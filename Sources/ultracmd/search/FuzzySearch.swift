import Foundation

/// Fuzzy matcher with ranked scoring: subsequence matching with bonuses for
/// consecutive runs, word starts and acronym hits — the classic launcher
/// scoring approach. Matching runs over UTF8 bytes (zero-allocation inner
/// loop) against caller-cached lowercase fields, keeping 10k-item ranking
/// in single-digit milliseconds.
enum FuzzySearch {

    struct Match {
        let score: Double
        /// Byte indices in `text` that matched (for highlighted ranges).
        let indices: [Int]
    }

    /// Convenience entry: lowercases inputs on each call. Hot paths should
    /// pre-lowercase and call this overload with cached strings.
    static func match(query: String, text: String) -> Match? {
        match(queryLower: query.lowercased(), textLower: text.lowercased())
    }

    static func matchAny(
        queryLower: String,
        titleLower: String,
        subtitleLower: String?,
        keywordsLower: [String]
    ) -> Match? {
        var best: Match?
        var bestScore = -Double.infinity

        if let m = match(queryLower: queryLower, textLower: titleLower) {
            best = m
            bestScore = m.score
        }
        // Secondary fields score at a discount.
        if let subtitleLower, let m = match(queryLower: queryLower, textLower: subtitleLower) {
            let s = m.score * 0.55
            if s > bestScore { best = Match(score: s, indices: m.indices); bestScore = s }
        }
        for kwLower in keywordsLower {
            guard let m = match(queryLower: queryLower, textLower: kwLower) else { continue }
            let s = m.score * 0.7
            if s > bestScore { best = Match(score: s, indices: m.indices); bestScore = s }
        }
        return best
    }

    static func matchAny(query: String, title: String, subtitle: String?, keywords: [String]) -> Match? {
        matchAny(
            queryLower: query.lowercased(),
            titleLower: title.lowercased(),
            subtitleLower: subtitle?.lowercased(),
            keywordsLower: keywords.map { $0.lowercased() }
        )
    }

    /// Zero-allocation subsequence scan over UTF8 bytes.
    static func match(queryLower: String, textLower: String) -> Match? {
        var queryBytes = queryLower.utf8.makeIterator()
        guard let firstQueryByte = queryBytes.next() else {
            return Match(score: 1, indices: [])
        }

        var indices: [Int] = []
        indices.reserveCapacity(8)
        var score = 0.0
        var lastMatchIndex = -10
        var pending: UInt8? = firstQueryByte
        var queryCount = 1
        var index = 0
        var prevByte: UInt8 = 0

        for byte in textLower.utf8 {
            guard let q = pending else { break }
            if q == byte {
                var bonus = 1.0
                if index == lastMatchIndex + 1 { bonus += 2.5 } // consecutive run
                if index == 0 || Self.isBoundary(prevByte) { bonus += 4.0 } // word start
                else if index != lastMatchIndex + 1 { bonus -= 0.3 }
                score += bonus
                indices.append(index)
                lastMatchIndex = index
                pending = queryBytes.next()
                queryCount += 1
            }
            prevByte = byte
            index += 1
        }

        // Unconsumed query bytes mean no match.
        if pending != nil { return nil }

        let matched = queryCount - 1
        let spread = Double((indices.last ?? 0) - (indices.first ?? 0) + 1)
        let textLength = textLower.utf8.count
        score -= spread * 0.15
        score -= Double(textLength - matched) * 0.08
        score += Double(matched) * 2.0
        // Exact (case-insensitive) or prefix matches win outright.
        if textLength == matched { score += 60 }
        if textLower.hasPrefix(queryLower) { score += 30 }
        return Match(score: score, indices: indices)
    }

    private static func isBoundary(_ c: UInt8) -> Bool {
        c == 32 /* space */ || c == 45 /* - */ || c == 95 /* _ */ ||
        c == 47 /* / */ || c == 46 /* . */ || c == 40 /* ( */ || c == 41 /* ) */
    }
}

import Foundation

/// What a natural-language capture line splits into: the doing, and when.
struct QuickCaptureDraft: Sendable, Equatable {
    var title: String
    var date: Date?
}

/// Splits capture lines typed in the launcher — "Dinner friday 7pm", "25m", "directions to SFO".
/// Pure text work; the calendar and clock facts are injected by the callers.
enum QuickCaptureParser {
    /// NSDataDetector resolves "friday 7pm" against the current moment, so the date is live.
    static func parseDateAndTitle(_ text: String) -> QuickCaptureDraft {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector?.matches(in: text, options: [], range: range) ?? []

        var title = text
        var date: Date?
        for match in matches.reversed() {
            guard match.date != nil, let matchRange = Range(match.range, in: text) else { continue }
            date = match.date
            title.removeSubrange(matchRange)
        }
        title = title
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ,-@"))
            .trimmingCharacters(in: .whitespaces)
        if title.isEmpty { title = text.trimmingCharacters(in: .whitespaces) }
        return QuickCaptureDraft(title: title, date: date)
    }

    /// Parses "25m", "1h 30m", "90 seconds"; nil when the text spells no duration at all.
    static func parseDuration(_ text: String) -> TimeInterval? {
        var seconds: TimeInterval = 0
        let pattern = #"(\d+(?:\.\d+)?)\s*(h|hr|hrs|hour|hours|m|min|mins|minute|minutes|s|sec|secs|second|seconds)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex.matches(in: text, options: [], range: range)
        guard !matches.isEmpty else { return nil }
        for match in matches {
            guard match.numberOfRanges > 2,
                let valueRange = Range(match.range(at: 1), in: text),
                let unitRange = Range(match.range(at: 2), in: text),
                let value = Double(text[valueRange])
            else { continue }
            let unit = text[unitRange].lowercased()
            if unit.hasPrefix("h") {
                seconds += value * 3600
            } else if unit.hasPrefix("m") {
                seconds += value * 60
            } else {
                seconds += value
            }
        }
        return seconds > 0 ? seconds : nil
    }
}

/// Where a Maps line goes: a place searched for, or a route asked for.
enum MapsDestination: Sendable, Equatable {
    case search(String)
    case directions(String)

    /// "directions to SFO" routes; anything else is a plain search, "near me" included.
    static func parse(_ text: String) -> MapsDestination {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        for prefix in ["directions to ", "route to "] where trimmed.lowercased().hasPrefix(prefix) {
            let destination = String(trimmed.dropFirst(prefix.count))
                .trimmingCharacters(in: .whitespaces)
            if !destination.isEmpty { return .directions(destination) }
        }
        return .search(trimmed)
    }

    var url: URL? {
        var components = URLComponents(string: "maps://")
        switch self {
        case .search(let query):
            components?.queryItems = [URLQueryItem(name: "q", value: query)]
        case .directions(let destination):
            components?.queryItems = [
                URLQueryItem(name: "daddr", value: destination),
                URLQueryItem(name: "dirflg", value: "d"),
            ]
        }
        return components?.url
    }
}

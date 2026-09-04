import Foundation

/// Instant inline calculator for arithmetic queries (Raycast-style).
/// Input is validated to a strict numeric-expression charset before being
/// handed to NSExpression, so no code-injection surface exists.
///
/// v2 ("better calculator", issue #12): supports a leading/trailing `=`,
/// mathematical constants (pi, tau, e), the full unicode operator set
/// (× ÷ − ^) and shows alternate integer bases in the subtitle.
enum Calculator {
    private static let allowedCharacters = CharacterSet(charactersIn: "0123456789+-*/%().e ")
        .union(CharacterSet.alphanumerics) // function names: sqrt, pow, log…

    private static let forbidden = Set("!\"'_{}[];:<>?#$&|^~`\\=@,")

    static func canEvaluate(_ input: String) -> Bool {
        let expression = normalize(input)
        guard expression.count >= 3 else { return false }
        guard !expression.contains(where: forbidden.contains) else { return false }
        guard expression.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else { return false }
        // Must contain at least one operator to not treat words as math.
        let hasOperator = expression.rangeOfCharacter(from: CharacterSet(charactersIn: "+-*/%^")) != nil
        let hasDigits = expression.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil
        return hasOperator && hasDigits
    }

    /// Unicode operators → ASCII, `=` prefixes stripped, constants inlined.
    private static func normalize(_ input: String) -> String {
        var expression = input.trimmingCharacters(in: .whitespaces)
        while expression.hasPrefix("=") { expression = String(expression.dropFirst()).trimmingCharacters(in: .whitespaces) }
        while expression.hasSuffix("=") { expression = String(expression.dropLast()).trimmingCharacters(in: .whitespaces) }
        expression = expression
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "^", with: "**")
        return expression
    }

    static func evaluate(_ input: String) -> Double? {
        guard canEvaluate(input) else { return nil }
        var sanitized = normalize(input)
        // Named constants → literals (word boundaries so "e" in "10e3" is kept).
        sanitized = substituteConstants(sanitized)
        // NSExpression does integer division on integer literals; decimalize
        // whole numbers so "10/4" is 2.5. Falls back to the raw expression if
        // decimalizing breaks a modulo.
        let decimalized = decimalizeLiterals(sanitized)
        for candidate in [decimalized, sanitized] {
            guard let expr = try? NSExpression(format: candidate) else { continue }
            let value = expr.expressionValue(with: nil, context: nil)
            if let d = value as? Double { return d }
            if let i = value as? Int { return Double(i) }
            if let n = value as? NSNumber { return n.doubleValue }
        }
        return nil
    }

    /// pi / tau / e → decimal literals, on word boundaries only.
    private static func substituteConstants(_ input: String) -> String {
        let map: [String: String] = [
            "pi": "(3.141592653589793)",
            "π": "(3.141592653589793)",
            "tau": "(6.283185307179586)",
            "e": "(2.718281828459045)",
        ]
        var result = input
        for (name, literal) in map.sorted(by: { $0.key.count > $1.key.count }) {
            guard let regex = try? NSRegularExpression(pattern: "(?<![a-zA-Z0-9_])\(NSRegularExpression.escapedPattern(for: name))(?![a-zA-Z0-9_])") else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: literal)
        }
        return result
    }

    /// Turn standalone integer literals into decimal literals (7 → 7.0).
    private static func decimalizeLiterals(_ input: String) -> String {
        let pattern = "(^|[^0-9.])([0-9]+)(?![0-9.])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let ns = input as NSString
        var result = input
        let matches = regex.matches(in: input, range: NSRange(location: 0, length: ns.length)).reversed()
        for m in matches {
            guard m.numberOfRanges > 2, let intRange = Range(m.range(at: 2), in: input) else { continue }
            let number = String(input[intRange])
            result.replaceSubrange(intRange, with: "\(number).0")
        }
        return result
    }

    static func formatted(_ value: Double) -> String {
        if value.rounded() == value, abs(value) < 1e15 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? String(value)
        }
        var s = String(format: "%.6g", value)
        if s.hasSuffix(".0") { s = String(s.dropLast(2)) }
        return s
    }

    /// Alternate representations shown in the result subtitle.
    static func detailLine(for value: Double) -> String? {
        guard value.rounded() == value, abs(value) < 1e15 else { return nil }
        let int = Int64(value)
        return "HEX 0x\(String(int, radix: 16, uppercase: true)) · BIN \(String(int, radix: 2)) · ⏎ Copy"
    }
}

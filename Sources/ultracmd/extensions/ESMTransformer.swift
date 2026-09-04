import Foundation

/// Transforms plain ESM imports/exports into the CommonJS-ish form the
/// UltraCMD runtime executes. Regex-based; covers the import shapes used by
/// Raycast-style extension sources:
///
///   import x from "m";            -> const x = require("m");
///   import {a, b as c} from "m";  -> const {a, b: c} = require("m");
///   import * as X from "m";       -> const X = require("m");
///   import "m";                   -> require("m");
///   export default X;             -> exports.default = X;
///   export function f(){}         -> function f(){} … exports.f = f;
///   export const/let x = …;       -> const x = …; … exports.x = x;
///   export { a, b };              -> … exports.a = a; exports.b = b;
enum ESMTransformer {

    static func transform(_ source: String) -> String {
        var appended = ""
        var out = source

        // Imports -----------------------------------------------------------------
        out = replace(out, pattern: #"import\s+["']([^"']+)["'];?"#) { m in
            "require(\"\(m[1])\");"
        }
        out = replace(out, pattern: #"import\s+(\w+)\s+from\s+["']([^"']+)["'];?"#) { m in
            "const \(m[1]) = require(\"\(m[2])\");"
        }
        out = replace(out, pattern: #"import\s*\*\s*as\s+(\w+)\s+from\s+["']([^"']+)["'];?"#) { m in
            "const \(m[1]) = require(\"\(m[2])\");"
        }
        out = replace(out, pattern: #"import\s*\{([^}]+)\}\s+from\s+["']([^"']+)["'];?"#) { m in
            let names = m[1]
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { spec -> String in
                    let parts = spec.split(separator: " as ").map { String($0).trimmingCharacters(in: .whitespaces) }
                    return parts.count == 2 ? "\(parts[0]): \(parts[1])" : parts[0]
                }
                .joined(separator: ", ")
            return "const {\(names)} = require(\"\(m[2])\");"
        }

        // Exports ------------------------------------------------------------------
        out = replace(out, pattern: #"export\s+default\s+"#) { _ in
            "exports.default = "
        }
        out = replace(out, pattern: #"export\s+(async\s+)?function\s+(\w+)"#) { m in
            appended.append("exports.\(m[2]) = \(m[2]);\n")
            return "\(m[1])function \(m[2])"
        }
        out = replace(out, pattern: #"export\s+(const|let|var)\s+(\w+)"#) { m in
            appended.append("exports.\(m[2]) = \(m[2]);\n")
            return "\(m[1]) \(m[2])"
        }
        out = replace(out, pattern: #"export\s+class\s+(\w+)"#) { m in
            appended.append("exports.\(m[1]) = \(m[1]);\n")
            return "class \(m[1])"
        }
        out = replace(out, pattern: #"export\s*\{([^}]+)\};?"#) { m in
            for spec in m[1].split(separator: ",") {
                let parts = spec.split(separator: " as ").map { String($0).trimmingCharacters(in: .whitespaces) }
                let local = parts[0]
                let exported = parts.count == 2 ? parts[1] : parts[0]
                appended.append("exports.\(exported) = \(local);\n")
            }
            return ""
        }

        return appended.isEmpty ? out : out + "\n;\n" + appended
    }

    private static func replace(
        _ source: String,
        pattern: String,
        options: NSRegularExpression.Options = [],
        transform: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return source }
        var result = ""
        var last = source.startIndex
        let ns = source as NSString
        for m in regex.matches(in: source, options: [], range: NSRange(location: 0, length: ns.length)) {
            guard let range = Range(m.range, in: source) else { continue }
            result += source[last..<range.lowerBound]
            let groups = (0..<m.numberOfRanges).map { r -> String in
                if m.range(at: r).location == NSNotFound { return "" }
                if let groupRange = Range(m.range(at: r), in: source) { return String(source[groupRange]) }
                return ""
            }
            result += transform(groups)
            last = range.upperBound
        }
        result += source[last...]
        return result
    }
}

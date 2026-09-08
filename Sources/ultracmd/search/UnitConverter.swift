import Foundation

/// Inline answer providers beyond arithmetic: unit conversion ("5 kg to lb"),
/// color inspection ("#ff8800" → swatch + rgb/hsl) and bare-URL detection
/// ("example.com" → open). All pure & unit-tested; surfaced as answer rows
/// by `AppModel.applyRanked`.
enum UnitConverter {

    struct Conversion: Equatable {
        var value: Double
        var fromUnit: String
        var result: Double
        var toUnit: String

        var title: String { "\(Calculator.formatted(result)) \(toUnit)" }
        var subtitle: String { "\(Calculator.formatted(value)) \(fromUnit) = \(Calculator.formatted(result)) \(toUnit) · ⏎ Copy" }
    }

    // MARK: Parsing

    /// Parses "<number> <unit> (to|in|as) <unit>" — case-insensitive,
    /// degree symbols optional.
    static func convert(_ input: String) -> Conversion? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard let parsed = parseNumberUnitTail(trimmed) else { return nil }
        let (value, fromRaw, toRaw) = parsed
        guard let from = canonicalize(fromRaw), let to = canonicalize(toRaw) else { return nil }
        guard from.dimension == to.dimension, from.symbol != to.symbol else { return nil }

        // Temperature is affine (°C = (value + add) × scale), everything
        // else is linear around a base unit.
        if from.dimension == .temperature {
            let celsius = (value + from.celsiusAdd) * from.celsiusScale
            let result = celsius / to.celsiusScale - to.celsiusAdd
            return Conversion(value: value, fromUnit: from.symbol, result: result, toUnit: to.symbol)
        }
        let base = value * from.factor
        return Conversion(value: value, fromUnit: from.symbol, result: base / to.factor, toUnit: to.symbol)
    }

    private static func parseNumberUnitTail(_ input: String) -> (Double, String, String)? {
        let pattern = #"^\s*(-?\d+(?:\.\d+)?)\s*([a-zA-Z°/]+[a-zA-Z0-9°/]*)\s+(?:to|in|as)\s+([a-zA-Z°/]+[a-zA-Z0-9°/]*)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(input.startIndex..., in: input)
        guard let m = regex.firstMatch(in: input, options: [], range: range),
              m.numberOfRanges > 3,
              let valueRange = Range(m.range(at: 1), in: input),
              let fromRange = Range(m.range(at: 2), in: input),
              let toRange = Range(m.range(at: 3), in: input),
               let value = Double(input[valueRange]) else { return nil }
        return (value, String(input[fromRange]), String(input[toRange]))
    }

    // MARK: Unit tables

    private enum Dimension: String {
        case length, mass, volume, temperature, data, time, speed
    }

    private struct Unit {
        var symbol: String
        var dimension: Dimension
        var factor: Double // relative to the dimension's base unit
        // Temperature only: °C = (value + celsiusAdd) × celsiusScale.
        var celsiusAdd: Double = 0
        var celsiusScale: Double = 1
        var aliases: [String] = []
    }

    private static let units: [Unit] = [
        // Length (base: meter)
        Unit(symbol: "mm", dimension: .length, factor: 0.001, aliases: ["millimeter", "millimeters"]),
        Unit(symbol: "cm", dimension: .length, factor: 0.01, aliases: ["centimeter", "centimeters"]),
        Unit(symbol: "m", dimension: .length, factor: 1, aliases: ["meter", "meters"]),
        Unit(symbol: "km", dimension: .length, factor: 1000, aliases: ["kilometer", "kilometers"]),
        Unit(symbol: "in", dimension: .length, factor: 0.0254, aliases: ["inch", "inches", "\u{2019}", "\u{2033}"]),
        Unit(symbol: "ft", dimension: .length, factor: 0.3048, aliases: ["foot", "feet", "\u{2032}", "\u{2019}"]),
        Unit(symbol: "yd", dimension: .length, factor: 0.9144, aliases: ["yard", "yards"]),
        Unit(symbol: "mi", dimension: .length, factor: 1609.344, aliases: ["mile", "miles"]),
        Unit(symbol: "nmi", dimension: .length, factor: 1852, aliases: ["nauticalmile", "nauticalmiles"]),
        // Mass (base: gram)
        Unit(symbol: "mg", dimension: .mass, factor: 0.001, aliases: ["milligram", "milligrams"]),
        Unit(symbol: "g", dimension: .mass, factor: 1, aliases: ["gram", "grams"]),
        Unit(symbol: "kg", dimension: .mass, factor: 1000, aliases: ["kilogram", "kilograms", "kilo", "kilos"]),
        Unit(symbol: "t", dimension: .mass, factor: 1_000_000, aliases: ["tonne", "tonnes", "ton", "tons"]),
        Unit(symbol: "oz", dimension: .mass, factor: 28.349523125, aliases: ["ounce", "ounces"]),
        Unit(symbol: "lb", dimension: .mass, factor: 453.59237, aliases: ["lbs", "pound", "pounds"]),
        Unit(symbol: "st", dimension: .mass, factor: 6350.29318, aliases: ["stone", "stones"]),
        // Volume (base: liter)
        Unit(symbol: "ml", dimension: .volume, factor: 0.001, aliases: ["milliliter", "milliliters"]),
        Unit(symbol: "l", dimension: .volume, factor: 1, aliases: ["liter", "liters", "litre", "litres"]),
        Unit(symbol: "gal", dimension: .volume, factor: 3.785411784, aliases: ["gallon", "gallons"]),
        Unit(symbol: "qt", dimension: .volume, factor: 0.946352946, aliases: ["quart", "quarts"]),
        Unit(symbol: "pt", dimension: .volume, factor: 0.473176473, aliases: ["pint", "pints"]),
        Unit(symbol: "cup", dimension: .volume, factor: 0.2365882365, aliases: ["cups"]),
        Unit(symbol: "floz", dimension: .volume, factor: 0.0295735295625, aliases: ["oz", "fluidounce", "fluidounces"]),
        // Temperature (affine: °C = (value + add) × scale)
        Unit(symbol: "°C", dimension: .temperature, factor: 1, celsiusAdd: 0, celsiusScale: 1, aliases: ["c", "celsius"]),
        Unit(symbol: "°F", dimension: .temperature, factor: 1, celsiusAdd: -32, celsiusScale: 1.0 / 1.8, aliases: ["f", "fahrenheit"]),
        Unit(symbol: "K", dimension: .temperature, factor: 1, celsiusAdd: -273.15, celsiusScale: 1, aliases: ["k", "kelvin"]),
        // Data (base: byte, decimal SI + binary IEC)
        Unit(symbol: "kb", dimension: .data, factor: 1e3, aliases: ["kilobyte", "kilobytes"]),
        Unit(symbol: "mb", dimension: .data, factor: 1e6, aliases: ["megabyte", "megabytes"]),
        Unit(symbol: "gb", dimension: .data, factor: 1e9, aliases: ["gigabyte", "gigabytes"]),
        Unit(symbol: "tb", dimension: .data, factor: 1e12, aliases: ["terabyte", "terabytes"]),
        Unit(symbol: "kib", dimension: .data, factor: 1024, aliases: []),
        Unit(symbol: "mib", dimension: .data, factor: 1024 * 1024, aliases: []),
        Unit(symbol: "gib", dimension: .data, factor: 1024 * 1024 * 1024, aliases: []),
        // Time (base: second)
        Unit(symbol: "ms", dimension: .time, factor: 0.001, aliases: ["millisecond", "milliseconds"]),
        Unit(symbol: "s", dimension: .time, factor: 1, aliases: ["sec", "secs", "second", "seconds"]),
        Unit(symbol: "min", dimension: .time, factor: 60, aliases: ["mins", "minute", "minutes"]),
        Unit(symbol: "h", dimension: .time, factor: 3600, aliases: ["hr", "hrs", "hour", "hours"]),
        Unit(symbol: "d", dimension: .time, factor: 86400, aliases: ["day", "days"]),
        Unit(symbol: "wk", dimension: .time, factor: 604800, aliases: ["week", "weeks"]),
        // Speed (base: m/s)
        Unit(symbol: "km/h", dimension: .speed, factor: 1.0 / 3.6, aliases: ["kph", "kmh"]),
        Unit(symbol: "mph", dimension: .speed, factor: 0.44704, aliases: []),
        Unit(symbol: "m/s", dimension: .speed, factor: 1, aliases: ["mps"]),
        Unit(symbol: "kn", dimension: .speed, factor: 0.514444, aliases: ["knot", "knots"]),
    ]

    private static let aliasTable: [String: Unit] = {
        var table: [String: Unit] = [:]
        for unit in units {
            table[unit.symbol.lowercased()] = unit
            for alias in unit.aliases {
                table[alias.lowercased()] = unit
            }
        }
        // Volume "oz" would otherwise collide with mass ounces; keep the
        // mass meaning and drop the volume alias.
        table["oz"] = units.first { $0.symbol == "oz" && $0.dimension == .mass }
        return table
    }()

    private static func canonicalize(_ raw: String) -> Unit? {
        var key = raw.lowercased()
            .replacingOccurrences(of: "°", with: "")
            .replacingOccurrences(of: "\u{00BA}", with: "") // masculine ordinal
            .replacingOccurrences(of: " ", with: "")
        if key.hasSuffix("s"), key != "s", key != "ms", tableKeyMissingSingular(key) {
            key = String(key.dropLast())
        }
        return aliasTable[key]
    }

    private static func tableKeyMissingSingular(_ pluralKey: String) -> Bool {
        aliasTable[String(pluralKey.dropLast())] != nil && aliasTable[pluralKey] == nil
    }
}

// MARK: - Color inspection

/// Expands a color literal into display forms for the answer row subtitle.
enum ColorInfo {
    struct RGB: Equatable {
        var r: Int
        var g: Int
        var b: Int
    }
    struct HSL: Equatable {
        var h: Int // degrees 0–360
        var s: Int // percent 0–100
        var l: Int // percent 0–100
    }

    static func rgb(fromHex hex: String) -> RGB? {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 3 || value.count == 6 || value.count == 8,
              value.allSatisfy({ $0.isHexDigit }),
              let raw = UInt64(value.suffix(6), radix: 16) else { return nil }
        return RGB(
            r: Int((raw >> 16) & 0xFF),
            g: Int((raw >> 8) & 0xFF),
            b: Int(raw & 0xFF)
        )
    }

    static func hsl(from rgb: RGB) -> HSL {
        let r = Double(rgb.r) / 255, g = Double(rgb.g) / 255, b = Double(rgb.b) / 255
        let max = Swift.max(r, Swift.max(g, b))
        let min = Swift.min(r, Swift.min(g, b))
        let l = (max + min) / 2
        let delta = max - min
        var h = 0.0
        var s = 0.0
        if delta > 1e-9 {
            s = l > 0.5 ? delta / (2 - max - min) : delta / (max + min)
            switch max {
            case r: h = (g - b) / delta + (g < b ? 6 : 0)
            case g: h = (b - r) / delta + 2
            default: h = (r - g) / delta + 4
            }
            h *= 60
        }
        return HSL(h: Int(h.rounded()), s: Int((s * 100).rounded()), l: Int((l * 100).rounded()))
    }

    /// Subtitle shown under the swatch answer row.
    static func detailLine(forHex hex: String) -> String? {
        guard let rgb = rgb(fromHex: hex) else { return nil }
        let hsl = hsl(from: rgb)
        return "rgb(\(rgb.r), \(rgb.g), \(rgb.b)) · hsl(\(hsl.h), \(hsl.s)%, \(hsl.l)%) · ⏎ Copy"
    }
}

// MARK: - URL detection

/// Recognizes a query that *is* a URL (bare domain or full scheme) so search
/// can offer "Open URL" — without hijacking numbers ("3.14") or sentences.
enum URLDetector {
    static func openableURL(from query: String) -> URL? {
        let t = query.trimmingCharacters(in: .whitespaces)
        guard t.count >= 4, !t.contains(where: \.isWhitespace) else { return nil }

        if t.hasPrefix("http://") || t.hasPrefix("https://") {
            return URL(string: t)
        }
        guard t.contains(".") else { return nil }
        // Numbers with decimal points ("3.14", "1.5e3") are math, not links.
        if Double(t) != nil { return nil }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~:/?#[]@!$&'()*+,;%=")
        guard t.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }

        let parts = t.split(separator: ".")
        guard let tld = parts.last, tld.count >= 2, tld.allSatisfy(\.isLetter) else { return nil }
        // Needs a host before the dot — ".com" alone isn't a URL.
        guard parts.count >= 2, !parts.dropLast().allSatisfy({ $0.isEmpty }) else { return nil }
        return URL(string: "https://" + t)
    }
}

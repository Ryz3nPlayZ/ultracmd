import Foundation

/// Tracks launch frequency + recency for adaptive ranking ("used often,
/// used recently" floats to the top). Persisted as JSON in Application Support.
final class UsageStore {
    struct Usage: Codable {
        var count: Int = 0
        var lastUsed: Date = .distantPast
    }

    private(set) var usage: [String: Usage] = [:]
    private let fileURL: URL
    private let saveQueue = DispatchQueue(label: "ultracmd.usage", qos: .utility)

    init(directory: URL? = nil) {
        let dir = directory ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ultracmd", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("usage.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: Usage].self, from: data) {
            usage = decoded
        }
    }

    func record(id: String) {
        var entry = usage[id] ?? Usage()
        entry.count += 1
        entry.lastUsed = Date()
        usage[id] = entry
        persist()
    }

    /// Frequency/recency boost for scoring.
    func boost(id: String, now: Date = Date()) -> Double {
        guard let u = usage[id], u.count > 0 else { return 0 }
        let frequency = min(Double(u.count), 30.0) * 1.2
        let days = now.timeIntervalSince(u.lastUsed) / 86_400
        let recency = max(0, 12.0 - days) // fades to 0 after 12 days
        return frequency + recency
    }

    func clear() {
        usage.removeAll()
        persist()
    }

    private func persist() {
        let snapshot = usage
        let url = fileURL
        saveQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}

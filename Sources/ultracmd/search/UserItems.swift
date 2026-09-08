import Foundation

/// User-defined search items: Quicklinks (URL shortcuts that may consume the
/// live query via a `{query}` placeholder) and Snippets (saved text blocks
/// pasted on run, with an optional `{clipboard}` placeholder). Plain JSON in
/// Application Support; every store keeps a lock-guarded mirror so the
/// background search queue can snapshot safely while the main actor mutates.

struct Quicklink: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var url: String
    var keywords: [String] = []

    /// True when the URL consumes the live search query.
    var takesQuery: Bool {
        url.range(of: "{query}", options: .caseInsensitive) != nil
    }

    /// Substitute the placeholder (when present) and normalize the scheme.
    func resolvedURL(for query: String) -> URL? {
        var target = url.trimmingCharacters(in: .whitespaces)
        if takesQuery {
            let encoded = query.trimmingCharacters(in: .whitespaces)
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
            target = target.replacingOccurrences(of: "{query}", with: encoded, options: .caseInsensitive)
        }
        if !target.hasPrefix("http://") && !target.hasPrefix("https://") {
            target = "https://" + target
        }
        return URL(string: target)
    }
}

struct Snippet: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var body: String
    var keywords: [String] = []

    /// `{clipboard}` inlines the current pasteboard contents at run time.
    func expandedBody(clipboard: String?) -> String {
        guard body.contains("{clipboard}"), let clipboard, !clipboard.isEmpty else { return body }
        return body.replacingOccurrences(of: "{clipboard}", with: clipboard)
    }
}

/// Lock-guarded JSON-backed store. `@Published` state is touched on the main
/// actor only; `snapshot` is safe from any queue (the search ranking queue).
final class QuicklinkStore: ObservableObject {
    @Published private(set) var links: [Quicklink] = []

    private var storage: [Quicklink] = []
    private let lock = NSLock()
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ultracmd", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("quicklinks.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Quicklink].self, from: data) {
            links = decoded
            lock.lock()
            storage = decoded
            lock.unlock()
        }
    }

    var snapshot: [Quicklink] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    /// Insert or update (matched by id), keeping user order.
    func upsert(_ link: Quicklink) {
        if let index = links.firstIndex(where: { $0.id == link.id }) {
            links[index] = link
        } else {
            links.append(link)
        }
        syncAndPersist()
    }

    func delete(id: UUID) {
        links.removeAll { $0.id == id }
        syncAndPersist()
    }

    private func syncAndPersist() {
        lock.lock()
        storage = links
        lock.unlock()
        // Rare, user-initiated mutations of a tiny file — write inline so a
        // reader (tests, a second store) never observes a stale file.
        if let data = try? JSONEncoder().encode(links) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

final class SnippetStore: ObservableObject {
    @Published private(set) var snippets: [Snippet] = []

    private var storage: [Snippet] = []
    private let lock = NSLock()
    private let fileURL: URL

    init(directory: URL? = nil) {
        let dir = directory ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ultracmd", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("snippets.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
            lock.lock()
            storage = decoded
            lock.unlock()
        }
    }

    var snapshot: [Snippet] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func upsert(_ snippet: Snippet) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippets[index] = snippet
        } else {
            snippets.append(snippet)
        }
        syncAndPersist()
    }

    func delete(id: UUID) {
        snippets.removeAll { $0.id == id }
        syncAndPersist()
    }

    private func syncAndPersist() {
        lock.lock()
        storage = snippets
        lock.unlock()
        // Rare, user-initiated mutations of a tiny file — write inline.
        if let data = try? JSONEncoder().encode(snippets) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}

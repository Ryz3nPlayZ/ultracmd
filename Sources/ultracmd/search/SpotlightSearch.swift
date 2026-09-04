import AppKit
import CoreServices
import Foundation

/// File search through Spotlight's MDQuery API — queries the same metadata
/// index Finder uses, so results are instant without owning a file crawler.
/// The query runs synchronously on a background queue (bounded by Spotlight
/// itself, typically a few ms) and delivers on the main queue.
final class SpotlightSearch {
    private let queue = DispatchQueue(label: "ultracmd.spotlight", qos: .userInitiated)
    private var generation = 0

    func search(_ queryString: String, limit: Int = 12, completion: @escaping @MainActor ([SearchItem]) -> Void) {
        generation &+= 1
        let gen = generation
        queue.async { [weak self] in
            let items = Self.run(query: queryString, limit: limit)
            DispatchQueue.main.async {
                guard let self, gen == self.generation else { return } // stale result
                completion(items)
            }
        }
    }

    static func run(query queryString: String, limit: Int) -> [SearchItem] {
        let escaped = queryString.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "*", with: "")
        guard !escaped.isEmpty else { return [] }
        let predicate = "kMDItemFSName == '*\(escaped)*'c"
        guard let q = MDQueryCreate(nil, predicate as CFString, nil, nil) else { return [] }
        guard MDQueryExecute(q, CFOptionFlags(kMDQuerySynchronous.rawValue)) else { return [] }
        let count = min(Int(limit), MDQueryGetResultCount(q))
        var items: [SearchItem] = []
        for i in 0..<count {
            guard let raw = MDQueryGetResultAtIndex(q, i) else { continue }
            let item = Unmanaged<MDItem>.fromOpaque(raw).takeUnretainedValue()
            let name = MDItemCopyAttribute(item, kMDItemFSName) as? String ?? ""
            let path = MDItemCopyAttribute(item, kMDItemPath) as? String ?? ""
            guard !name.isEmpty, !path.isEmpty else { continue }
            var kind = SearchItemKind.file
            var isFolder = false
            if let uti = MDItemCopyAttribute(item, kMDItemContentType) as? String,
               uti == "public.folder" || uti == "public.directory" {
                kind = .folder
                isFolder = true
            }
            let dir = (path as NSString).deletingLastPathComponent
            items.append(SearchItem(
                id: "file:\(path)",
                title: name,
                subtitle: isFolder ? dir : "\(dir)  ·  \(path.fileSizeLabel)",
                kind: kind,
                icon: .file(path),
                keywords: [],
                path: path
            ))
        }
        return items
    }
}

extension String {
    /// Best-effort human-readable file size for subtitles.
    var fileSizeLabel: String {
        let url = URL(fileURLWithPath: self)
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

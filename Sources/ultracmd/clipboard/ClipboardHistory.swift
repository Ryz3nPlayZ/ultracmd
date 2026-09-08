import AppKit
import Foundation
import UniformTypeIdentifiers

enum ClipKind: String, Codable {
    case text
    case rtf
    case url
    case image
    case file
    case color
}

struct ClipEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var kind: ClipKind
    var createdAt: Date
    /// Text payload (plain text, URL string, or file-path list joined by \n).
    var text: String?
    /// RTF payload path (Application Support) for styled text.
    var rtfPath: String?
    /// Image payload path for captured images.
    var imagePath: String?
    var pixelWidth: Int?
    var pixelHeight: Int?
    /// File URL paths when files were copied.
    var filePaths: [String]?
    /// Normalized "#RRGGBB" when the payload is a color literal.
    var colorHex: String?
    /// App the content was copied from (nil on legacy entries).
    var sourceBundleID: String?
    var sourceAppName: String?
    /// Sidecar file holding the *full* text when it exceeded the inline cap
    /// (index bloat control — `text` then carries only the truncated copy).
    var textPath: String?
    /// Vision-extracted text for image entries (searchable & copyable).
    var ocrText: String?
    /// New fields are optionals so pre-migration index.json files decode.
    var pinned: Bool?
    var copyCount: Int?
    var firstCopiedAt: Date?
    var lastCopiedAt: Date?

    /// The complete text payload — inline, or read from the sidecar file.
    var fullText: String? {
        if let textPath,
           let stored = try? String(contentsOf: URL(fileURLWithPath: textPath), encoding: .utf8),
           !stored.isEmpty {
            return stored
        }
        return text
    }

    var isPinned: Bool { pinned ?? false }
    var timesCopied: Int { max(1, copyCount ?? 1) }
    var firstCopied: Date { firstCopiedAt ?? createdAt }
    var lastCopied: Date { lastCopiedAt ?? createdAt }

    var preview: String {
        switch kind {
        case .text, .url, .rtf:
            return (text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        case .color:
            return colorHex?.uppercased() ?? (text ?? "")
        case .image:
            if let w = pixelWidth, let h = pixelHeight { return "Image · \(w)×\(h)" }
            return "Image"
        case .file:
            let names = (filePaths ?? []).map { ($0 as NSString).lastPathComponent }
            return names.joined(separator: ", ")
        }
    }

    /// Kind shown in the inspector ("Image", "Rich Text", …).
    var typeLabel: String {
        switch kind {
        case .text: return "Text"
        case .rtf: return "Rich Text"
        case .url: return "Link"
        case .image: return "Image"
        case .file: return "File"
        case .color: return "Color"
        }
    }

    /// Path Finder/Quick Look can reveal, if any.
    var revealablePath: String? {
        switch kind {
        case .image: return imagePath
        case .rtf: return rtfPath
        case .file: return filePaths?.first
        default: return nil
        }
    }

    /// On-disk size of the stored payload, when it lives in a file.
    var payloadByteSize: Int? {
        let path: String?
        switch kind {
        case .image: path = imagePath
        case .rtf: path = rtfPath
        default: path = nil
        }
        guard let path,
              let size = try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int else { return nil }
        return size
    }

    /// Chronological bucket for the grouped list (Raycast-style).
    var dateBucket: ClipDateBucket {
        ClipDateBucket(for: lastCopied, relativeTo: Date())
    }

    func isSameContent(as other: ClipEntry) -> Bool {
        if kind != other.kind { return false }
        switch kind {
        case .image:
            return pixelWidth == other.pixelWidth
                && pixelHeight == other.pixelHeight
                && payloadByteSize == other.payloadByteSize
        default:
            return text == other.text
                && filePaths == other.filePaths
                && colorHex == other.colorHex
        }
    }
}

/// Compaction policy (pure, unit-tested): the JSON index only carries a
/// truncated copy of very long texts — the full payload moves to a sidecar
/// file, exactly like images/RTF always have.
enum ClipCompactor {
    /// Texts longer than this live in a sidecar file instead of the index.
    static let inlineTextLimit = 2048
    /// Truncated inline preview kept in `text` for search + previews.
    static let inlinePreviewLimit = 2000

    static func compact(_ text: String, directory: URL) -> (text: String, path: String?) {
        guard text.count > inlineTextLimit else { return (text, nil) }
        let url = directory.appendingPathComponent("\(UUID().uuidString).txt")
        guard (try? text.write(to: url, atomically: true, encoding: .utf8)) != nil else {
            return (text, nil) // write failed → keep inline rather than lose data
        }
        return (String(text.prefix(inlinePreviewLimit)), url.path)
    }

    /// Time-decay prune: unpinned entries older than the cutoff go first,
    /// oldest first, until the count fits the capacity. Pinned survive.
    static func prune(
        _ entries: [ClipEntry],
        capacity: Int,
        retentionDays: Int,
        now: Date = Date()
    ) -> [ClipEntry] {
        var survivors = entries
        if retentionDays > 0,
           let horizon = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now) {
            survivors = survivors.filter { $0.isPinned || $0.lastCopied > horizon }
        }
        var unpinned = survivors.filter { !$0.isPinned }.count
        guard unpinned > capacity else { return survivors }
        // Entries are newest-first; drop from the tail.
        var result: [ClipEntry] = []
        result.reserveCapacity(survivors.count)
        for entry in survivors.reversed() {
            if unpinned <= capacity || entry.isPinned {
                result.append(entry)
            } else {
                unpinned -= 1
            }
        }
        return result.reversed()
    }
}

enum ClipDateBucket: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case pastWeek = "Past 7 Days"
    case pastMonth = "Past 30 Days"
    case older = "Older"

    init(for date: Date, relativeTo now: Date) {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: now) {
            self = .today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            self = .yesterday
        } else if let week = calendar.date(byAdding: .day, value: -7, to: now), date >= week {
            self = .pastWeek
        } else if let month = calendar.date(byAdding: .day, value: -30, to: now), date >= month {
            self = .pastMonth
        } else {
            self = .older
        }
    }
}

/// Type filter for the clipboard list (⌘P).
enum ClipFilter: String, CaseIterable, Identifiable {
    case all
    case text
    case images
    case files
    case links
    case colors

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Types"
        case .text: return "Text"
        case .images: return "Images"
        case .files: return "Files"
        case .links: return "Links"
        case .colors: return "Colors"
        }
    }

    var symbol: String {
        switch self {
        case .all: return "line.3.horizontal.decrease.circle"
        case .text: return "text.quote"
        case .images: return "photo"
        case .files: return "folder"
        case .links: return "link"
        case .colors: return "paintpalette"
        }
    }

    func matches(_ entry: ClipEntry) -> Bool {
        switch self {
        case .all: return true
        case .text: return entry.kind == .text || entry.kind == .rtf
        case .images: return entry.kind == .image
        case .files: return entry.kind == .file
        case .links: return entry.kind == .url
        case .colors: return entry.kind == .color
        }
    }
}

/// Pure classification helpers (unit-tested).
enum ClipClassifier {
    /// Recognizes a standalone color literal: #RGB, #RGBA, #RRGGBB,
    /// #RRGGBBAA, rgb()/rgba() and hsl()/hsla(). Returns normalized
    /// "#RRGGBB[AA]".
    static func colorHex(from raw: String) -> String? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !t.isEmpty, t.count <= 32 else { return nil }

        func hexChar(_ c: Character) -> Int? {
            c.hexDigitValue
        }
        func expand(_ hex: [Int]) -> String? {
            // 3/4-digit shorthand duplicates each digit; 6/8 pass through.
            let digits: [Int]
            switch hex.count {
            case 3: digits = hex.flatMap { [$0, $0] }
            case 4: digits = hex.flatMap { [$0, $0] }
            case 6, 8: digits = hex
            default: return nil
            }
            let value = digits.map { String($0, radix: 16) }.joined()
            return "#" + value.uppercased()
        }

        if t.hasPrefix("#") {
            let hex = Array(t.dropFirst()).compactMap(hexChar)
            guard hex.count == t.count - 1 else { return nil }
            return expand(hex)
        }
        if t.hasPrefix("rgb") || t.hasPrefix("hsl") {
            let parts = commaComponents(t)
            guard parts.count == 3 || parts.count == 4,
                  let first = Double(parts[0].hasSuffix("%") ? String(parts[0].dropLast()) : parts[0]),
                  let second = Double(parts[1].hasSuffix("%") ? String(parts[1].dropLast()) : parts[1]),
                  let third = Double(parts[2].hasSuffix("%") ? String(parts[2].dropLast()) : parts[2]) else { return nil }
            if t.hasPrefix("rgb") {
                guard (0...255).contains(first), (0...255).contains(second), (0...255).contains(third) else { return nil }
                var hex = String(format: "#%02X%02X%02X", Int(first), Int(second), Int(third))
                if parts.count == 4, let a = Double(parts[3]), (0...1).contains(a) {
                    hex += String(format: "%02X", Int((a * 255).rounded()))
                }
                return hex
            }
            // hsl()/hsla()
            guard (0...360).contains(first), (0...100).contains(second), (0...100).contains(third) else { return nil }
            let rgb = hslToRGB(h: first / 360, s: second / 100, l: third / 100)
            return String(format: "#%02X%02X%02X", rgb.0, rgb.1, rgb.2)
        }
        return nil
    }

    /// "rgb(1, 2, 3)" → ["1", "2", "3"]; nil when malformed.
    private static func commaComponents(_ t: String) -> [String] {
        guard let open = t.firstIndex(of: "("), t.hasSuffix(")"), t.index(after: open) < t.index(before: t.endIndex) else { return [] }
        let inner = t[t.index(after: open)..<t.index(before: t.endIndex)]
        return inner.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private static func hslToRGB(h: Double, s: Double, l: Double) -> (Int, Int, Int) {
        func channel(_ n: Int) -> Double {
            let k = Double(n) + 12 * h.truncatingRemainder(dividingBy: 1)
            let a = s * min(l, 1 - l)
            return l - a * max(-1, min(k - 3, 9 - k, 1))
        }
        return (Int((channel(0) * 255).rounded()), Int((channel(8) * 255).rounded()), Int((channel(4) * 255).rounded()))
    }

    /// Password managers & secret stores whose copies are never recorded.
    static let secureBundleIDs: Set<String> = [
        "com.agilebits.onepassword-osx", "com.1password.1password",
        "com.bitwarden.desktop", "com.bitwarden.safari",
        "com.dashlane.DashlaneAgent", "com.dashlane.mac",
        "org.keepassxc.keepassxc", "in.sinew.enpass", "in.sinew.Enpass5",
        "com.apple.keychainaccess", "com.starkmac.strongbox",
    ]

    static let secureNameFragments: Set<String> = [
        "1password", "bitwarden", "keepass", "dashlane", "enpass",
        "strongbox", "keychain", "secrets",
    ]

    static func isSecureSource(bundleID: String?, appName: String?) -> Bool {
        if let bundleID, secureBundleIDs.contains(bundleID.lowercased()) { return true }
        if let name = appName?.lowercased() {
            if secureNameFragments.contains(where: { name.contains($0) }) { return true }
        }
        return false
    }
}

/// High-performance pasteboard observer + persistent history.
/// Polls `pasteboard.changeCount` on a short timer (the standard approach —
/// there is no push API for NSPasteboard) and stores payloads under
/// Application Support/ultracmd/clipboard. Every capture records the
/// frontmost app, re-copies bump a copy-count instead of duplicating, and
/// entries from password managers are skipped entirely.
final class ClipboardHistoryManager: ObservableObject {
    @Published private(set) var entries: [ClipEntry] = []

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var suppressNextCapture = false
    private let storeDir: URL
    private let indexURL: URL
    private var loading = false

    static let shared = ClipboardHistoryManager()

    init(directory: URL? = nil) {
        let base = directory ?? URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/ultracmd/clipboard", isDirectory: true)
        storeDir = base
        indexURL = base.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        lastChangeCount = NSPasteboard.general.changeCount
    }

    // MARK: Lifecycle

    func startWatching() {
        loadPersisted()
        guard timer == nil else { return }
        let t = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.poll() // RunLoop.main ensures main-thread execution
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopWatching() {
        timer?.invalidate()
        timer = nil
    }

    /// Called when UltraCMD itself (or an extension) writes to the pasteboard
    /// so the watcher doesn't capture our own writes.
    func suppressCaptureOnce() {
        suppressNextCapture = true
    }

    // MARK: Capture

    private func poll() {
        guard SettingsStore.shared.clipboardEnabled else { return }
        let pb = NSPasteboard.general
        let count = pb.changeCount
        guard count != lastChangeCount else { return }
        lastChangeCount = count
        guard !suppressNextCapture else {
            suppressNextCapture = false
            return
        }

        // The launcher is a non-activating panel, so whatever copied last is
        // (almost always) still the frontmost app.
        let source = NSWorkspace.shared.frontmostApplication
        let bundleID = source?.bundleIdentifier
        let appName = source?.localizedName

        // Never record secrets: password managers + the user's blocklist.
        let excluded = SettingsStore.shared.clipboardExcludedApps
        if let bundleID, excluded.contains(bundleID) { return }
        if SettingsStore.shared.clipboardIgnoreSecureApps,
           ClipClassifier.isSecureSource(bundleID: bundleID, appName: appName) {
            return
        }

        capture(pasteboard: pb, sourceBundleID: bundleID, sourceAppName: appName)
    }

    private func capture(pasteboard: NSPasteboard, sourceBundleID: String?, sourceAppName: String?) {
        let types = pasteboard.types ?? []
        var entry: ClipEntry?

        if types.contains(.fileURL), let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true,
        ]) as? [URL], !urls.isEmpty {
            entry = ClipEntry(
                id: UUID(), kind: .file, createdAt: Date(),
                text: urls.map(\.path).joined(separator: "\n"),
                filePaths: urls.map(\.path),
                sourceBundleID: sourceBundleID, sourceAppName: sourceAppName,
                firstCopiedAt: Date(), lastCopiedAt: Date()
            )
        } else if types.contains(.png) || types.contains(.tiff),
                  let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
                  let image = NSImage(data: data) {
            let name = "\(UUID().uuidString).png"
            let url = storeDir.appendingPathComponent(name)
            let png = image.pngData()
            let size = image.pixelSize
            if let png, (try? png.write(to: url, options: .atomic)) != nil {
                entry = ClipEntry(
                    id: UUID(), kind: .image, createdAt: Date(),
                    imagePath: url.path,
                    pixelWidth: size.width, pixelHeight: size.height,
                    sourceBundleID: sourceBundleID, sourceAppName: sourceAppName,
                    firstCopiedAt: Date(), lastCopiedAt: Date()
                )
            } else { entry = nil }
        } else if types.contains(.rtf), let rtf = pasteboard.data(forType: .rtf) {
            let text = pasteboard.string(forType: .string)
                ?? NSAttributedString(rtf: rtf, documentAttributes: nil)?.string
            let name = "\(UUID().uuidString).rtf"
            let url = storeDir.appendingPathComponent(name)
            if (try? rtf.write(to: url, options: .atomic)) != nil {
                entry = ClipEntry(
                    id: UUID(), kind: .rtf, createdAt: Date(),
                    text: text?.trimmingCharacters(in: .whitespacesAndNewlines),
                    rtfPath: url.path,
                    sourceBundleID: sourceBundleID, sourceAppName: sourceAppName,
                    firstCopiedAt: Date(), lastCopiedAt: Date()
                )
            } else { entry = nil }
        } else if let text = pasteboard.string(forType: .string) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            let kind: ClipKind
            var colorHex: String? = nil
            if let hex = ClipClassifier.colorHex(from: trimmed) {
                kind = .color
                colorHex = hex
            } else if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
                kind = .url
            } else {
                kind = .text
            }
            // Very long texts move to a sidecar file so index.json stays lean.
            let (inline, textPath) = ClipCompactor.compact(trimmed, directory: storeDir)
            entry = ClipEntry(
                id: UUID(), kind: kind, createdAt: Date(),
                text: inline, colorHex: colorHex,
                sourceBundleID: sourceBundleID, sourceAppName: sourceAppName,
                textPath: textPath,
                firstCopiedAt: Date(), lastCopiedAt: Date()
            )
        } else {
            entry = nil
        }

        guard let entry else { return }
        insert(entry)
        if entry.kind == .image { enrichWithOCR(entry) }
    }

    /// Background Vision text extraction for a freshly captured image.
    private func enrichWithOCR(_ entry: ClipEntry) {
        guard SettingsStore.shared.clipboardOCRText, let path = entry.imagePath else { return }
        let id = entry.id
        Task { [weak self] in
            guard let text = await ClipboardOCR.recognizeText(atPath: path) else { return }
            await MainActor.run { [weak self] in
                guard let self, let index = self.entries.firstIndex(where: { $0.id == id }) else { return }
                self.entries[index].ocrText = text
                self.persist()
            }
        }
    }

    private func insert(_ entry: ClipEntry) {
        // Re-copy of known content: bump counts, refresh source, float to top.
        if let index = entries.firstIndex(where: { $0.isSameContent(as: entry) }) {
            var existing = entries.remove(at: index)
            existing.copyCount = existing.timesCopied + 1
            existing.lastCopiedAt = Date()
            existing.sourceBundleID = entry.sourceBundleID
            existing.sourceAppName = entry.sourceAppName
            entries.insert(existing, at: 0)
            persist()
            return
        }
        entries.insert(entry, at: 0)
        applyRetention()
        persist()
    }

    /// Capacity + time-decay pruning in one pass (pinned entries survive).
    private func applyRetention() {
        let kept = ClipCompactor.prune(
            entries,
            capacity: SettingsStore.shared.clipboardCapacity,
            retentionDays: SettingsStore.shared.clipboardRetentionDays
        )
        guard kept.count != entries.count else { return }
        let keptIDs = Set(kept.map(\.id))
        let doomed = entries.filter { !keptIDs.contains($0.id) }
        // Sidecar payloads shared with a survivor (re-copies dedup to one
        // path) must not be deleted along with the dropped entry.
        let survivingTextPaths = Set(kept.compactMap(\.textPath))
        removePayloads(for: doomed.filter { entry in
            guard let path = entry.textPath else { return true }
            return !survivingTextPaths.contains(path)
        })
        entries = kept
    }

    // MARK: Read path

    /// Write an entry back to the pasteboard (paste action).
    func paste(_ entry: ClipEntry) {
        let pb = NSPasteboard.general
        suppressNextCapture = true
        lastChangeCount += 1 // our own write bumps changeCount; ignore it
        pb.clearContents()
        switch entry.kind {
        case .file:
            let urls = (entry.filePaths ?? []).compactMap { URL(fileURLWithPath: $0) }
            pb.writeObjects(urls as [NSURL])
        case .image:
            if let path = entry.imagePath, let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let image = NSImage(data: data) {
                pb.writeObjects([image])
            }
        case .rtf:
            if let path = entry.rtfPath, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                pb.declareTypes([.rtf, .string], owner: nil)
                pb.setData(data, forType: .rtf)
                if let text = entry.text { pb.setString(text, forType: .string) }
            } else if let text = entry.text {
                pb.setString(text, forType: .string)
            }
        case .url:
            if let text = entry.text, let url = URL(string: text) {
                pb.writeObjects([url as NSURL])
                pb.setString(text, forType: .string)
            }
        case .color, .text:
            pb.setString(entry.fullText ?? entry.colorHex ?? "", forType: .string)
        }
    }

    /// Plain-text variant of the write (strips RTF/file wrappers).
    func pastePlain(_ entry: ClipEntry) {
        let pb = NSPasteboard.general
        suppressNextCapture = true
        lastChangeCount += 1
        pb.clearContents()
        pb.setString(entry.fullText ?? entry.preview, forType: .string)
    }

    // MARK: Entry management

    func togglePin(_ entry: ClipEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index].pinned = !(entries[index].isPinned)
        persist()
    }

    func delete(_ entry: ClipEntry) {
        entries.removeAll { $0.id == entry.id }
        removePayloads(for: [entry])
        persist()
    }

    /// Bulk delete matching entries (⌘K "delete older than…"). Returns how
    /// many were removed so the caller can toast it.
    @discardableResult
    func delete(where predicate: (ClipEntry) -> Bool) -> Int {
        let doomed = entries.filter(predicate)
        guard !doomed.isEmpty else { return 0 }
        removePayloads(for: doomed)
        let doomedIDs = Set(doomed.map(\.id))
        entries.removeAll { doomedIDs.contains($0.id) }
        persist()
        return doomed.count
    }

    /// Delete unpinned entries older than the given date.
    @discardableResult
    func deleteOlder(than cutoff: Date) -> Int {
        delete(where: { !$0.isPinned && $0.lastCopied < cutoff })
    }

    func clearAll(keepingPinned: Bool) {
        if keepingPinned {
            let doomed = entries.filter { !$0.isPinned }
            removePayloads(for: doomed)
            entries = entries.filter { $0.isPinned }
        } else {
            removePayloads(for: entries)
            entries.removeAll()
        }
        persist()
    }

    /// Fuzzy search over history, honoring the type filter. Matching also
    /// covers the source app name ("copied from Xcode") and OCR text on
    /// image entries.
    func search(_ query: String, filter: ClipFilter = .all, limit: Int = 200) -> [ClipEntry] {
        let pool = entries.filter { filter.matches($0) }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return Array(pool.prefix(limit)) }
        let queryLower = trimmed.lowercased()
        let scored = pool.compactMap { entry -> (ClipEntry, Double)? in
            var best: (Double)? = nil
            if let m = FuzzySearch.match(queryLower: queryLower, textLower: entry.preview.lowercased()) {
                best = m.score
            }
            if let source = entry.sourceAppName?.lowercased(),
               let m = FuzzySearch.match(queryLower: queryLower, textLower: source) {
                best = max(best ?? -Double.infinity, m.score * 0.6)
            }
            if let ocr = entry.ocrText?.lowercased(), ocr.count <= 10_000,
               let m = FuzzySearch.match(queryLower: queryLower, textLower: String(ocr.prefix(2_000))) {
                best = max(best ?? -Double.infinity, m.score * 0.5)
            }
            guard var score = best else { return nil }
            if entry.isPinned { score += 8 }
            return (entry, score)
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(limit).map(\.0)
    }

    // MARK: Persistence

    private func persist() {
        guard !loading else { return }
        let snapshot = entries
        let url = indexURL
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadPersisted() {
        guard let data = try? Data(contentsOf: indexURL),
              let decoded = try? JSONDecoder().decode([ClipEntry].self, from: data) else { return }
        entries = decoded
        // Honor a lowered retention/capacity setting at launch, not just on
        // the next capture.
        loading = true
        applyRetention()
        loading = false
        if entries.count != decoded.count { persist() }
    }

    private func removePayloads(for clips: [ClipEntry]) {
        for clip in clips {
            if let p = clip.imagePath { try? FileManager.default.removeItem(atPath: p) }
            if let p = clip.rtfPath { try? FileManager.default.removeItem(atPath: p) }
            if let p = clip.textPath { try? FileManager.default.removeItem(atPath: p) }
        }
    }
}

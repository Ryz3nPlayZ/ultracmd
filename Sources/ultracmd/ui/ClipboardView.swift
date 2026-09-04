import SwiftUI

/// Clipboard history, Raycast-style (issue #4): a dual-pane surface —
/// left, the chronological list grouped into Pinned / Today / Yesterday /
/// Past 7 Days / Past 30 Days; right, an inspector with a live preview and
/// full metadata (source app, type, dimensions, copy frequency, timestamps).
/// The shared search bar filters (fuzzy, source-app aware); the type filter
/// chip (⌘P) narrows by kind; the footer pill pastes into the frontmost app.
struct ClipboardView: View {
    @ObservedObject var model: AppModel
    /// Top padding inside the scroll content (clears the floating header).
    var contentTopPadding: CGFloat

    @State private var visibleIDs: Set<UUID> = []
    @State private var lastSelectedIndex = 0

    private let detailWidth: CGFloat = 252

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            listPane
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 0.5)
                .padding(.vertical, 14)
            ClipDetailView(entry: model.selectedClipEntry, pasteTarget: model.pasteTargetName)
                .frame(width: detailWidth)
                .padding(.top, contentTopPadding - 6)
                .padding(.bottom, 58)
        }
        .onAppear {
            model.refreshClipboard()
        }
    }

    // MARK: List pane

    private struct ClipSection {
        let title: String
        let rows: [(index: Int, entry: ClipEntry)]
    }

    /// Searching shows one flat "Results" section; browsing groups by pin +
    /// date bucket while preserving flat indices for keyboard selection.
    private var sections: [ClipSection] {
        let enumerated = Array(model.clipboardResults.enumerated())
        guard model.query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return [ClipSection(title: "Results", rows: enumerated.map { (index: $0.offset, entry: $0.element) })]
        }
        var pinned: [(index: Int, entry: ClipEntry)] = []
        var buckets: [ClipDateBucket: [(index: Int, entry: ClipEntry)]] = [:]
        for pair in enumerated {
            if pair.element.isPinned {
                pinned.append((index: pair.offset, entry: pair.element))
            } else {
                buckets[pair.element.dateBucket, default: []].append((index: pair.offset, entry: pair.element))
            }
        }
        var out: [ClipSection] = []
        if !pinned.isEmpty {
            out.append(ClipSection(title: "Pinned", rows: pinned))
        }
        for bucket in ClipDateBucket.allCases {
            if let rows = buckets[bucket], !rows.isEmpty {
                out.append(ClipSection(title: bucket.rawValue, rows: rows))
            }
        }
        return out
    }

    @ViewBuilder
    private var listPane: some View {
        if model.clipboardResults.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        Color.clear.frame(height: contentTopPadding).id("clip-top")
                        ForEach(sections, id: \.title) { section in
                            sectionHeader(section.title)
                            ForEach(section.rows, id: \.entry.id) { row in
                                ClipRow(
                                    entry: row.entry,
                                    selected: row.index == model.clipboardSelectedIndex
                                )
                                .id(row.entry.id)
                                .onAppear { visibleIDs.insert(row.entry.id) }
                                .onDisappear { visibleIDs.remove(row.entry.id) }
                                .onTapGesture {
                                    model.clipboardSelectedIndex = row.index
                                }
                            }
                        }
                        // Clearance so the last rows clear the bottom fade.
                        Color.clear.frame(height: Theme.rowHeight + 26)
                    }
                    .padding(.horizontal, Theme.outerPadding)
                    .padding(.bottom, 8)
                }
                .noScrollIndicators()
                .onChange(of: model.clipboardSelectedIndex) { newIndex in
                    guard model.clipboardResults.indices.contains(newIndex) else { return }
                    let id = model.clipboardResults[newIndex].id
                    let goingDown = newIndex >= lastSelectedIndex
                    lastSelectedIndex = newIndex
                    guard !visibleIDs.contains(id) else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(id, anchor: goingDown ? .bottom : .top)
                    }
                }
                .onChange(of: model.query) { _ in
                    lastSelectedIndex = 0
                    visibleIDs.removeAll()
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo("clip-top", anchor: .top)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10.5, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.25))
            Text(model.query.isEmpty ? "Clipboard history is empty" : "Nothing matches “\(model.query)”")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, contentTopPadding)
    }
}

// MARK: - Row

/// One history row: type badge icon, single-line preview, sub-line with
/// kind · relative time · copy count, pin glyph for pinned entries.
/// Click selects (⏎ pastes — keyboard-centric by design).
struct ClipRow: View {
    let entry: ClipEntry
    let selected: Bool
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            leadingIcon

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.preview.isEmpty ? "(empty)" : entry.preview)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    Text(entry.typeLabel.uppercased())
                    Text("·")
                    Text(entry.lastCopied.relativeLabel)
                    if entry.timesCopied > 1 {
                        Text("·")
                        Text("×\(entry.timesCopied)")
                    }
                }
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.35))
            }

            Spacer(minLength: 8)

            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: Theme.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: Theme.itemRadius, style: .continuous)
                .fill(rowFill)
        )
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
    }

    private var rowFill: Color {
        if selected { return Color.white.opacity(Theme.selectionOpacity) }
        if hovered { return Color.white.opacity(0.04) }
        return .clear
    }

    @ViewBuilder
    private var leadingIcon: some View {
        switch entry.kind {
        case .image:
            if let path = entry.imagePath, let image = NSImage(contentsOf: URL(fileURLWithPath: path)) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 30, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .frame(width: 26, height: 26)
            } else {
                symbolIcon("photo")
            }
        case .color:
            if let color = entry.colorHex.map({ Color(hex: $0) ?? .white }) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: 18, height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                    .frame(width: 26, height: 26)
            } else {
                symbolIcon("paintpalette")
            }
        case .file:
            symbolIcon("folder.fill")
        case .url:
            symbolIcon("link")
        case .rtf:
            symbolIcon("doc.richtext")
        case .text:
            symbolIcon("text.quote")
        }
    }

    private func symbolIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 26, height: 26)
    }
}

// MARK: - Inspector pane

/// Right-hand metadata pane for the selected entry.
struct ClipDetailView: View {
    let entry: ClipEntry?
    let pasteTarget: String?

    var body: some View {
        Group {
            if let entry {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        previewCard(entry)
                        metadata(entry)
                        hint
                    }
                    .padding(.horizontal, 12)
                }
                .noScrollIndicators()
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "sidebar.right")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.2))
                    Text("Select an entry")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func previewCard(_ entry: ClipEntry) -> some View {
        VStack(spacing: 0) {
            switch entry.kind {
            case .image:
                if let path = entry.imagePath, let image = NSImage(contentsOf: URL(fileURLWithPath: path)) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 148)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(8)
                } else {
                    fallbackPreview("photo", "Image")
                }
            case .color:
                if let hex = entry.colorHex, let color = Color(hex: hex) {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                            .frame(height: 92)
                        Text(hex.uppercased())
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(8)
                } else {
                    fallbackPreview("paintpalette", "Color")
                }
            case .file:
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array((entry.filePaths ?? []).prefix(6).enumerated()), id: \.offset) { _, path in
                        HStack(spacing: 6) {
                            Image(systemName: "doc")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.5))
                            Text((path as NSString).lastPathComponent)
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    if (entry.filePaths ?? []).count > 6 {
                        Text("+ \((entry.filePaths ?? []).count - 6) more…")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            case .url:
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "link")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.55))
                    Text(entry.text ?? entry.preview)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(4)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
            case .rtf, .text:
                Text(entry.text ?? entry.preview)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func fallbackPreview(_ symbol: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.white.opacity(0.3))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
    }

    private func metadata(_ entry: ClipEntry) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            if let name = entry.sourceAppName ?? entry.sourceBundleID {
                metaRow("Source App") {
                    HStack(spacing: 6) {
                        if let bundleID = entry.sourceBundleID,
                           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                                .resizable()
                                .frame(width: 15, height: 15)
                        }
                        Text(name)
                    }
                }
            } else {
                metaRow("Source App") { Text("Unknown") }
            }
            metaRow("Content Type") { Text(entry.typeLabel) }
            if entry.kind == .image {
                if let w = entry.pixelWidth, let h = entry.pixelHeight {
                    metaRow("Dimensions") { Text("\(w) × \(h)") }
                }
                if let size = entry.payloadByteSize {
                    metaRow("File Size") { Text(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)) }
                }
            }
            if entry.kind == .text || entry.kind == .rtf || entry.kind == .url {
                if let text = entry.text, !text.isEmpty {
                    let lines = text.components(separatedBy: .newlines).count
                    let words = text.split(whereSeparator: \.isWhitespace).count
                    metaRow("Characters") { Text("\(text.count)") }
                    metaRow("Words · Lines") { Text("\(words) · \(lines)") }
                }
            }
            if (entry.filePaths?.count ?? 0) > 1 {
                metaRow("Entities") { Text("\(entry.filePaths?.count ?? 0) items") }
            }
            metaRow("Copy Frequency") {
                Text(entry.timesCopied == 1 ? "1 time" : "\(entry.timesCopied) times")
            }
            metaRow("First Copied") {
                Text(entry.firstCopied.formatted(date: .abbreviated, time: .shortened))
            }
            metaRow("Last Copied") {
                Text(entry.lastCopied.relativeLabelCapitalized)
            }
        }
    }

    private func metaRow<Content: View>(_ label: String, @ViewBuilder value: () -> Content) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(.white.opacity(0.38))
            Spacer(minLength: 10)
            value()
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.trailing)
        }
    }

    private var hint: some View {
        Text("⏎ Paste to \(pasteTarget ?? "Active App") · ⌘K Actions")
            .font(.system(size: 10.5))
            .foregroundStyle(.white.opacity(0.32))
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
    }
}

// MARK: - Helpers

extension Color {
    /// Parses "#RGB", "#RRGGBB" and "#RRGGBBAA" literals.
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 3 || value.count == 6 || value.count == 8,
              value.allSatisfy({ $0.isHexDigit }),
              let rgb = UInt64(value.suffix(6), radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

extension Date {
    var relativeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var relativeLabelCapitalized: String {
        relativeLabel.prefix(1).uppercased() + relativeLabel.dropFirst()
    }
}

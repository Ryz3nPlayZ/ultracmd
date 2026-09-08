import SwiftUI

/// Root launcher surface. Every page (search, clipboard, emoji picker, Quick
/// AI) is the *same* panel: one floating search bar, one scrolling list body
/// and the shared footer pills — Quick AI is no longer a separate-looking
/// canvas (issue #5). The list scrolls under the bar with an alpha mask; no
/// scrollbars. Selection is keyboard-driven; pointer hover is a separate,
/// purely visual highlight so both can be visible at once.
struct RootView: View {
    @ObservedObject var model: AppModel
    @FocusState private var searchFocused: Bool

    private var topBarHeight: CGFloat { Theme.searchBarHeight }
    /// Rows are crisp at rest but dissolve over this band when scrolled
    /// under the search bar. Kept tight — the bar should breathe against the
    /// list, not float away from it (issue #1).
    private var contentTopInset: CGFloat { topBarHeight + 6 }

    var body: some View {
        ZStack(alignment: .top) {
            backgroundLayer
            contentLayer
            chromeLayer
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .overlay(borderStroke)
        .preferredColorScheme(.dark)
        .onAppear { focusSearch() }
        .onChange(of: model.mode) { _ in
            focusSearch()
        }
        .onChange(of: model.focusSeed) { _ in
            focusSearch()
        }
        // Dismissing a palette (⌘K/esc) hands the keyboard back to the field.
        .onChange(of: model.actionPanelOpen) { open in
            if !open { focusSearch() }
        }
        .onChange(of: model.extActionPanelOpen) { open in
            if !open { focusSearch() }
        }
    }

    /// The hosting view persists across hide/show, so `onAppear` never
    /// re-fires — focus is re-armed through `model.focusSeed` (bumped every
    /// time the panel is summoned) and on every mode change. The runloop hop
    /// lets the field exist first.
    private func focusSearch() {
        Task { @MainActor in
            searchFocused = true
        }
    }

    // MARK: Layers

    /// Neutral charcoal over the native vibrancy — identical for every
    /// surface, Quick AI included (issue #5).
    private var backgroundLayer: some View {
        Theme.hudTint.opacity(Theme.hudOverlayOpacity)
    }

    @ViewBuilder
    private var contentLayer: some View {
        switch model.mode {
        case .root:
            underHeaderList {
                RootResultsView(model: model, contentTopPadding: contentTopInset)
            }
        case .clipboard:
            underHeaderList {
                ClipboardView(model: model, contentTopPadding: contentTopInset)
            }
        case .emojiPage:
            underHeaderList {
                EmojiGridView(model: model, contentTopPadding: contentTopInset)
            }
        case .extensionView:
            VStack(spacing: 0) {
                searchBar
                ExtensionView(model: model)
            }
        case .aiChat:
            // The transcript fades under the bar and above the footer itself.
            ZStack(alignment: .top) {
                ChatTranscript(
                    model: model,
                    topInset: topBarHeight,
                    emptyTitle: "Quick AI",
                    emptySubtitle: "Type a question · ⏎ send · Tab from search sends instantly"
                )
                searchBar
            }
        }
    }

    /// Full-height list with the frosted search bar floating on top of it.
    private func underHeaderList<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: .top) {
            content()
                .edgeFade(
                    topHiddenUntil: topBarHeight - 6,
                    topOpaqueFrom: topBarHeight + 10,
                    bottomOpaqueUntil: 48,
                    bottomHiddenFrom: 6
                )
            searchBar
        }
    }

    /// Floating chrome that sits above every mode's content.
    private var chromeLayer: some View {
        ZStack(alignment: .top) {
            footerPills
            overlays
        }
    }

    // MARK: Border

    private var borderStroke: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
            .strokeBorder(Color.white.opacity(Theme.borderOpacity), lineWidth: Theme.borderWidth)
    }

    // MARK: Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Button {
                if model.mode == .extensionView { model.closeExtension() }
                else if model.mode != .root { model.returnToRoot() }
            } label: {
                Image(systemName: leadingSymbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
            }
            .buttonStyle(.plain)
            .opacity(model.mode == .root ? 0.7 : 1)

            field
                .font(.system(size: Theme.searchFontSize, weight: .regular))
                .textFieldStyle(.plain)
                .foregroundStyle(.primary)

            if model.dictationActive {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(0.85)
                    .help("Dictation active")
            }

            if model.mode == .clipboard {
                filterChip
            }

            quickAIBadge
        }
        .padding(.horizontal, Theme.outerPadding)
        .frame(height: topBarHeight)
    }

    /// Clipboard type filter (⌘P): All/Text/Images/Files/Links/Colors.
    private var filterChip: some View {
        Button {
            model.clipboardFilterOpen.toggle()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: model.clipboardFilter.symbol)
                    .font(.system(size: 10.5, weight: .medium))
                Text(model.clipboardFilter.label)
                    .font(.system(size: 11.5, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
            .foregroundStyle(.white.opacity(0.62))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .liquidGlassCapsule(interactive: true)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Filter by type (⌘P)")
    }

    /// Tab → Quick AI fast path: sends the prompt immediately (issue #8).
    /// Plain muted text — no pill, no borders.
    @ViewBuilder
    private var quickAIBadge: some View {
        if model.mode == .extensionView {
            Text("esc")
                .font(.system(size: 10.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.40))
        } else if model.mode == .root || model.mode == .clipboard {
            Button {
                model.openChat(seed: model.query.isEmpty ? nil : model.query)
            } label: {
                HStack(spacing: 5) {
                    Text("tab")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.40))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("Quick AI")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Ask Quick AI (Tab sends immediately)")
        }
    }

    @ViewBuilder
    private var field: some View {
        switch model.mode {
        case .root, .clipboard, .emojiPage:
            TextField(placeholder, text: $model.query)
                .focused($searchFocused)
        case .extensionView:
            TextField(model.extDescriptor?.placeholder ?? "Search…", text: $model.extQuery)
                .focused($searchFocused)
        case .aiChat:
            // Quick AI shares the launcher's search bar as its prompt field —
            // same surface, same feel (issue #5). One stop control lives in
            // the footer pill; the old duplicate header button is gone.
            TextField("Ask anything…", text: $model.chatInput)
                .focused($searchFocused)
        }
    }

    private var placeholder: String {
        if let override = model.searchPlaceholderOverride { return override }
        switch model.mode {
        case .root: return "Search apps, commands, files…"
        case .clipboard: return "Search clipboard history…"
        case .aiChat: return "Ask anything…"
        case .emojiPage: return "Search emoji — fire, party, cat…"
        case .extensionView: return model.extDescriptor?.placeholder ?? "Search…"
        }
    }

    private var leadingSymbol: String {
        switch model.mode {
        case .root: return "text.magnifyingglass"
        case .clipboard: return "doc.on.clipboard"
        case .aiChat: return "wand.and.rays"
        case .emojiPage: return "face.smiling"
        case .extensionView: return "chevron.left"
        }
    }

    // MARK: Footer pills

    @ViewBuilder
    private var footerPills: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                appMenuPill
                Spacer(minLength: 12)
                actionSplitPill
            }
            .padding(.horizontal, Theme.outerPadding)
            .padding(.bottom, Theme.outerPadding)
        }
    }

    /// Bottom-left: larger glass capsule with the ⌘ glyph → custom liquid
    /// glass UltraCMD menu (issue #5 — no native dropdown).
    private var appMenuPill: some View {
        Button {
            if model.actionPanelOpen {
                model.actionPanelOpen = false
            } else {
                model.openAppMenu()
            }
        } label: {
            Image(systemName: "command")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.78))
                .frame(width: 40, height: Theme.footerPillHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .liquidGlassCapsule(interactive: true)
        .help("UltraCMD menu")
    }

    /// Bottom-right: larger split glass capsule [ primary ↵ | Actions ⌘K ].
    /// The primary half is surface-aware (Open / Paste to App / Ask / Stop /
    /// Copy emoji) and there is exactly one stop control (issue #5).
    private var actionSplitPill: some View {
        HStack(spacing: 0) {
            Button {
                model.performPrimaryFooterAction()
            } label: {
                HStack(spacing: 7) {
                    Text(model.primaryFooterLabel)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    Text("↵")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 13)
                .frame(height: Theme.footerPillHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 0.5, height: 14)

            Button {
                model.openActionPanel()
            } label: {
                HStack(spacing: 7) {
                    Text("⌘K")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Actions")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.88))
                .padding(.horizontal, 13)
                .frame(height: Theme.footerPillHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .liquidGlassCapsule(interactive: true)
        .help("Primary action (↵) · Actions (⌘K)")
    }

    // MARK: Overlays

    @ViewBuilder
    private var overlays: some View {
        ZStack {
            if model.actionPanelOpen {
                GlassActionPanel(
                    title: "Actions",
                    actions: model.actionPanelActions,
                    selectedIndex: model.actionPanelIndex,
                    anchorLeading: model.actionPanelAnchor == .leading,
                    filter: model.actionPanelFilter,
                    perform: { action in
                        model.actionPanelOpen = false
                        action.perform()
                    },
                    hover: { index in
                        if index != model.actionPanelIndex {
                            model.actionPanelIndex = index
                        }
                    }
                )
            }

            if model.extActionPanelOpen, let actions = model.selectedExtActions, !actions.isEmpty {
                GlassActionPanel(
                    title: "Actions",
                    actions: actions.map { action in
                        AppModel.PanelAction(
                            title: action.title ?? "Action",
                            shortcut: ShortcutParser.display(action.shortcut),
                            isDestructive: action.isDestructive
                        ) {
                            model.extActionPanelOpen = false
                            model.performExtAction(action)
                        }
                    },
                    selectedIndex: model.extActionPanelIndex,
                    anchorLeading: false,
                    filter: model.extActionPanelFilter,
                    perform: { action in
                        model.extActionPanelOpen = false
                        action.perform()
                    },
                    hover: { index in
                        if index != model.extActionPanelIndex {
                            model.extActionPanelIndex = index
                        }
                    }
                )
            }

            if model.clipboardFilterOpen {
                VStack {
                    HStack {
                        Spacer()
                        GlassContextMenu(items: ClipFilter.allCases.map { filter in
                            GlassContextMenu.Item(
                                icon: filter.symbol,
                                title: filter.label + (filter == model.clipboardFilter ? "  ✓" : "")
                            ) {
                                model.clipboardFilter = filter
                                model.clipboardFilterOpen = false
                                model.refreshClipboard()
                            }
                        })
                        .frame(width: 210)
                    }
                    .padding(.horizontal, Theme.outerPadding)
                    .padding(.top, topBarHeight + 4)
                    Spacer()
                }
            }

            if let request = model.confirmRequest {
                GlassConfirmDialog(request: request) {
                    model.confirmRequest = nil
                }
            }

            ToastOverlay(toasts: model.toasts) { id in
                model.dismissToast(id: id)
            }

            if let hud = model.hudText {
                VStack {
                    Spacer()
                    Text(hud)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .liquidGlassCapsule()
                        .padding(.bottom, 26)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeOut(duration: 0.14), value: model.actionPanelOpen)
        .animation(.easeOut(duration: 0.14), value: model.extActionPanelOpen)
        .animation(.easeOut(duration: 0.14), value: model.clipboardFilterOpen)
        .animation(.easeOut(duration: 0.18), value: model.hudText)
    }
}

// MARK: - Root results

/// One grouped slice of the flat result list. Flat indices are preserved so
/// keyboard selection (arrows, ⌘1–9, ↵) keeps addressing `model.results`.
private struct ResultSection {
    let title: String
    let rows: [(index: Int, result: SearchResult)]
}

struct RootResultsView: View {
    @ObservedObject var model: AppModel
    /// Top padding inside the scroll content so rows start below the
    /// floating search bar but can scroll under it.
    var contentTopPadding: CGFloat

    /// Row IDs currently realized by the LazyVStack (~visible viewport).
    /// Keyboard navigation only scrolls when the target leaves this set —
    /// no re-centering, no cursor-chasing.
    @State private var visibleIDs: Set<String> = []
    @State private var lastSelectedIndex = 0

    /// Empty query → Favorites section first (⌘F), then one mixed
    /// "Suggestions" section (kind labels on rows). Searching → grouped by
    /// kind with section headers, rows drop the redundant per-row label.
    private var sections: [ResultSection] {
        let enumerated = Array(model.results.enumerated())
        guard model.query.isEmpty else {
            var order: [SearchItemKind] = []
            var buckets: [SearchItemKind: [(index: Int, result: SearchResult)]] = [:]
            for pair in enumerated {
                let kind = pair.element.item.kind
                if buckets[kind] == nil {
                    order.append(kind)
                    buckets[kind] = []
                }
                buckets[kind]?.append((index: pair.offset, result: pair.element))
            }
            return order.compactMap { kind in
                buckets[kind].map { ResultSection(title: Self.sectionTitle(for: kind), rows: $0) }
            }
        }
        let favorites = enumerated.compactMap { pair -> (index: Int, result: SearchResult)? in
            model.isFavorite(pair.element.id) ? (index: pair.offset, result: pair.element) : nil
        }
        let rest = enumerated.compactMap { pair -> (index: Int, result: SearchResult)? in
            model.isFavorite(pair.element.id) ? nil : (index: pair.offset, result: pair.element)
        }
        var out: [ResultSection] = []
        if !favorites.isEmpty {
            out.append(ResultSection(title: "Favorites", rows: favorites))
        }
        out.append(ResultSection(title: "Suggestions", rows: rest))
        return out
    }

    private static func sectionTitle(for kind: SearchItemKind) -> String {
        switch kind {
        case .application: return "Applications"
        case .preferencePane: return "Settings"
        case .command: return "Commands"
        case .calculator: return "Calculator"
        case .extensionCommand: return "Extensions"
        case .file, .folder: return "Files & Folders"
        case .clipboardEntry: return "Clipboard"
        case .aiPrompt: return "AI"
        case .bookmark: return "Web"
        case .systemAction: return "System"
        case .emoji: return "Emoji & Symbols"
        case .quicklink: return "Quicklinks"
        case .snippet: return "Snippets"
        }
    }

    var body: some View {
        if model.results.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        Color.clear.frame(height: contentTopPadding).id("list-top")
                        ForEach(sections, id: \.title) { section in
                            sectionHeader(section.title)
                            ForEach(section.rows, id: \.result.id) { row in
                                ResultRow(
                                    result: row.result,
                                    index: row.index,
                                    selected: row.index == model.selectedIndex,
                                    showsKindLabel: model.query.isEmpty,
                                    isFavorite: model.query.isEmpty && model.isFavorite(row.result.id)
                                )
                                .id(row.result.id)
                                .onAppear { visibleIDs.insert(row.result.id) }
                                .onDisappear { visibleIDs.remove(row.result.id) }
                                .onTapGesture {
                                    model.selectedIndex = row.index
                                    model.runRootItem(row.result)
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
                .onChange(of: model.selectedIndex) { newIndex in
                    guard model.results.indices.contains(newIndex) else { return }
                    let id = model.results[newIndex].id
                    let goingDown = newIndex >= lastSelectedIndex
                    lastSelectedIndex = newIndex
                    // Already in the viewport → leave the scroll position alone.
                    guard !visibleIDs.contains(id) else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(id, anchor: goingDown ? .bottom : .top)
                    }
                }
                .onChange(of: model.query) { _ in
                    // New search → jump back to the top of the fresh list.
                    lastSelectedIndex = 0
                    visibleIDs.removeAll()
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo("list-top", anchor: .top)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: Theme.sectionHeaderSize, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.white.opacity(0.35))
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.25))
            Text(model.query.isEmpty ? "Search apps, files, emoji — or Tab to ask AI" : "No results for “\(model.query)”")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, contentTopPadding)
    }
}

/// One result row. `selected` is the keyboard cursor (arrow keys, ↵);
/// hover is an independent pointer highlight — both can be lit at once.
struct ResultRow: View {
    let result: SearchResult
    let index: Int
    let selected: Bool
    var showsKindLabel: Bool = false
    var isFavorite: Bool = false
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            ItemIconView.view(result.item.icon)

            VStack(alignment: .leading, spacing: 1) {
                Text(result.item.title)
                    .font(.system(size: Theme.rowTitleSize, weight: .medium))
                    .lineLimit(1)
                if let subtitle = result.item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            // Pinned by ⌘F — star trails the title so favorites are
            // recognizable wherever the row appears.
            if isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
            }

            // Kind labels only in the mixed Suggestions section — grouped
            // sections already carry it in their header.
            if showsKindLabel {
                Text(kindLabel)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.32))
            }
        }
        .padding(.horizontal, 10)
        .frame(height: Theme.rowHeight)
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

    private var kindLabel: String {
        switch result.item.kind {
        case .application: return "Application"
        case .preferencePane: return "Settings"
        case .command: return "Command"
        case .file: return "File"
        case .folder: return "Folder"
        case .calculator: return "Calculator"
        case .extensionCommand: return "Extension"
        case .clipboardEntry: return "Clipboard"
        case .aiPrompt: return "AI"
        case .bookmark: return "Web"
        case .systemAction: return "System"
        case .emoji: return "Emoji"
        case .quicklink: return "Quicklink"
        case .snippet: return "Snippet"
        }
    }
}

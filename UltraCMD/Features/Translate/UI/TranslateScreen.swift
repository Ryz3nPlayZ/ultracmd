import SwiftUI

/// Translate as one pane: source left, translation right, the swap floating between —
/// the pane owns its own multiline editor, so the palette's one-line field is hidden.
struct TranslateScreen: PaletteScreen {
    let vm: PaletteState
    let coordinator: TranslateCoordinator
    let pasteTarget: PasteTarget?
    let sourceMenuOpen: Bool
    let targetMenuOpen: Bool
    let openSourceMenu: () -> Void
    let openTargetMenu: () -> Void

    struct Row: Identifiable {
        let id = "translate"
    }

    let rows = [Row()]

    /// The source is paragraphs, not a query: the header field collapses line breaks.
    var hidesSearchField: Bool { true }

    /// ⏵ copies a result the moment one exists; before that it asks without waiting the debounce.
    var primaryActionTitle: String {
        coordinator.resultText != nil ? "Copy" : "Translate"
    }

    func hasPrimaryAction(at selection: Int) -> Bool {
        !coordinator.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func activate(at selection: Int) {
        if coordinator.resultText != nil {
            coordinator.copyResult()
        } else {
            coordinator.translateNow()
        }
    }

    func secondary(at selection: Int) -> Bool { false }

    func perform(_ shortcut: PaletteShortcut, at selection: Int) -> Bool {
        guard shortcut == .swapLanguages else { return false }
        coordinator.swap()
        return true
    }

    /// Escape clears the pane's text first — the rule the query served, screen-owned now.
    func consumeClearPress() -> Bool {
        guard !coordinator.sourceText.isEmpty else { return false }
        coordinator.clearSource()
        return true
    }

    func actions(at selection: Int) -> PopoverMenuContent? {
        var items: [PopoverMenuItem] = []
        if coordinator.resultText != nil {
            items.append(
                PopoverMenuItem(title: "Copy Translation", systemImage: "doc.on.doc") {
                    coordinator.copyResult()
                })
            if let pasteTarget {
                items.append(
                    PopoverMenuItem(
                        title: pasteTarget.pasteTitle,
                        icon: .paste(pasteTarget, fallback: "arrow.down.app")
                    ) {
                        coordinator.pasteToTargetApp()
                    })
            }
            items.append(
                PopoverMenuItem(
                    title: "Copy Source Text", systemImage: "doc.plaintext",
                    startsSection: pasteTarget == nil
                ) {
                    coordinator.copySource()
                })
            if coordinator.canContinueInChat {
                items.append(
                    PopoverMenuItem(
                        title: "Continue in AI Chat", systemImage: "sparkles",
                        startsSection: pasteTarget != nil
                    ) {
                        coordinator.continueInChat()
                    })
            }
        }
        items.append(
            PopoverMenuItem(
                title: "Swap Languages", systemImage: "arrow.left.arrow.right",
                startsSection: coordinator.resultText == nil
            ) {
                coordinator.swap()
            })
        if !coordinator.sourceText.isEmpty {
            items.append(
                PopoverMenuItem(title: "Clear Text", systemImage: "xmark.circle", startsSection: true) {
                    coordinator.clearSource()
                })
        }
        guard !items.isEmpty else { return nil }
        return PopoverMenuContent(header: "Translate", items: items)
    }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(
            TranslatePaneView(
                vm: vm,
                coordinator: coordinator,
                sourceMenuOpen: sourceMenuOpen, targetMenuOpen: targetMenuOpen,
                openSourceMenu: openSourceMenu, openTargetMenu: openTargetMenu))
    }
}

private struct TranslatePaneView: View {
    let vm: PaletteState
    let coordinator: TranslateCoordinator
    let sourceMenuOpen: Bool
    let targetMenuOpen: Bool
    let openSourceMenu: () -> Void
    let openTargetMenu: () -> Void

    @FocusState private var sourceFocused: Bool
    @Environment(\.metrics) private var metrics

    var body: some View {
        VStack(spacing: 0) {
            languageBar
            panes
        }
        .onAppear { sourceFocused = true }
        .onChange(of: vm.focusToken) { sourceFocused = true }
    }

    /// Each picker centres over its own pane; the gap keeps the swap button between them.
    private var languageBar: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HeaderMenuButton(
                title: coordinator.sourceTitle, icon: .symbol("globe"),
                isOpen: sourceMenuOpen, help: "Source language — Auto detects as you type",
                action: openSourceMenu)
            Spacer(minLength: 0)
            Color.clear.frame(width: metrics.size.barButtonHeight + metrics.spacing.md)
            Spacer(minLength: 0)
            HeaderMenuButton(
                title: coordinator.targetTitle, icon: .symbol("character.book.closed"),
                isOpen: targetMenuOpen, help: "Target language",
                action: openTargetMenu)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, metrics.spacing.xl)
        .padding(.top, metrics.spacing.md)
        .padding(.bottom, metrics.spacing.sm)
    }

    private var panes: some View {
        HStack(spacing: 0) {
            sourcePane
                .frame(maxWidth: .infinity)
            Rectangle()
                .fill(Theme.Colors.separator)
                .frame(width: 1)
                .padding(.vertical, metrics.spacing.lg)
            resultPane
                .frame(maxWidth: .infinity)
        }
        .overlay { swapButton }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var swapButton: some View {
        let side = metrics.size.barButtonHeight + metrics.spacing.md
        return Button {
            coordinator.swap()
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(metrics.typography.bar)
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: side, height: side)
                .background(Circle().fill(Theme.Colors.controlSurface))
                .overlay(Circle().strokeBorder(Theme.Colors.border, lineWidth: 1))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("Swap languages (⌘S)")
    }

    private var sourcePane: some View {
        VStack(spacing: 0) {
            editor
            Spacer(minLength: 0)
            sourceFooter
        }
        .padding(.leading, metrics.spacing.xl)
    }

    private var editor: some View {
        TextEditor(text: Binding(
            get: { coordinator.sourceText },
            set: { coordinator.sourceChanged($0) }))
            .font(metrics.typography.rowTitle)
            .scrollContentBackground(.hidden)
            .foregroundStyle(Theme.Colors.textPrimary)
            .focused($sourceFocused)
            .padding(.horizontal, metrics.spacing.lg)
            .padding(.top, metrics.spacing.lg)
            .overlay(alignment: .topLeading) {
                if coordinator.sourceText.isEmpty {
                    Text("Enter text…")
                        .font(metrics.typography.rowTitle)
                        .foregroundStyle(Theme.Colors.textTertiary)
                        .padding(.leading, metrics.spacing.lg + 4)
                        .padding(.top, metrics.spacing.lg + 4)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityLabel("Text to translate")
            // The panel's cursor policy reads this frame, so the editor gets the I-beam.
            .onGeometryChange(for: CGRect.self) {
                $0.frame(in: .global)
            } action: { vm.searchFieldFrame = $0 }
            .onDisappear { vm.searchFieldFrame = .zero }
    }

    private var sourceFooter: some View {
        HStack(spacing: metrics.spacing.sm) {
            BarButton(chrome: .rounded, action: { coordinator.dictation.toggle() }) {
                Image(systemName: coordinator.dictation.isActive ? "mic.fill" : "mic")
                    .font(metrics.typography.bar)
                    .foregroundStyle(
                        coordinator.dictation.isActive
                            ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
            }
            .help("Dictate the text")
            BarButton(chrome: .rounded, action: { coordinator.speakSource() }) {
                Image(
                    systemName: coordinator.speaker.activeText == coordinator.sourceText
                        ? "speaker.waveform.fill" : "speaker.waveform")
                    .font(metrics.typography.bar)
                    .foregroundStyle(
                        coordinator.speaker.activeText == coordinator.sourceText
                            ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
            }
            .help("Read the text aloud")
            Spacer(minLength: 0)
            if !coordinator.sourceText.isEmpty {
                let counts = TranslateModel.counts(for: coordinator.sourceText)
                Text("\(counts.words) words · \(counts.characters) characters")
                    .font(metrics.typography.rowTrailing)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, metrics.spacing.lg)
        .padding(.bottom, metrics.spacing.lg)
    }

    @ViewBuilder
    private var resultPane: some View {
        VStack(spacing: 0) {
            resultArea
                .padding(.leading, metrics.spacing.lg)
                .padding(.trailing, metrics.spacing.xl)
                .padding(.top, metrics.spacing.lg)
            Spacer(minLength: 0)
            HStack(spacing: metrics.spacing.sm) {
                Spacer(minLength: 0)
                BarButton(chrome: .rounded, action: { coordinator.speakResult() }) {
                    Image(
                        systemName: coordinator.speaker.activeText == coordinator.resultText
                            ? "speaker.waveform.fill" : "speaker.waveform")
                        .font(metrics.typography.bar)
                        .foregroundStyle(
                            coordinator.speaker.activeText == coordinator.resultText
                                ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                }
                .help("Read the translation aloud")
            }
            .padding(.trailing, metrics.spacing.xl)
            .padding(.bottom, metrics.spacing.lg)
            .opacity(coordinator.resultText == nil ? 0 : 1)
            .disabled(coordinator.resultText == nil)
        }
    }

    @ViewBuilder
    private var resultArea: some View {
        switch coordinator.phase {
        case .idle:
            Text("Translation")
                .font(metrics.typography.rowTitle)
                .foregroundStyle(Theme.Colors.textTertiary)
        case .translating:
            HStack(spacing: metrics.spacing.sm) {
                ProgressView().controlSize(.small)
                Text("Translating…")
                    .font(metrics.typography.rowTrailing)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        case .done(let text):
            ScrollView {
                Text(text)
                    .font(metrics.typography.rowTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.never)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle")
                .font(metrics.typography.rowTrailing)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

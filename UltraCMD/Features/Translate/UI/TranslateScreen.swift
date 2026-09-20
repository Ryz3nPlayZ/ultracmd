import SwiftUI

/// Translate as one native palette screen: the search field is the source, the body the result.
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

    /// ⏵ copies a result the moment one exists; before that it asks without waiting the debounce.
    var primaryActionTitle: String {
        coordinator.resultText != nil ? "Copy" : "Translate"
    }

    func hasPrimaryAction(at selection: Int) -> Bool {
        coordinator.resultText != nil || !vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func activate(at selection: Int) {
        if coordinator.resultText != nil {
            coordinator.copyResult()
        } else {
            coordinator.translateNow()
        }
    }

    func secondary(at selection: Int) -> Bool { false }

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
        }
        items.append(
            PopoverMenuItem(
                title: "Swap Languages", systemImage: "arrow.left.arrow.right",
                startsSection: coordinator.resultText == nil && pasteTarget == nil
            ) {
                coordinator.swap()
            })
        if !vm.query.isEmpty {
            items.append(
                PopoverMenuItem(title: "Clear Text", systemImage: "xmark.circle", startsSection: true) {
                    vm.query = ""
                })
        }
        guard !items.isEmpty else { return nil }
        return PopoverMenuContent(header: "Translate", items: items)
    }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(
            TranslateView(
                coordinator: coordinator,
                sourceMenuOpen: sourceMenuOpen, targetMenuOpen: targetMenuOpen,
                openSourceMenu: openSourceMenu, openTargetMenu: openTargetMenu))
    }
}

private struct TranslateView: View {
    let coordinator: TranslateCoordinator
    let sourceMenuOpen: Bool
    let targetMenuOpen: Bool
    let openSourceMenu: () -> Void
    let openTargetMenu: () -> Void

    @Environment(\.metrics) private var metrics

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            languageBar
            resultArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// The two pickers and the swap between them, in the surface the results sit under.
    private var languageBar: some View {
        HStack(spacing: metrics.spacing.sm) {
            HeaderMenuButton(
                title: coordinator.sourceTitle, icon: .symbol("globe"),
                isOpen: sourceMenuOpen, help: "Source language — Auto detects as you type",
                action: openSourceMenu)
            BarButton(chrome: .rounded, action: { coordinator.swap() }) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(metrics.typography.bar)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .help("Swap languages")
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

    @ViewBuilder
    private var resultArea: some View {
        switch coordinator.phase {
        case .idle:
            emptyState
        case .translating:
            HStack(spacing: metrics.spacing.sm) {
                ProgressView().controlSize(.small)
                Text("Translating…")
                    .font(metrics.typography.rowTrailing)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, metrics.spacing.xl)
            .padding(.top, metrics.spacing.lg)
        case .done(let text):
            ScrollView {
                Text(text)
                    .font(metrics.typography.rowTitle)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, metrics.spacing.xl)
                    .padding(.vertical, metrics.spacing.lg)
            }
            .scrollIndicators(.never)
        case .failed(let message):
            VStack(alignment: .leading, spacing: metrics.spacing.sm) {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(metrics.typography.rowTrailing)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.horizontal, metrics.spacing.xl)
            .padding(.top, metrics.spacing.lg)
        }
    }

    private var emptyState: some View {
        VStack(spacing: metrics.spacing.md) {
            Image(systemName: "translate")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tertiary)
            HStack(spacing: metrics.spacing.sm) {
                Text("Type to translate")
                KeyCapChip(text: "↵", style: .outline)
                Text("translates at once")
            }
            .font(metrics.typography.rowTrailing)
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

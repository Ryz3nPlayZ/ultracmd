import SwiftUI

// MARK: - Glass menu primitives
//
// Custom liquid-glass popups per the design docs: real `glassEffect`
// material on macOS 26, vibrancy fallback elsewhere. One tint per surface —
// neutral white selection fills, red reserved for destructive rows, no
// system-blue anywhere. Radius 14 for panels, SF Pro at HIG sizes.

/// A row in any glass menu: optional SF Symbol icon, title, right-aligned
/// shortcut glyph string, destructive styling. Implemented as a real Button
/// (plain style) so Accessibility/VoiceOver can press it.
struct GlassMenuRow: View {
    let icon: String?
    let title: String
    var shortcut: String? = nil
    var isDestructive = false
    var isSelected = false
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(rowIconColor)
                        .frame(width: 18)
                }
                Text(title)
                    .font(.system(size: 13, weight: isDestructive ? .semibold : .regular))
                    .foregroundStyle(rowTextColor)
                Spacer(minLength: 12)
                if let shortcut, !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(isSelected ? 0.75 : 0.38))
                }
            }
            .padding(.horizontal, 11)
            .frame(height: 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(rowFill)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in hovered = hovering }
    }

    /// Neutral menu-style selection: white fill, never the system accent.
    private var rowFill: Color {
        if isSelected { return Color.white.opacity(0.14) }
        if hovered { return Color.white.opacity(0.07) }
        return .clear
    }

    private var rowTextColor: Color {
        if isDestructive { return Color(red: 1.0, green: 0.42, blue: 0.40) }
        return Color.white.opacity(isSelected ? 0.96 : 0.88)
    }

    private var rowIconColor: Color {
        if isDestructive { return Color(red: 1.0, green: 0.42, blue: 0.40).opacity(0.9) }
        return Color.white.opacity(0.55)
    }
}

/// Hairline separator inside a glass menu.
struct GlassMenuDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 0.5)
            .padding(.horizontal, 11)
            .padding(.vertical, 4)
    }
}

/// The anchored glass panel itself: liquid-glass surface, 14pt continuous
/// corners, small-caps section header, fixed content width (~360pt) instead
/// of spanning the launcher. Bottom-aligned over a subtle scrim. Pointer
/// hover moves the keyboard cursor so both stay in sync. While a filter
/// string is active (typed after ⌘K, fzf-style) rows narrow to fuzzy title
/// matches and separators collapse.
struct GlassActionPanel: View {
    let title: String
    let actions: [AppModel.PanelAction]
    let selectedIndex: Int
    let anchorLeading: Bool
    var filter: String = ""
    let perform: (AppModel.PanelAction) -> Void
    var hover: (Int) -> Void = { _ in }

    private var filterText: String {
        filter.trimmingCharacters(in: .whitespaces)
    }

    /// Rows to render: unfiltered keeps separators; a filter drops them.
    private var visibleActions: [AppModel.PanelAction] {
        let q = filterText.lowercased()
        guard !q.isEmpty else { return actions }
        return actions.filter { action in
            guard !action.isSeparator else { return false }
            return FuzzySearch.match(queryLower: q, textLower: action.title.lowercased()) != nil
        }
    }

    var body: some View {
        let selectable = actions.filter { !$0.isSeparator }
        let visible = visibleActions
        VStack {
            Spacer(minLength: 100)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(Color.white.opacity(0.35))
                    Spacer(minLength: 8)
                    if !filterText.isEmpty {
                        Text(filterText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .lineLimit(1)
                            .help("Type to filter — backspace edits")
                    }
                }
                .padding(.horizontal, 11)
                .padding(.top, 9)
                .padding(.bottom, 3)

                if visible.isEmpty {
                    Text(filterText.isEmpty ? "No actions" : "No matching actions")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 1.5) {
                        ForEach(Array(visible.enumerated()), id: \.element.id) { visibleIndex, action in
                            if action.isSeparator {
                                GlassMenuDivider()
                            } else {
                                // Unfiltered: index among all selectable rows
                                // (separators skipped). Filtered: index within
                                // the visible list, which already excludes
                                // separators — matching the model's routing.
                                let selectableIndex = filterText.isEmpty
                                    ? (selectable.firstIndex(where: { $0.id == action.id }) ?? -1)
                                    : visibleIndex
                                GlassMenuRow(
                                    icon: action.icon,
                                    title: action.title,
                                    shortcut: action.shortcut,
                                    isDestructive: action.isDestructive,
                                    isSelected: selectableIndex == selectedIndex
                                ) {
                                    perform(action)
                                }
                                .onHover { hovering in
                                    if hovering, selectableIndex >= 0 {
                                        hover(selectableIndex)
                                    }
                                }
                            }
                        }
                    }
                    .padding(4)
                }
            }
            .frame(width: 360, alignment: .leading)
            .liquidGlassCard(cornerRadius: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .padding(.horizontal, Theme.outerPadding)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, alignment: anchorLeading ? .leading : .trailing)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.18)],
                startPoint: .top, endPoint: .bottom
            )
            .allowsHitTesting(false)
        )
    }
}

// MARK: - Confirm dialog

/// Model-driven glass confirmation (used for uninstall & friends):
/// centered card, Enter confirms, Esc cancels, destructive confirm is red.
struct ConfirmRequest: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var message: String
    var confirmLabel: String = "Confirm"
    var isDestructive = true
    var onConfirm: () -> Void = {}

    static func == (lhs: ConfirmRequest, rhs: ConfirmRequest) -> Bool { lhs.id == rhs.id }
}

struct GlassConfirmDialog: View {
    let request: ConfirmRequest
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(alignment: .leading, spacing: 12) {
                Text(request.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(request.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Spacer()
                    glassButton("Cancel", fill: Color.white.opacity(0.10), action: onCancel)
                    glassButton(
                        request.confirmLabel,
                        fill: request.isDestructive
                            ? Color(red: 1.0, green: 0.30, blue: 0.27)
                            : Color.white.opacity(0.16),
                        action: {
                            onCancel()
                            request.onConfirm()
                        }
                    )
                }
            }
            .padding(16)
            .frame(width: 320, alignment: .leading)
            .liquidGlassCard(cornerRadius: 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .transition(.scale(scale: 0.97).combined(with: .opacity))
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.85), value: request.id)
    }

    private func glassButton(_ label: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .padding(.horizontal, 14)
                .frame(height: 28)
                .background(
                    Capsule().fill(fill)
                )
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Hover/click context menu (chat (+) picker)

/// Simple anchored glass menu for pointer-driven pickers. Rows highlight on
/// hover; Esc closes via the model's open state.
struct GlassContextMenu: View {
    struct Item {
        let icon: String
        let title: String
        let action: () -> Void
    }

    let items: [Item]
    var width: CGFloat = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 1.5) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                GlassMenuRow(
                    icon: item.icon,
                    title: item.title,
                    action: item.action
                )
            }
        }
        .padding(5)
        .frame(width: width, alignment: .leading)
        .liquidGlassCard(cornerRadius: 13)
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

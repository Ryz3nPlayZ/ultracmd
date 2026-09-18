import SwiftUI

/// The palette header's screen-awareness toggle; the brighter glyph says the next message
/// carries the front window's text.
struct ScreenAwarenessButton: View {
    let enabled: Bool
    let action: () -> Void
    @Environment(\.metrics) private var metrics

    var body: some View {
        BarButton(chrome: .rounded, action: action) {
            Image(systemName: "rectangle.and.text.magnifyingglass")
                .font(metrics.typography.bar)
                .foregroundStyle(
                    enabled ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
        }
        .help(
            enabled
            ? "Screen awareness on — the next message carries the front window's text"
            : "Include the front window's text in the next message")
    }
}

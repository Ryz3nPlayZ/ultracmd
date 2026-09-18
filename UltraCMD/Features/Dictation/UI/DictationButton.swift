import SwiftUI

/// The palette header's dictation toggle; the filled glyph is the live microphone.
struct DictationButton: View {
    let controller: DictationController
    let action: () -> Void
    @Environment(\.metrics) private var metrics

    var body: some View {
        BarButton(chrome: .rounded, action: action) {
            Image(systemName: controller.isActive ? "mic.fill" : "mic")
                .font(metrics.typography.bar)
                .foregroundStyle(
                    controller.isActive ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
        }
        .help(controller.isActive ? "Stop dictation" : "Dictate into the search field")
    }
}

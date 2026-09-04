import SwiftUI

/// Full desktop AI Chat window (pop-out from Quick AI via ↗ or ⌘J, or the
/// "AI Chat" root command). Shares the AppModel conversation and the Quick
/// AI design language: dark matte canvas, right-aligned user capsules,
/// flush-left assistant text with the wand marker, floating dock. The
/// header is a glass toolbar with a gutter for the traffic lights.
struct FullChatView: View {
    @ObservedObject var model: AppModel
    @FocusState private var composerFocused: Bool

    private let headerHeight: CGFloat = 52

    var body: some View {
        ZStack(alignment: .bottom) {
            ChatTranscript(
                model: model,
                topInset: headerHeight,
                emptyTitle: "AI Chat",
                emptySubtitle: "Continue the conversation from Quick AI — or start a new one here"
            )
            ChatDock(
                model: model,
                text: $model.chatInput,
                busy: model.chatBusy,
                focus: $composerFocused,
                surface: .full
            )
            header
        }
        .preferredColorScheme(.dark)
        .background(Theme.chatCanvas.opacity(0.96))
        .onAppear { composerFocused = true }
    }

    private var header: some View {
        HStack(spacing: 12) {
            // Gutter for the window's traffic-light buttons.
            Color.clear.frame(width: 72)

            Image(systemName: "wand.and.rays")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.5))

            VStack(alignment: .leading, spacing: 1) {
                Text(model.chatTitle.isEmpty ? "AI Chat" : model.chatTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(model.services.ai.activeProvider.displayName) · \(model.chatAIModelName)")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.secondaryLabel)
                    .lineLimit(1)
            }

            Spacer()

            if model.chatBusy {
                toolButton(icon: "stop.circle.fill", tint: Color(red: 1.0, green: 0.42, blue: 0.40)) {
                    model.services.ai.cancel()
                }
                .help("Stop generating")
            }
            toolButton(icon: "doc.on.doc") {
                model.copyLastResponse()
            }
            .help("Copy last response")
            toolButton(icon: "plus.circle") {
                model.newChat()
            }
            .help("New conversation (⌘N)")
        }
        .padding(.horizontal, 14)
        .frame(height: headerHeight)
        .background(
            Rectangle().fill(.ultraThinMaterial).opacity(0.30)
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 0.5)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func toolButton(icon: String, tint: Color = .white.opacity(0.7), action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .liquidGlassCard(cornerRadius: 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

import AppKit
import SwiftUI

// Quick AI lives *inside* the launcher panel now (issue #5): RootView hosts
// `ChatTranscript` under the shared search bar (which doubles as the prompt
// field) with the standard footer pills — no separate canvas, no duplicate
// stop control. The pieces below are shared with the full AI Chat window,
// which still uses the floating `ChatDock` input.

/// Message list shared by Quick AI and AI Chat. Auto-scrolls while
/// streaming and fades out under the header above / input dock below.
struct ChatTranscript: View {
    @ObservedObject var model: AppModel
    var topInset: CGFloat
    var emptyTitle: String
    var emptySubtitle: String

    private let bottomClearance: CGFloat = 100

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if model.chatMessages.isEmpty, !model.chatBusy {
                        emptyState
                    }
                    ForEach(model.chatMessages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }
                    if model.chatBusy {
                        TypingBubble(text: model.chatStreamingText)
                            .id("streaming")
                    }
                    Color.clear.frame(height: bottomClearance).id("chat-bottom")
                }
                .padding(.horizontal, Theme.outerPadding + 2)
                .padding(.top, topInset + 10)
            }
            .noScrollIndicators()
            .edgeFade(
                topHiddenUntil: topInset - 2,
                topOpaqueFrom: topInset + 14,
                bottomOpaqueUntil: bottomClearance,
                bottomHiddenFrom: 8
            )
            .onChange(of: model.chatMessages.count) { _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("chat-bottom", anchor: .bottom)
                }
            }
            .onChange(of: model.chatStreamingText) { _ in
                proxy.scrollTo("chat-bottom", anchor: .bottom)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "wand.and.rays")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.28))
            Text(emptyTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
            Text(emptySubtitle)
                .font(.system(size: 11.5))
                .foregroundStyle(.white.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Messages

/// User prompts: tight right-aligned capsules. Assistant replies: flush
/// against the left margin with a small AI glyph marker, pure white with
/// airy line-height — reading speed over decoration.
struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 56)
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.94))
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Theme.chatUserBubble)
                    )
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.30))
                    .frame(width: 16)
                    .padding(.top, 3)
                Text(message.content)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .lineSpacing(4.5) // ≈1.4 line-height for effortless scanning
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Assistant reply while streaming: full text, or an animated three-dot
/// pulse before the first token arrives.
struct TypingBubble: View {
    let text: String

    var body: some View {
        if text.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.30))
                    .frame(width: 16)
                TypingDots()
            }
        } else {
            ChatBubble(message: ChatMessage(role: .assistant, content: text))
        }
    }
}

struct TypingDots: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: 4.5, height: 4.5)
                    .scaleEffect(phase ? 1.0 : 0.55)
                    .opacity(phase ? 0.9 : 0.35)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.16),
                        value: phase
                    )
            }
        }
        .padding(.top, 5)
        .onAppear { phase = true }
    }
}

// MARK: - Input dock

/// Three-element floating dock: (+) circular context picker, plain glass
/// input capsule (Enter sends — no visible send affordance), (⋯) palette
/// trigger. While streaming, a stop control replaces the palette button.
struct ChatDock: View {
    @ObservedObject var model: AppModel
    @Binding var text: String
    var busy: Bool
    var focus: FocusState<Bool>.Binding
    var surface: AppModel.ChatSurface
    @State private var contextOpen = false

    var body: some View {
        VStack(spacing: 8) {
            if contextOpen {
                GlassContextMenu(items: contextItems)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.outerPadding + 4)
            }
            HStack(spacing: 10) {
                contextButton
                inputCapsule
                paletteButton
            }
            .padding(.horizontal, Theme.outerPadding)
            .padding(.vertical, Theme.outerPadding)
        }
        .onChange(of: model.mode) { _ in contextOpen = false }
    }

    private var contextItems: [GlassContextMenu.Item] {
        var items: [GlassContextMenu.Item] = [
            .init(icon: "text.quote", title: "Selected Text (Frontmost App)") {
                contextOpen = false
                model.insertSelectionContext()
            },
            .init(icon: "folder", title: "File…") {
                contextOpen = false
                model.pickFileContext()
            },
            .init(icon: "calendar", title: "Today's Calendar Events") {
                contextOpen = false
                model.insertCalendarContext()
            },
            .init(icon: "cpu", title: "System State") {
                contextOpen = false
                model.insertSystemStateContext()
            },
        ]
        if !model.clipboardContextEntries.isEmpty {
            for entry in model.clipboardContextEntries.prefix(5) {
                items.append(.init(icon: "doc.on.clipboard", title: String(entry.preview.prefix(48))) {
                    contextOpen = false
                    model.appendChatContext(label: "Clipboard", body: entry.text ?? entry.preview)
                })
            }
        }
        return items
    }

    /// (+) attach local files, web selection, clipboard history, calendar…
    private var contextButton: some View {
        Button {
            contextOpen.toggle()
        } label: {
            dockCircle(icon: contextOpen ? "xmark" : "plus")
        }
        .buttonStyle(.plain)
        .help("Attach context")
    }

    /// Center capsule: plain input. Enter sends; nothing else to click.
    private var inputCapsule: some View {
        HStack(spacing: 8) {
            TextField("Ask anything…", text: $text)
                .font(.system(size: 13.5))
                .textFieldStyle(.plain)
                .focused(focus)
                .onSubmit { model.submitChat(surface: surface) }

            if busy {
                Button {
                    model.services.ai.cancel()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(red: 1.0, green: 0.42, blue: 0.40))
                }
                .buttonStyle(.plain)
                .help("Stop generating")
            }
        }
        .padding(.leading, 15)
        .padding(.trailing, 12)
        .frame(height: 40)
        .liquidGlassCapsule()
    }

    /// (⋯) secondary action palette (⌘K).
    private var paletteButton: some View {
        Button {
            model.openActionPanel()
        } label: {
            dockCircle(icon: "ellipsis")
        }
        .buttonStyle(.plain)
        .help("Actions (⌘K)")
    }

    /// 38pt liquid-glass circle.
    private func dockCircle(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
            .frame(width: 38, height: 38)
            .liquidGlass(in: Circle(), interactive: true)
            .contentShape(Circle())
    }
}

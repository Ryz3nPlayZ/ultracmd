import SwiftUI

/// Emoji picker page (issues #3/#7): one launcher surface with a searchable
/// grid instead of per-emoji rows polluting root search. Keyboard-first —
/// arrows walk the grid (columns stay in lockstep with `AppModel.emojiColumns`),
/// ⏎ copies without leaving the page, ⌘1–9 copy by number, Esc/backspace
/// returns to root search.
struct EmojiGridView: View {
    @ObservedObject var model: AppModel
    /// Top padding inside the scroll content (clears the floating search bar).
    var contentTopPadding: CGFloat

    @State private var visibleKeys: Set<String> = []
    @State private var lastSelectedIndex = 0

    var body: some View {
        Group {
            if model.emojiResults.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 6),
                                count: model.emojiColumns
                            ),
                            spacing: 6
                        ) {
                            Color.clear.frame(height: contentTopPadding - 8).id("emoji-top")
                            ForEach(Array(model.emojiResults.enumerated()), id: \.offset) { index, entry in
                                EmojiCell(
                                    entry: entry,
                                    selected: index == model.emojiSelectedIndex
                                )
                                .id(Self.key(index))
                                .onAppear { visibleKeys.insert(Self.key(index)) }
                                .onDisappear { visibleKeys.remove(Self.key(index)) }
                                .onTapGesture {
                                    model.emojiSelectedIndex = index
                                    model.copySelectedEmoji()
                                }
                            }
                            Color.clear.frame(height: Theme.rowHeight + 30)
                        }
                        .padding(.horizontal, Theme.outerPadding + 2)
                        .padding(.bottom, 8)
                    }
                    .noScrollIndicators()
                    .onChange(of: model.emojiSelectedIndex) { newIndex in
                        guard model.emojiResults.indices.contains(newIndex) else { return }
                        let key = Self.key(newIndex)
                        let goingDown = newIndex >= lastSelectedIndex
                        lastSelectedIndex = newIndex
                        guard !visibleKeys.contains(key) else { return }
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(key, anchor: goingDown ? .bottom : .top)
                        }
                    }
                    .onChange(of: model.query) { _ in
                        lastSelectedIndex = 0
                        visibleKeys.removeAll()
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo("emoji-top", anchor: .top)
                        }
                    }
                }
            }
        }
    }

    /// Grid identity: index-keyed (same emoji can appear twice across names).
    private static func key(_ index: Int) -> String { "emoji-\(index)" }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "face.dashed")
                .font(.system(size: 30))
                .foregroundStyle(.white.opacity(0.25))
            Text(model.query.isEmpty ? "No emoji loaded" : "No emoji matches “\(model.query)”")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, contentTopPadding)
    }
}

private struct EmojiCell: View {
    let entry: EmojiStore.Entry
    let selected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(entry.emoji)
                .font(.system(size: 25))
            Text(entry.name)
                .font(.system(size: 8.5))
                .foregroundStyle(selected ? .white.opacity(0.75) : .white.opacity(0.30))
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(selected ? Color.white.opacity(0.14) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.white.opacity(selected ? 0.22 : 0), lineWidth: 0.5)
        )
        .contentShape(Rectangle())
    }
}

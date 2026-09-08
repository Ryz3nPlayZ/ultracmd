import SwiftUI

/// Native SwiftUI rendering of the extension descriptor tree produced by the
/// JS shim: List (sections + items + accessories), Detail (markdown) and
/// Form (fields + submit actions).
struct ExtensionView: View {
    @ObservedObject var model: AppModel

    /// Realized item IDs (~visible viewport) for minimal keyboard scrolling.
    @State private var visibleItemIDs: Set<String> = []
    @State private var lastSelectedIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            if let descriptor = model.extDescriptor {
                if descriptor.isList {
                    listBody(descriptor)
                } else if descriptor.isForm {
                    formBody(descriptor)
                } else {
                    detailBody(descriptor)
                }
            } else {
                VStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading extension…")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Button {
                model.closeExtension()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Text(model.extDescriptor?.navigationTitle ?? "Extension")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            Spacer()

            if model.extDescriptor?.isLoading == true {
                ProgressView()
                    .controlSize(.small)
            }

            Text("⌘K actions · esc back")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.32))
        }
        .padding(.horizontal, Theme.outerPadding)
        .frame(height: 30)
    }

    // MARK: List

    private func listBody(_ descriptor: ExtDescriptor) -> some View {
        let items: [ExtItem] = descriptor.flatItems
        return Group {
            if items.isEmpty {
                emptyListBody(descriptor)
            } else {
                listScrollBody(descriptor: descriptor, items: items)
            }
        }
    }

    private func emptyListBody(_ descriptor: ExtDescriptor) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.25))
            Text(descriptor.isLoading == true ? "Loading…" : "No items")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func listScrollBody(descriptor: ExtDescriptor, items: [ExtItem]) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(descriptor.sections ?? []), id: \.self) { section in
                        self.sectionView(section)
                    }
                    // Clearance so the last rows clear the footer pills.
                    Color.clear.frame(height: Theme.rowHeight + 26)
                }
                .padding(.horizontal, Theme.outerPadding)
                .padding(.top, 4)
            }
            .noScrollIndicators()
            .onChange(of: model.extSelectedIndex) { newIndex in
                scrollToSelection(proxy: proxy, items: items, newIndex: newIndex)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: ExtSection) -> some View {
        if let title = section.title, !title.isEmpty {
            Text(title.uppercased())
                .font(.system(size: Theme.sectionHeaderSize, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.35))
                .padding(.horizontal, 10)
                .padding(.top, 7)
                .padding(.bottom, 2)
        }
        ForEach(Array(section.items.enumerated()), id: \.element.stableID) { globalIndex, item in
            self.itemRow(item: item, globalIndex: globalIndex)
                .onAppear { visibleItemIDs.insert(item.stableID) }
                .onDisappear { visibleItemIDs.remove(item.stableID) }
        }
    }

    private func itemRow(item: ExtItem, globalIndex: Int) -> some View {
        ExtItemRow(item: item, selected: globalIndex == model.extSelectedIndex)
            .id(item.stableID)
            .onTapGesture { self.activate(item: item) }
    }

    private func scrollToSelection(proxy: ScrollViewProxy, items: [ExtItem], newIndex: Int) {
        guard items.indices.contains(newIndex) else { return }
        let id = items[newIndex].stableID
        // Only scroll when the keyboard cursor leaves the realized viewport —
        // never re-centers while the user browses with the pointer.
        guard !visibleItemIDs.contains(id) else {
            lastSelectedIndex = newIndex
            return
        }
        let goingDown = newIndex >= lastSelectedIndex
        lastSelectedIndex = newIndex
        withAnimation(.easeOut(duration: 0.12)) {
            proxy.scrollTo(id, anchor: goingDown ? .bottom : .top)
        }
    }

    private func activate(item: ExtItem) {
        if let first = item.actions?.first {
            model.performExtAction(first)
        } else if let onClick = item.onClick {
            let eventId: String? = onClick
            model.services.extensions.dispatchEvent("perform", eventId, nil)
        }
    }

    // MARK: Detail

    private func detailBody(_ descriptor: ExtDescriptor) -> some View {
        ScrollView {
            MarkdownText(markdown: descriptor.markdown ?? "")
                .padding(Theme.outerPadding + 2)
                .padding(.bottom, Theme.rowHeight + 26)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .noScrollIndicators()
    }

    // MARK: Form

    private func formBody(_ descriptor: ExtDescriptor) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(descriptor.fields ?? []) { field in
                    ExtFormField(field: field, value: binding(for: field))
                }
                if let primary = descriptor.actions?.first {
                    Button {
                        model.performExtAction(primary)
                    } label: {
                        Text(primary.title ?? "Submit")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(
                                Capsule().fill(Color.white.opacity(0.16))
                            )
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.outerPadding + 2)
            .padding(.bottom, Theme.rowHeight + 26)
        }
        .noScrollIndicators()
    }

    private func binding(for field: ExtField) -> Binding<String> {
        Binding(
            get: { model.extFormValues[field.stableID] ?? "" },
            set: { model.extFormValues[field.stableID] = $0 }
        )
    }
}

// MARK: - Rows

struct ExtItemRow: View {
    let item: ExtItem
    let selected: Bool
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: IconMapper.symbol(for: item.icon))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title ?? "")
                    .font(.system(size: Theme.rowTitleSize, weight: .medium))
                    .lineLimit(1)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            ForEach(Array((item.accessories ?? []).enumerated()), id: \.offset) { _, accessory in
                HStack(spacing: 3) {
                    if let icon = accessory.icon {
                        Image(systemName: IconMapper.symbol(for: icon))
                            .font(.system(size: 10))
                    }
                    if let text = accessory.text, !text.isEmpty {
                        Text(text)
                            .font(.system(size: 10.5))
                    }
                }
                .foregroundStyle(.white.opacity(0.4))
            }

            if let count = item.actions?.count, count > 0 {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
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
}

// MARK: - Form fields

struct ExtFormField: View {
    let field: ExtField
    @Binding var value: String

    var body: some View {
        switch field.type {
        case "textarea":
            VStack(alignment: .leading, spacing: 4) {
                label
                TextEditor(text: $value)
                    .font(.system(size: 13))
                    .scrollContentBackground(.hidden)
                    .background(Color.white.opacity(0.05))
                    .frame(minHeight: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                info
            }
        case "password":
            VStack(alignment: .leading, spacing: 4) {
                label
                SecureField(field.placeholder ?? "", text: $value)
                    .textFieldStyle(.roundedBorder)
                info
            }
        case "checkbox":
            HStack {
                Toggle(isOn: Binding(
                    get: { value == "true" },
                    set: { value = $0 ? "true" : "false" }
                )) {
                    Text(field.label ?? "")
                        .font(.system(size: 13))
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                info
            }
        case "dropdown":
            VStack(alignment: .leading, spacing: 4) {
                label
                Picker("", selection: $value) {
                    ForEach(field.options ?? []) { option in
                        Text(option.label ?? option.value ?? "").tag(option.value ?? "")
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                info
            }
        case "description":
            VStack(alignment: .leading, spacing: 2) {
                if let label = field.label, !label.isEmpty {
                    Text(label).font(.system(size: 12, weight: .semibold))
                }
                Text(field.text ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                info
            }
        case "separator":
            Divider().overlay(Color.white.opacity(0.1))
        default:
            VStack(alignment: .leading, spacing: 4) {
                label
                TextField(field.placeholder ?? "", text: $value)
                    .textFieldStyle(.roundedBorder)
                info
            }
        }
    }

    @ViewBuilder
    private var label: some View {
        if let label = field.label, !label.isEmpty {
            Text(label).font(.system(size: 12, weight: .semibold))
        }
    }

    @ViewBuilder
    private var info: some View {
        if let info = field.info, !info.isEmpty {
            Text(info)
                .font(.system(size: 10.5))
                .foregroundStyle(.white.opacity(0.35))
        }
    }
}

// MARK: - Markdown

struct MarkdownText: View {
    let markdown: String

    var body: some View {
        if let attributed = try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            Text(attributed)
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(markdown)
                .font(.system(size: 13))
        }
    }
}

// MARK: - Action panel
//
// The action panel itself now lives in GlassMenu.swift (GlassActionPanel):
// custom liquid-glass popup, neutral selection, anchored bottom corners.

// MARK: - Toasts

struct ToastOverlay: View {
    let toasts: [AppModel.ToastData]
    let onDismiss: (String) -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                ForEach(toasts) { toast in
                    HStack(spacing: 7) {
                        Image(systemName: symbol(for: toast.style))
                            .font(.system(size: 12, weight: .medium))
                        VStack(alignment: .leading, spacing: 0) {
                            Text(toast.title).font(.system(size: 12, weight: .medium))
                            if !toast.message.isEmpty {
                                Text(toast.message)
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }
                    }
                    .foregroundStyle(color(for: toast.style))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture { onDismiss(toast.id) }
                }
            }
            .padding(.bottom, 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: toasts)
        }
        .allowsHitTesting(toasts.contains { _ in true })
    }

    private func symbol(for style: AppModel.ToastStyle) -> String {
        switch style {
        case .success: return "checkmark.circle.fill"
        case .failure: return "exclamationmark.triangle.fill"
        case .animated, .regular: return "info.circle.fill"
        }
    }

    private func color(for style: AppModel.ToastStyle) -> Color {
        switch style {
        case .success: return .green
        case .failure: return .orange
        case .animated, .regular: return .primary
        }
    }
}

import ServiceManagement
import SwiftUI

// MARK: - Settings window (glass redesign)
//
// The Settings window shares the launcher's design language: vibrancy HUD
// window, charcoal tint, glass cards with hairline rims, 10pt tracked
// section headers — no native NavigationSplitView chrome. System controls
// (toggles, sliders, menu pickers) render natively on top in dark mode.

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var settings = SettingsStore.shared

    enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case ai = "AI"
        case search = "Search"
        case userItems = "User Items"
        case clipboard = "Clipboard"
        case appearance = "Appearance"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .ai: return "wand.and.rays"
            case .search: return "magnifyingglass"
            case .userItems: return "star"
            case .clipboard: return "doc.on.clipboard"
            case .appearance: return "paintbrush"
            }
        }
    }

    @State private var tab: Tab = .general

    // AI provider state (mirrors Keychain-backed values)
    @State private var provider = SettingsStore.shared.aiProvider
    @State private var aiModel = SettingsStore.shared.aiModel
    @State private var quickModel = SettingsStore.shared.quickAIModel
    @State private var chatModel = SettingsStore.shared.aiChatModel
    @State private var systemPrompt = SettingsStore.shared.aiSystemPrompt
    @State private var ollamaEndpoint = SettingsStore.shared.ollamaEndpoint
    @State private var customEndpoint = SettingsStore.shared.customEndpoint
    @State private var apiKey = ""
    @State private var testing = false
    @State private var testResult: String?

    // General / search / clipboard
    @State private var fileSearch = SettingsStore.shared.fileSearchEnabled
    @State private var clipboardEnabled = SettingsStore.shared.clipboardEnabled
    @State private var clipboardCapacity = Double(SettingsStore.shared.clipboardCapacity)
    @State private var clipboardRetention = Double(SettingsStore.shared.clipboardRetentionDays)
    @State private var clipIgnoreSecure = SettingsStore.shared.clipboardIgnoreSecureApps
    @State private var clipExcludedApps = SettingsStore.shared.clipboardExcludedAppsRaw
    @State private var clipOCR = SettingsStore.shared.clipboardOCRText
    @State private var pasteQueueHotkey = SettingsStore.shared.pasteQueueHotkeyEnabled
    @State private var excludeDraft = SettingsStore.shared.excludePathsRaw
    @State private var axTrusted = AccessibilityHelper.isTrusted()
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var hiddenApps: [String] = []
    @State private var compactWindow = SettingsStore.shared.compactLauncherWindow

    // User items CRUD drafts
    @State private var favoriteIDs: [String] = []
    @State private var quicklinkDrafts: [Quicklink] = []
    @State private var snippetDrafts: [Snippet] = []

    var body: some View {
        ZStack {
            Theme.hudTint.opacity(Theme.hudOverlayOpacity)
            HStack(spacing: 0) {
                sidebar
                    .frame(width: 218)
                Rectangle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 0.5)
                detail
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            apiKey = Keychain.get(provider) ?? ""
            axTrusted = AccessibilityHelper.isTrusted()
            hiddenApps = Array(SettingsStore.shared.hiddenBundleIDs)
            favoriteIDs = SettingsStore.shared.favoriteItemIDs
            quicklinkDrafts = model.services.quicklinks.links
            snippetDrafts = model.services.snippets.snippets
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Gutter for the window's traffic lights.
            HStack(spacing: 8) {
                Image(systemName: "command.square.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text("UltraCMD")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 16)
            .padding(.top, 34)
            .padding(.bottom, 14)

            ForEach(Tab.allCases) { t in
                sidebarButton(t)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 3) {
                Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                Text("Native launcher · no telemetry")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.28))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }

    private func sidebarButton(_ t: Tab) -> some View {
        Button {
            tab = t
        } label: {
            HStack(spacing: 9) {
                Image(systemName: t.icon)
                    .font(.system(size: 12.5, weight: .medium))
                    .frame(width: 18)
                Text(t.rawValue)
                    .font(.system(size: 12.5, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white.opacity(tab == t ? 0.92 : 0.55))
            .padding(.horizontal, 10)
            .frame(height: 32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(tab == t ? 0.10 : 0))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
    }

    // MARK: Detail

    private var detail: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text(tab.rawValue)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, 26)
                switch tab {
                case .general: generalTab
                case .ai: aiTab
                case .search: searchTab
                case .userItems: userItemsTab
                case .clipboard: clipboardTab
                case .appearance: appearanceTab
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .noScrollIndicators()
    }

    // MARK: General tab

    private var generalTab: some View {
        VStack(spacing: 16) {
            GlassCard(title: "Launcher", footer: "Summon the launcher from anywhere with the global hotkey.") {
                SettingsRow(label: "Hotkey") {
                    menuPicker(selection: $settings.hotkeyIndex) {
                        ForEach(Array(HotkeyCombination.presets.enumerated()), id: \.offset) { index, combo in
                            Text(combo.displayName).tag(index)
                        }
                    }
                    .onChange(of: settings.hotkeyIndex) { _ in model.onHotkeyChanged() }
                }
                SettingsRow(label: "Launch at Login") {
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
                        .onChange(of: launchAtLogin) { on in
                            settings.launchAtLogin = on
                            do {
                                if on { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                NSLog("ultracmd login item: \(error)")
                            }
                        }
                }
                SettingsRow(
                    label: "Compact Window",
                    subtitle: "Short panel while the search is empty"
                ) {
                    Toggle("", isOn: $compactWindow)
                        .labelsHidden()
                        .onChange(of: compactWindow) { SettingsStore.shared.compactLauncherWindow = $0 }
                }
            }

            GlassCard(
                title: "Center Snapping",
                footer: "While dragging, dashed guides appear across the screen near the center. Release within this distance and the panel snaps onto the axis — otherwise it stays exactly where you dropped it."
            ) {
                SettingsRow(label: "Snap Distance") {
                    HStack {
                        Slider(value: $settings.snapThreshold, in: 4...24, step: 1)
                            .frame(width: 160)
                        Text("\(Int(settings.snapThreshold)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }

            GlassCard(
                title: "Permissions",
                footer: "Needed for automatic clipboard pasting, window tiling and selection rewriting. UltraCMD never re-prompts on its own — grant it once here and it sticks."
            ) {
                SettingsRow(label: "Accessibility") {
                    HStack(spacing: 10) {
                        if axTrusted {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            glassButton("Open System Settings") {
                                AccessibilityHelper.openAccessibilitySettings()
                            }
                            glassButton("Recheck") { axTrusted = AccessibilityHelper.isTrusted() }
                        }
                    }
                }
            }

            GlassCard(title: "About") {
                Text("UltraCMD — native launcher, AI workspace and Raycast-extension runner. Free & open, no telemetry.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: AI tab

    private var aiTab: some View {
        VStack(spacing: 16) {
            GlassCard(title: "AI Surfaces", footer: "Effort tunes the system instruction (brief ↔ step-by-step reasoning).") {
                surfaceRow(
                    "Quick AI",
                    subtitle: "Inline chat in the launcher — press Tab while searching",
                    override: $quickModel,
                    persist: { SettingsStore.shared.quickAIModel = $0 }
                )
                rowDivider
                surfaceRow(
                    "AI Chat",
                    subtitle: "Full desktop chat window",
                    override: $chatModel,
                    persist: { SettingsStore.shared.aiChatModel = $0 }
                )
                rowDivider
                SettingsRow(label: "Effort") {
                    menuPicker(selection: $settings.aiEffort) {
                        Text("Low").tag("low")
                        Text("Medium").tag("medium")
                        Text("High").tag("high")
                    }
                }
            }

            GlassCard(title: "Provider & Model", footer: currentProvider.needsAPIKey ? hintForKey : nil) {
                SettingsRow(label: "Provider") {
                    menuPicker(selection: Binding(
                        get: { provider },
                        set: { switchProvider($0) }
                    )) {
                        ForEach(AIProvider.allCases) { p in
                            Text(p.displayName).tag(p.rawValue)
                        }
                    }
                }

                if currentProvider.needsAPIKey {
                    SettingsRow(label: "API Key", subtitle: "Stored in Keychain") {
                        SecureField("sk-…", text: $apiKey)
                            .textFieldStyle(.plain)
                            .frame(width: 210)
                            .onChange(of: apiKey) { newValue in
                                if newValue.isEmpty { Keychain.delete(provider) }
                                else { Keychain.set(newValue, account: provider) }
                            }
                    }
                }

                SettingsRow(label: "Model") {
                    HStack {
                        plainField(text: $aiModel, prompt: "Model name", width: 190) {
                            SettingsStore.shared.aiModel = aiModel
                            model.commands.rebuild()
                        }
                        glassButton("Use Default") {
                            aiModel = currentProvider.defaultModel
                            SettingsStore.shared.aiModel = aiModel
                            model.commands.rebuild()
                        }
                    }
                }

                if currentProvider == .ollama {
                    ollamaRows
                    SettingsRow(label: "Endpoint") {
                        plainField(text: $ollamaEndpoint, prompt: "http://127.0.0.1:11434", width: 190) {
                            SettingsStore.shared.ollamaEndpoint = ollamaEndpoint
                            Task { await model.services.ollama.refresh(endpoint: ollamaEndpoint) }
                        }
                    }
                }
                if currentProvider == .custom {
                    SettingsRow(label: "Endpoint") {
                        plainField(text: $customEndpoint, prompt: "…/v1", width: 190) {
                            SettingsStore.shared.customEndpoint = customEndpoint
                        }
                    }
                }
            }

            GlassCard(title: "System Prompt") {
                TextEditor(text: $systemPrompt)
                    .font(.system(size: 12))
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(height: 72)
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    .onChange(of: systemPrompt) { SettingsStore.shared.aiSystemPrompt = $0 }
            }

            GlassCard(title: "Connection") {
                HStack {
                    glassButton(testing ? "Testing…" : "Test Connection", action: runTest)
                        .disabled(testing)
                    if let testResult {
                        Text(testResult)
                            .font(.system(size: 11))
                            .foregroundStyle(testResult.hasPrefix("✓") ? Color.green : Color.orange)
                    }
                }
            }
        }
    }

    /// Per-surface model row with a menu picker.
    private func surfaceRow(
        _ title: String,
        subtitle: String,
        override: Binding<String>,
        persist: @escaping (String) -> Void
    ) -> some View {
        SettingsRow(label: title, subtitle: subtitle) {
            menuPicker(selection: Binding(
                get: { override.wrappedValue },
                set: { newValue in
                    override.wrappedValue = newValue
                    persist(newValue)
                    model.commands.rebuild()
                }
            )) {
                Text("Provider Default — \(currentProvider.defaultModel)").tag("")
                ForEach(surfaceModelOptions, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
        }
    }

    private var surfaceModelOptions: [String] {
        var options = [currentProvider.defaultModel]
        let s = SettingsStore.shared
        for current in [s.quickAIModel, s.aiChatModel, s.aiModel]
        where !current.isEmpty && !options.contains(current) {
            options.append(current)
        }
        if currentProvider == .ollama {
            for name in model.services.ollama.models where !options.contains(name) {
                options.append(name)
            }
        }
        return options
    }

    private func switchProvider(_ rawValue: String) {
        provider = rawValue
        SettingsStore.shared.aiProvider = rawValue
        let p = AIProvider(rawValue: rawValue) ?? .openai
        aiModel = p.defaultModel
        SettingsStore.shared.aiModel = aiModel
        // Surface overrides reference the previous provider's models.
        quickModel = ""
        chatModel = ""
        SettingsStore.shared.quickAIModel = ""
        SettingsStore.shared.aiChatModel = ""
        apiKey = Keychain.get(rawValue) ?? ""
        model.commands.rebuild()
    }

    @ViewBuilder
    private var ollamaRows: some View {
        let discovery = model.services.ollama
        SettingsRow(label: "Local Models") {
            HStack(spacing: 6) {
                if discovery.models.isEmpty {
                    Text(discovery.checking ? "Checking…" : (discovery.lastError ?? "None found"))
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    menuPicker(selection: Binding(
                        get: { aiModel },
                        set: { newValue in
                            aiModel = newValue
                            SettingsStore.shared.aiModel = newValue
                            model.commands.rebuild()
                        }
                    )) {
                        ForEach(discovery.models, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }
                Button {
                    Task { await discovery.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.7))
                .disabled(discovery.checking)
                .help("Re-scan the local Ollama daemon")
            }
        }
    }

    // MARK: Search tab

    private var searchTab: some View {
        VStack(spacing: 16) {
            GlassCard(title: "Search Index", footer: "Include files from Spotlight and the curated System Settings panes in results.") {
                SettingsRow(label: "Spotlight File Search") {
                    Toggle("", isOn: $fileSearch)
                        .labelsHidden()
                        .onChange(of: fileSearch) { SettingsStore.shared.fileSearchEnabled = $0 }
                }
                rowDivider
                SettingsRow(label: "System Settings Panes") {
                    Toggle("", isOn: $settings.includeSettingsPanes)
                        .labelsHidden()
                        .onChange(of: settings.includeSettingsPanes) { _ in
                            model.services.search.rebuildIndexAsync()
                            model.refreshResults()
                        }
                }
                rowDivider
                SettingsRow(label: "Emoji in Search", subtitle: "Answer rows for emoji matches") {
                    Toggle("", isOn: Binding(
                        get: { SettingsStore.shared.emojiInlineInRoot },
                        set: {
                            SettingsStore.shared.emojiInlineInRoot = $0
                            model.refreshResults()
                        }
                    ))
                    .labelsHidden()
                }
            }

            GlassCard(
                title: "Sensitivity",
                footer: "Strict hides weak subsequence matches — only confident hits remain. Loose keeps every match (Raycast default behavior)."
            ) {
                SettingsRow(label: "Fuzziness") {
                    menuPicker(selection: Binding(
                        get: { SettingsStore.shared.searchSensitivityIndex },
                        set: {
                            SettingsStore.shared.searchSensitivityIndex = $0
                            model.refreshResults()
                        }
                    )) {
                        Text("Loose").tag(0)
                        Text("Normal").tag(1)
                        Text("Strict").tag(2)
                    }
                }
            }

            GlassCard(title: "Fallbacks", footer: "Shown when nothing matched your query.") {
                SettingsRow(label: "Ask AI") {
                    Toggle("", isOn: Binding(
                        get: { SettingsStore.shared.fallbackAIEnabled },
                        set: {
                            SettingsStore.shared.fallbackAIEnabled = $0
                            model.refreshResults()
                        }
                    ))
                    .labelsHidden()
                }
                rowDivider
                SettingsRow(label: "Search the Web") {
                    Toggle("", isOn: Binding(
                        get: { SettingsStore.shared.fallbackWebEnabled },
                        set: {
                            SettingsStore.shared.fallbackWebEnabled = $0
                            model.refreshResults()
                        }
                    ))
                    .labelsHidden()
                }
                rowDivider
                SettingsRow(label: "Search Engine") {
                    menuPicker(selection: Binding(
                        get: { SettingsStore.shared.webSearchEngineIndex },
                        set: { SettingsStore.shared.webSearchEngineIndex = $0 }
                    )) {
                        Text("Google").tag(0)
                        Text("DuckDuckGo").tag(1)
                        Text("Bing").tag(2)
                    }
                }
            }

            GlassCard(title: "Excluded Paths", footer: "One path per line, ~ allowed.") {
                TextEditor(text: $excludeDraft)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 72)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                HStack {
                    glassButton("Apply Exclusions") {
                        SettingsStore.shared.excludePathsRaw = excludeDraft
                        model.services.search.rebuildIndexAsync()
                        model.refreshResults()
                    }
                    .disabled(excludeDraft == settings.excludePathsRaw)
                }
            }

            if !hiddenApps.isEmpty {
                GlassCard(title: "Hidden from Search", footer: "Apps hidden via the ⌘K action. Showing them returns them to results.") {
                    ForEach(hiddenApps, id: \.self) { bundleID in
                        SettingsRow(label: hiddenAppTitle(bundleID)) {
                            glassButton("Show") {
                                var hidden = SettingsStore.shared.hiddenBundleIDs
                                hidden.remove(bundleID)
                                SettingsStore.shared.hiddenBundleIDs = hidden
                                hiddenApps = Array(hidden)
                                model.refreshResults()
                            }
                        }
                    }
                }
            }

            GlassCard(title: "Installed Extensions") {
                if model.services.extensions.extensions.isEmpty {
                    Text("No extensions found in ~/.ultracmd/extensions")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                } else {
                    ForEach(model.services.extensions.extensions, id: \.id) { ext in
                        HStack(spacing: 10) {
                            Image(systemName: "puzzlepiece")
                                .foregroundStyle(.white.opacity(0.55))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(ext.displayName)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                Text("\(ext.commands.count) command(s) · \(ext.directory.lastPathComponent)")
                                    .font(.system(size: 10.5))
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                HStack {
                    glassButton("Reload") {
                        model.services.extensions.reload()
                        model.services.search.rebuildIndexAsync()
                        model.refreshResults()
                    }
                    glassButton("Open Folder") {
                        ExtensionPaths.ensureExtensionsFolder()
                        NSWorkspace.shared.open(ExtensionPaths.extensionsFolderURL)
                    }
                }
            }
        }
    }

    private func hiddenAppTitle(_ bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let name = url.deletingPathExtension().lastPathComponent
            return name
        }
        return bundleID
    }

    // MARK: User items tab

    private var userItemsTab: some View {
        VStack(spacing: 16) {
            GlassCard(
                title: "Favorites",
                footer: "⌘F in the launcher pins the selected result to the top of the empty search view."
            ) {
                if favoriteIDs.isEmpty {
                    Text("No favorites yet — select a result in the launcher and press ⌘F.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(favoriteIDs, id: \.self) { id in
                        SettingsRow(label: favoriteTitle(id), subtitle: id) {
                            glassButton("Remove") {
                                SettingsStore.shared.toggleFavorite(id)
                                favoriteIDs = SettingsStore.shared.favoriteItemIDs
                            }
                        }
                    }
                }
            }

            GlassCard(
                title: "Quicklinks",
                footer: "URL shortcuts. {query} in the URL consumes the live search text — e.g. https://x.com/search?q={query}."
            ) {
                if quicklinkDrafts.isEmpty {
                    Text("No quicklinks — create one with “quicklink <name> <url>” in the launcher.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                ForEach($quicklinkDrafts) { $draft in
                    HStack(spacing: 8) {
                        plainField(text: $draft.name, prompt: "Name", width: 120) {
                            model.services.quicklinks.upsert(draft)
                        }
                        plainField(text: $draft.url, prompt: "https://…/{query}", width: 230) {
                            model.services.quicklinks.upsert(draft)
                        }
                        Button {
                            model.services.quicklinks.delete(id: draft.id)
                            quicklinkDrafts = model.services.quicklinks.links
                            model.refreshResults()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.55))
                        .help("Delete quicklink")
                    }
                }
                HStack {
                    glassButton("Add Quicklink") {
                        let draft = Quicklink(name: "New Quicklink", url: "https://")
                        quicklinkDrafts.append(draft)
                        model.services.quicklinks.upsert(draft)
                    }
                }
            }

            GlassCard(
                title: "Snippets",
                footer: "Text blocks pasted on Enter. {clipboard} inserts the current clipboard contents."
            ) {
                if snippetDrafts.isEmpty {
                    Text("No snippets — create one with “snippet <name> :: <body>” in the launcher.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.5))
                }
                ForEach($snippetDrafts) { $draft in
                    HStack(alignment: .top, spacing: 8) {
                        plainField(text: $draft.name, prompt: "Name", width: 120) {
                            model.services.snippets.upsert(draft)
                        }
                        TextEditor(text: $draft.body)
                            .font(.system(size: 11.5))
                            .scrollContentBackground(.hidden)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(height: 60)
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                            .onChange(of: draft.body) { _ in
                                model.services.snippets.upsert(draft)
                            }
                        Button {
                            model.services.snippets.delete(id: draft.id)
                            snippetDrafts = model.services.snippets.snippets
                            model.refreshResults()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white.opacity(0.55))
                        .help("Delete snippet")
                    }
                }
                HStack {
                    glassButton("Add Snippet") {
                        let draft = Snippet(name: "New Snippet", body: "")
                        snippetDrafts.append(draft)
                        model.services.snippets.upsert(draft)
                    }
                }
            }
        }
    }

    /// Pretty name for a favorited item id (falls back to the raw id).
    private func favoriteTitle(_ id: String) -> String {
        if let item = model.results.first(where: { $0.id == id })?.item {
            return item.title
        }
        if let link = model.services.quicklinks.links.first(where: { "quicklink:\($0.id.uuidString)" == id }) {
            return link.name
        }
        if let snippet = model.services.snippets.snippets.first(where: { "snippet:\($0.id.uuidString)" == id }) {
            return snippet.name
        }
        return id
    }

    // MARK: Clipboard tab

    private var clipboardTab: some View {
        VStack(spacing: 16) {
            GlassCard(
                title: "History",
                footer: "Copies made while 1Password, Bitwarden and friends are frontmost are never recorded. Add bundle IDs below to exclude any other app. Pinned entries survive Clear History."
            ) {
                SettingsRow(label: "Record History") {
                    Toggle("", isOn: $clipboardEnabled)
                        .labelsHidden()
                        .onChange(of: clipboardEnabled) { SettingsStore.shared.clipboardEnabled = $0 }
                }
                rowDivider
                SettingsRow(label: "Capacity") {
                    HStack {
                        Slider(value: $clipboardCapacity, in: 50...1000, step: 50)
                            .frame(width: 160)
                            .onChange(of: clipboardCapacity) { SettingsStore.shared.clipboardCapacity = Int($0) }
                        Text("\(Int(clipboardCapacity))")
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                rowDivider
                SettingsRow(label: "Keep For", subtitle: "Unpinned entries older than this are pruned") {
                    HStack {
                        Slider(value: $clipboardRetention, in: 0...365, step: 5)
                            .frame(width: 160)
                            .onChange(of: clipboardRetention) { SettingsStore.shared.clipboardRetentionDays = Int($0) }
                        Text(clipboardRetention == 0 ? "∞" : "\(Int(clipboardRetention)) d")
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                rowDivider
                SettingsRow(label: "Ignore Password Managers") {
                    Toggle("", isOn: $clipIgnoreSecure)
                        .labelsHidden()
                        .onChange(of: clipIgnoreSecure) { SettingsStore.shared.clipboardIgnoreSecureApps = $0 }
                }
                rowDivider
                SettingsRow(label: "Never Record From") {
                    plainField(text: $clipExcludedApps, prompt: "com.example.app, …", width: 210) {
                        SettingsStore.shared.clipboardExcludedAppsRaw = clipExcludedApps
                    }
                }
            }

            GlassCard(
                title: "Images",
                footer: "Recognized text is searchable (“find that screenshot with the license key”) and copyable via ⌘K → Copy Recognized Text."
            ) {
                SettingsRow(label: "Text Recognition", subtitle: "Vision OCR on captured images") {
                    Toggle("", isOn: $clipOCR)
                        .labelsHidden()
                        .onChange(of: clipOCR) { SettingsStore.shared.clipboardOCRText = $0 }
                }
            }

            GlassCard(
                title: "Paste Queue",
                footer: "Queue entries with ⌘K → Paste Sequentially, then paste them one by one into any app. The global chord also shadows Paste and Match Style in some apps — that's why it's off by default."
            ) {
                SettingsRow(label: "Global ⇧⌘V Hotkey", subtitle: "Paste next from anywhere") {
                    Toggle("", isOn: $pasteQueueHotkey)
                        .labelsHidden()
                        .onChange(of: pasteQueueHotkey) { SettingsStore.shared.pasteQueueHotkeyEnabled = $0 }
                }
                rowDivider
                SettingsRow(label: "Queue Now") {
                    Text(model.pasteQueue.isEmpty ? "Empty" : "\(model.pasteQueue.count) entr\(model.pasteQueue.count == 1 ? "y" : "ies")")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            GlassCard(title: "Maintenance") {
                HStack {
                    glassButton("Clear History Now", role: .destructive) {
                        model.services.clipboard.clearAll(keepingPinned: true)
                        model.clipboardResults = []
                    }
                }
            }
        }
    }

    // MARK: Appearance tab

    private var appearanceTab: some View {
        VStack(spacing: 16) {
            GlassCard(title: "Density", footer: "Scales the launcher's result rows.") {
                SettingsRow(label: "Interface Size") {
                    menuPicker(selection: $settings.interfaceSizeIndex) {
                        Text("Default").tag(0)
                        Text("Large").tag(1)
                        Text("Larger").tag(2)
                    }
                }
            }

            GlassCard(title: "Window", footer: "Applies the next time the launcher opens.") {
                SettingsRow(label: "Width") {
                    menuPicker(selection: $settings.launcherSizeMode) {
                        Text("Compact").tag(0)
                        Text("Expanded").tag(1)
                    }
                }
            }

            GlassCard(title: "Window Glass") {
                SettingsRow(label: "Blur Material") {
                    menuPicker(selection: $settings.blurMaterialIndex) {
                        Text("HUD Window").tag(0)
                        Text("Under-Window").tag(1)
                        Text("Menu").tag(2)
                    }
                }
                rowDivider
                SettingsRow(label: "Dark Tint") {
                    HStack {
                        Slider(value: $settings.tintOpacity, in: 0.3...0.8, step: 0.05)
                            .frame(width: 160)
                        Text(String(format: "%.0f%%", settings.tintOpacity * 100))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                rowDivider
                SettingsRow(label: "Corner Radius") {
                    HStack {
                        Slider(value: $settings.cornerRadius, in: 8...24, step: 1)
                            .frame(width: 160)
                        Text("\(Int(settings.cornerRadius)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            }

            GlassCard(title: "Presets") {
                HStack {
                    glassButton("Raycast Dark (default)") { applyPreset(tint: 0.60, corner: 18, material: 0) }
                    glassButton("Lighter Glass") { applyPreset(tint: 0.40, corner: 18, material: 1) }
                    glassButton("Compact") { applyPreset(tint: 0.60, corner: 12, material: 0) }
                }
            }
        }
    }

    private func applyPreset(tint: Double, corner: Double, material: Int) {
        settings.tintOpacity = tint
        settings.cornerRadius = corner
        settings.blurMaterialIndex = material
    }

    // MARK: Misc

    private var currentProvider: AIProvider {
        AIProvider(rawValue: provider) ?? .openai
    }

    private var hintForKey: String {
        switch currentProvider {
        case .openai: return "Create at platform.openai.com → API keys"
        case .anthropic: return "Create at console.anthropic.com → API keys"
        case .gemini: return "Create at aistudio.google.com → Get API key"
        default: return ""
        }
    }

    private func runTest() {
        testing = true
        testResult = nil
        let ai = AIChatService()
        Task { @MainActor in
            do {
                let reply = try await ai.complete("Reply with the single word OK.")
                testResult = reply.isEmpty ? "✓ Connected (empty reply)" : "✓ \(reply.prefix(60))"
            } catch {
                testResult = error.localizedDescription
            }
            testing = false
        }
    }
}

// MARK: - Glass primitives

/// One section card: tracked header, content rows, optional footer note.
private struct GlassCard<Content: View>: View {
    let title: String
    var footer: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.40))
            content
                .padding(.vertical, 2)
            if let footer {
                Text(footer)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(0.40))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
    }
}

/// Label-left / control-right settings row.
private struct SettingsRow<Value: View>: View {
    let label: String
    var subtitle: String? = nil
    @ViewBuilder var value: Value

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.88))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.42))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 12)
            value
        }
        .padding(.vertical, 4)
    }
}

private var rowDivider: some View {
    Rectangle()
        .fill(Color.white.opacity(0.08))
        .frame(height: 0.5)
        .padding(.vertical, 2)
}

private func glassButton(
    _ title: String,
    role: ButtonRole? = nil,
    action: @escaping () -> Void
) -> some View {
    Button(title, role: role, action: action)
        .buttonStyle(.plain)
        .font(.system(size: 11.5, weight: .medium))
        .foregroundStyle(role == .destructive ? Color.red.opacity(0.9) : Color.white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
}

private func menuPicker<Selection: Hashable>(selection: Binding<Selection>, @ViewBuilder content: () -> some View) -> some View {
    Picker("", selection: selection, content: content)
        .labelsHidden()
        .pickerStyle(.menu)
        .frame(maxWidth: 240)
}

private func plainField(
    text: Binding<String>,
    prompt: String,
    width: CGFloat,
    onCommit: @escaping () -> Void
) -> some View {
    TextField(prompt, text: text)
        .textFieldStyle(.plain)
        .font(.system(size: 11.5))
        .foregroundStyle(.white.opacity(0.9))
        .frame(width: width)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
        )
        .onSubmit(onCommit)
}

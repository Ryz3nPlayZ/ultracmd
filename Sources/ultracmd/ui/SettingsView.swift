import ServiceManagement
import SwiftUI

// MARK: - Settings window
//
// Rebuilt to match the macOS System Settings design language (apple.md):
// sidebar navigation with SF Symbol icons, grouped inset form sections with
// hairline separators, native controls, system appearance (light or dark),
// SF Pro at HIG sizes, no custom chrome. One accent per surface — the
// system accent for controls only.

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @ObservedObject private var settings = SettingsStore.shared

    enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case ai = "AI"
        case search = "Extensions & Search"
        case appearance = "Appearance"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .ai: return "wand.and.rays"
            case .search: return "square.stack.3x3"
            case .appearance: return "paintbrush"
            }
        }
    }

    @State private var tab: Tab = .general
    @State private var navFilter = ""

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

    // General
    @State private var fileSearch = SettingsStore.shared.fileSearchEnabled
    @State private var clipboardEnabled = SettingsStore.shared.clipboardEnabled
    @State private var clipboardCapacity = Double(SettingsStore.shared.clipboardCapacity)
    @State private var clipIgnoreSecure = SettingsStore.shared.clipboardIgnoreSecureApps
    @State private var clipExcludedApps = SettingsStore.shared.clipboardExcludedAppsRaw
    @State private var excludeDraft = SettingsStore.shared.excludePathsRaw
    @State private var axTrusted = AccessibilityHelper.isTrusted()
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var hiddenApps: [String] = []

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewColumnWidth(230)
        .frame(minWidth: 740, minHeight: 620)
        .onAppear {
            apiKey = Keychain.get(provider) ?? ""
            axTrusted = AccessibilityHelper.isTrusted()
            hiddenApps = Array(SettingsStore.shared.hiddenBundleIDs)
        }
    }

    // MARK: Sidebar

    /// Native translucent sidebar with the system search field.
    private var sidebar: some View {
        List(selection: tabSelection) {
            ForEach(filteredTabs) { t in
                Label(t.rawValue, systemImage: t.icon)
                    .tag(t)
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $navFilter, placement: .sidebar, prompt: "Search settings…")
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 26)
        }
    }

    private var filteredTabs: [Tab] {
        Tab.allCases.filter {
            navFilter.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(navFilter)
        }
    }

    private var tabSelection: Binding<Tab?> {
        Binding(
            get: { tab },
            set: { if let t = $0 { tab = t } }
        )
    }

    // MARK: Detail

    private var detail: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch tab {
                case .general: generalTab
                case .ai: aiTab
                case .search: searchTab
                case .appearance: appearanceTab
                }
            }
            .padding(.vertical, 18)
            .frame(maxWidth: 600, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .noScrollIndicators()
        .navigationTitle(tab.rawValue)
    }

    // MARK: General tab

    private var generalTab: some View {
        Form {
            Section {
                Picker("Hotkey", selection: $settings.hotkeyIndex) {
                    ForEach(Array(HotkeyCombination.presets.enumerated()), id: \.offset) { index, combo in
                        Text(combo.displayName).tag(index)
                    }
                }
                .onChange(of: settings.hotkeyIndex) { _ in model.onHotkeyChanged() }

                LabeledContent("Launch at Login") {
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
            } header: {
                Text("Launcher")
            } footer: {
                Text("Summon the launcher from anywhere with the global hotkey.")
            }

            Section {
                LabeledContent("Snap Distance") {
                    HStack {
                        Slider(value: $settings.snapThreshold, in: 4...24, step: 1)
                            .frame(width: 170)
                        Text("\(Int(settings.snapThreshold)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                }
            } header: {
                Text("Center Snapping")
            } footer: {
                Text("While dragging, dashed guides appear across the screen near the center. Release within this distance and the panel snaps onto the axis — otherwise it stays exactly where you dropped it.")
            }

            Section {
                LabeledContent("Record History") {
                    Toggle("", isOn: $clipboardEnabled)
                        .labelsHidden()
                        .onChange(of: clipboardEnabled) { SettingsStore.shared.clipboardEnabled = $0 }
                }
                LabeledContent("Capacity") {
                    HStack {
                        Slider(value: $clipboardCapacity, in: 50...1000, step: 50)
                            .frame(width: 170)
                            .onChange(of: clipboardCapacity) { SettingsStore.shared.clipboardCapacity = Int($0) }
                        Text("\(Int(clipboardCapacity))")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 38, alignment: .trailing)
                    }
                }
                LabeledContent("Ignore Password Managers") {
                    Toggle("", isOn: $clipIgnoreSecure)
                        .labelsHidden()
                        .onChange(of: clipIgnoreSecure) { SettingsStore.shared.clipboardIgnoreSecureApps = $0 }
                }
                LabeledContent("Never Record From") {
                    TextField("com.example.app, …", text: $clipExcludedApps)
                        .frame(width: 200)
                        .onChange(of: clipExcludedApps) { SettingsStore.shared.clipboardExcludedAppsRaw = $0 }
                }
                Button("Clear History Now", role: .destructive) {
                    model.services.clipboard.clearAll(keepingPinned: true)
                    model.clipboardResults = []
                }
            } header: {
                Text("Clipboard History")
            } footer: {
                Text("Copies made while 1Password, Bitwarden and friends are frontmost are never recorded. Add bundle IDs above to exclude any other app. Pinned entries survive Clear History.")
            }

            Section {
                LabeledContent {
                    HStack {
                        if axTrusted {
                            Label("Granted", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .labelStyle(.titleAndIcon)
                        } else {
                            Button("Open System Settings") {
                                AccessibilityHelper.openAccessibilitySettings()
                            }
                            Button("Recheck") { axTrusted = AccessibilityHelper.isTrusted() }
                        }
                    }
                } label: {
                    Text("Accessibility")
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Needed for window tiling and selection rewriting. UltraCMD never re-prompts on its own — grant it once here and it sticks.")
            }

            Section {
                Text("UltraCMD — native launcher, AI workspace and Raycast-extension runner. Free & open, no telemetry.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: AI tab

    private var aiTab: some View {
        Form {
            Section {
                surfaceRow(
                    "Quick AI",
                    subtitle: "Inline chat in the launcher — press Tab while searching",
                    override: $quickModel,
                    persist: { SettingsStore.shared.quickAIModel = $0 }
                )
                surfaceRow(
                    "AI Chat",
                    subtitle: "Full desktop chat window",
                    override: $chatModel,
                    persist: { SettingsStore.shared.aiChatModel = $0 }
                )
                Picker("Effort", selection: $settings.aiEffort) {
                    Text("Low").tag("low")
                    Text("Medium").tag("medium")
                    Text("High").tag("high")
                }
            } header: {
                Text("AI Surfaces")
            } footer: {
                Text("Effort tunes the system instruction (brief ↔ step-by-step reasoning).")
            }

            Section {
                Picker("Provider", selection: Binding(
                    get: { provider },
                    set: { switchProvider($0) }
                )) {
                    ForEach(AIProvider.allCases) { p in
                        Text(p.displayName).tag(p.rawValue)
                    }
                }

                if currentProvider.needsAPIKey {
                    SecureField("API Key (stored in Keychain)", text: $apiKey)
                        .onChange(of: apiKey) { newValue in
                            if newValue.isEmpty { Keychain.delete(provider) }
                            else { Keychain.set(newValue, account: provider) }
                        }
                }

                LabeledContent("Model") {
                    HStack {
                        TextField("Model name", text: $aiModel)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                            .onChange(of: aiModel) {
                                SettingsStore.shared.aiModel = $0
                                model.commands.rebuild()
                            }
                        Button("Use Default") {
                            aiModel = currentProvider.defaultModel
                            SettingsStore.shared.aiModel = aiModel
                            model.commands.rebuild()
                        }
                    }
                }

                if currentProvider == .ollama {
                    ollamaRows
                    LabeledContent("Endpoint") {
                        TextField("http://127.0.0.1:11434", text: $ollamaEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                            .onChange(of: ollamaEndpoint) { newValue in
                                SettingsStore.shared.ollamaEndpoint = newValue
                                Task { await model.services.ollama.refresh(endpoint: newValue) }
                            }
                    }
                }
                if currentProvider == .custom {
                    LabeledContent("Endpoint") {
                        TextField("…/v1", text: $customEndpoint)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                            .onChange(of: customEndpoint) { SettingsStore.shared.customEndpoint = $0 }
                    }
                }
            } header: {
                Text("Provider & Model")
            } footer: {
                if currentProvider.needsAPIKey {
                    Text(hintForKey)
                }
            }

            Section {
                TextField("System prompt", text: $systemPrompt, axis: .vertical)
                    .lineLimit(2...4)
                    .onChange(of: systemPrompt) { SettingsStore.shared.aiSystemPrompt = $0 }
            } header: {
                Text("System Prompt")
            }

            Section {
                HStack {
                    Button(testing ? "Testing…" : "Test Connection", action: runTest)
                        .disabled(testing)
                    if let testResult {
                        Text(testResult)
                            .font(.footnote)
                            .foregroundStyle(testResult.hasPrefix("✓") ? Color.green : Color.orange)
                    }
                }
            } header: {
                Text("Connection")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            Task { await model.services.ollama.refresh() }
        }
    }

    /// Per-surface model row with a right-aligned menu picker.
    private func surfaceRow(
        _ title: String,
        subtitle: String,
        override: Binding<String>,
        persist: @escaping (String) -> Void
    ) -> some View {
        LabeledContent {
            Picker("", selection: Binding(
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
            .labelsHidden()
            .buttonStyle(.borderless)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
        LabeledContent("Local Models") {
            HStack(spacing: 6) {
                if discovery.models.isEmpty {
                    Text(discovery.checking ? "Checking…" : (discovery.lastError ?? "None found"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("", selection: Binding(
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
                    .labelsHidden()
                    .buttonStyle(.borderless)
                }
                Button {
                    Task { await discovery.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(discovery.checking)
                .help("Re-scan the local Ollama daemon")
            }
        }
    }

    // MARK: Extensions & Search tab

    private var searchTab: some View {
        Form {
            Section {
                Toggle("Spotlight file search", isOn: $fileSearch)
                    .onChange(of: fileSearch) { SettingsStore.shared.fileSearchEnabled = $0 }
                Toggle("System Settings panes", isOn: $settings.includeSettingsPanes)
                    .onChange(of: settings.includeSettingsPanes) { _ in
                        model.services.search.rebuildIndex()
                        model.refreshResults()
                    }
            } header: {
                Text("Search Index")
            } footer: {
                Text("Include files from Spotlight and the curated System Settings panes in results.")
            }

            Section {
                TextEditor(text: $excludeDraft)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 76)
                    .scrollContentBackground(.hidden)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                HStack {
                    Button("Apply Exclusions") {
                        SettingsStore.shared.excludePathsRaw = excludeDraft
                        model.services.search.rebuildIndex()
                        model.refreshResults()
                    }
                    .disabled(excludeDraft == settings.excludePathsRaw)
                    Spacer()
                    Text("One path per line, ~ allowed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Excluded Paths")
            }

            if !hiddenApps.isEmpty {
                Section {
                    ForEach(hiddenApps, id: \.self) { bundleID in
                        LabeledContent(hiddenAppTitle(bundleID)) {
                            Button("Show") {
                                var hidden = SettingsStore.shared.hiddenBundleIDs
                                hidden.remove(bundleID)
                                SettingsStore.shared.hiddenBundleIDs = hidden
                                hiddenApps = Array(hidden)
                                model.refreshResults()
                            }
                        }
                    }
                } header: {
                    Text("Hidden from Search")
                } footer: {
                    Text("Apps hidden via the ⌘K action. Showing them returns them to results.")
                }
            }

            Section {
                if model.services.extensions.extensions.isEmpty {
                    Text("No extensions found in ~/.ultracmd/extensions")
                        .font(.body)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(model.services.extensions.extensions, id: \.id) { ext in
                        LabeledContent {
                            EmptyView()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "puzzlepiece")
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(ext.displayName)
                                    Text("\(ext.commands.count) command(s) · \(ext.directory.lastPathComponent)")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                HStack {
                    Button("Reload") {
                        model.services.extensions.reload()
                        model.services.search.rebuildIndex()
                        model.refreshResults()
                    }
                    Button("Open Folder") {
                        ExtensionPaths.ensureExtensionsFolder()
                        NSWorkspace.shared.open(ExtensionPaths.extensionsFolderURL)
                    }
                }
            } header: {
                Text("Installed Extensions")
            }
        }
        .formStyle(.grouped)
    }

    private func hiddenAppTitle(_ bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let name = url.deletingPathExtension().lastPathComponent
            return name
        }
        return bundleID
    }

    // MARK: Appearance tab

    private var appearanceTab: some View {
        Form {
            Section {
                Picker("Interface Size", selection: $settings.interfaceSizeIndex) {
                    Text("Default").tag(0)
                    Text("Large").tag(1)
                    Text("Larger").tag(2)
                }
            } header: {
                Text("Density")
            } footer: {
                Text("Scales the launcher's result rows.")
            }

            Section {
                Picker("Window Mode", selection: $settings.launcherSizeMode) {
                    Text("Compact").tag(0)
                    Text("Expanded").tag(1)
                }
                .pickerStyle(.inline)
            } header: {
                Text("Window")
            } footer: {
                Text("Applies the next time the launcher opens.")
            }

            Section {
                Picker("Blur Material", selection: $settings.blurMaterialIndex) {
                    Text("HUD Window").tag(0)
                    Text("Under-Window").tag(1)
                    Text("Menu").tag(2)
                }
                LabeledContent("Dark Tint") {
                    HStack {
                        Slider(value: $settings.tintOpacity, in: 0.3...0.8, step: 0.05)
                            .frame(width: 170)
                        Text(String(format: "%.0f%%", settings.tintOpacity * 100))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
                LabeledContent("Corner Radius") {
                    HStack {
                        Slider(value: $settings.cornerRadius, in: 8...24, step: 1)
                            .frame(width: 170)
                        Text("\(Int(settings.cornerRadius)) pt")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 42, alignment: .trailing)
                    }
                }
            } header: {
                Text("Window Glass")
            }

            Section {
                HStack {
                    Button("Raycast Dark (default)") { applyPreset(tint: 0.60, corner: 18, material: 0) }
                    Button("Lighter Glass") { applyPreset(tint: 0.40, corner: 18, material: 1) }
                    Button("Compact") { applyPreset(tint: 0.60, corner: 12, material: 0) }
                }
            } header: {
                Text("Presets")
            }
        }
        .formStyle(.grouped)
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

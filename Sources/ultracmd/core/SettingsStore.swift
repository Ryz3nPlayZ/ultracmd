import Foundation

/// App-wide user preferences, persisted to UserDefaults.
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    private let d: UserDefaults

    private enum Key {
        static let hotkeyIndex = "hotkeyIndex"
        static let clipboardEnabled = "clipboardEnabled"
        static let clipboardCapacity = "clipboardCapacity"
        static let fileSearchEnabled = "fileSearchEnabled"
        static let aiProvider = "aiProvider"
        static let aiModel = "aiModel"
        static let aiSystemPrompt = "aiSystemPrompt"
        static let aiEffort = "aiEffort"
        static let ollamaEndpoint = "ollamaEndpoint"
        static let customEndpoint = "customEndpoint"
        static let snapThreshold = "snapThreshold"
        static let launchAtLogin = "launchAtLogin"
        static let includeSettingsPanes = "includeSettingsPanes"
        static let excludePaths = "excludePaths"
        static let tintOpacity = "tintOpacity"
        static let windowCornerRadius = "windowCornerRadius"
        static let blurMaterial = "blurMaterial"
        static let interfaceSize = "interfaceSize"
        static let quickAIModel = "quickAIModel"
        static let aiChatModel = "aiChatModel"
        static let launcherSizeMode = "launcherSizeMode"
        static let hiddenApps = "hiddenBundleIDs"
        static let didRequestAX = "didRequestAccessibilityOnce"
        static let originX = "launcherOriginX"
        static let originY = "launcherOriginY"
        static let clipIgnoreSecure = "clipboardIgnoreSecureApps"
        static let clipExcludedApps = "clipboardExcludedApps"
    }

    init(defaults: UserDefaults = .standard) {
        d = defaults
        // Seed @Published values from the injected defaults (not .standard)
        // so test suites and the shared instance behave identically.
        hotkeyIndex = d.object(forKey: Key.hotkeyIndex) as? Int ?? 0
        includeSettingsPanes = d.object(forKey: Key.includeSettingsPanes) as? Bool ?? true
        excludePathsRaw = d.string(forKey: Key.excludePaths) ?? ""
        aiEffort = d.string(forKey: Key.aiEffort) ?? "medium"
        snapThreshold = (d.object(forKey: Key.snapThreshold) as? NSNumber)?.doubleValue ?? 12
        launchAtLogin = d.object(forKey: Key.launchAtLogin) as? Bool ?? false
        tintOpacity = (d.object(forKey: Key.tintOpacity) as? NSNumber)?.doubleValue ?? 0.60
        cornerRadius = (d.object(forKey: Key.windowCornerRadius) as? NSNumber)?.doubleValue ?? 18
        blurMaterialIndex = d.object(forKey: Key.blurMaterial) as? Int ?? 0
        interfaceSizeIndex = d.object(forKey: Key.interfaceSize) as? Int ?? 0
        launcherSizeMode = d.object(forKey: Key.launcherSizeMode) as? Int ?? 1
    }

    // MARK: Hotkey

    var hotkeyCombination: HotkeyCombination {
        HotkeyCombination.presets[min(max(hotkeyIndex, 0), HotkeyCombination.presets.count - 1)]
    }

    @Published var hotkeyIndex: Int = 0 {
        didSet { d.set(hotkeyIndex, forKey: Key.hotkeyIndex) }
    }

    // MARK: Clipboard

    var clipboardEnabled: Bool {
        get { d.object(forKey: Key.clipboardEnabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.clipboardEnabled) }
    }

    var clipboardCapacity: Int {
        get { max(50, min(2000, d.object(forKey: Key.clipboardCapacity) as? Int ?? 500)) }
        set { d.set(newValue, forKey: Key.clipboardCapacity) }
    }

    /// Skip capture while a password manager is frontmost (1Password,
    /// Bitwarden, …) so secrets never land in the history store.
    var clipboardIgnoreSecureApps: Bool {
        get { d.object(forKey: Key.clipIgnoreSecure) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.clipIgnoreSecure) }
    }

    /// Comma/newline-separated bundle IDs never captured (any app).
    var clipboardExcludedAppsRaw: String {
        get { d.string(forKey: Key.clipExcludedApps) ?? "" }
        set { d.set(newValue, forKey: Key.clipExcludedApps) }
    }

    var clipboardExcludedApps: Set<String> {
        Set(clipboardExcludedAppsRaw
            .split(whereSeparator: { $0 == "," || $0 == "\n" })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty })
    }

    // MARK: Search

    var fileSearchEnabled: Bool {
        get { d.object(forKey: Key.fileSearchEnabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.fileSearchEnabled) }
    }

    /// Show the curated System Settings panes in root search.
    @Published var includeSettingsPanes: Bool = true {
        didSet { d.set(includeSettingsPanes, forKey: Key.includeSettingsPanes) }
    }

    /// Newline-separated path prefixes excluded from app/pane indexing.
    @Published var excludePathsRaw: String = "" {
        didSet { d.set(excludePathsRaw, forKey: Key.excludePaths) }
    }

    var excludePaths: [String] {
        excludePathsRaw
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { ($0 as NSString).expandingTildeInPath }
    }

    // MARK: AI

    var aiProvider: String {
        get { d.string(forKey: Key.aiProvider) ?? AIProvider.openai.rawValue }
        set { d.set(newValue, forKey: Key.aiProvider) }
    }

    var aiModel: String {
        get { d.string(forKey: Key.aiModel) ?? "gpt-4o-mini" }
        set { d.set(newValue, forKey: Key.aiModel) }
    }

    var aiSystemPrompt: String {
        get { d.string(forKey: Key.aiSystemPrompt) ?? "You are a concise, helpful assistant inside the UltraCMD launcher." }
        set { d.set(newValue, forKey: Key.aiSystemPrompt) }
    }

    /// Reasoning effort hint: "low" | "medium" | "high".
    @Published var aiEffort: String = "medium" {
        didSet { d.set(aiEffort, forKey: Key.aiEffort) }
    }

    /// Extra system instruction derived from the effort level.
    var effortInstruction: String {
        switch aiEffort {
        case "low": return "Effort: low — answer as briefly as possible, skip preamble."
        case "high": return "Effort: high — reason step by step and be thorough."
        default: return ""
        }
    }

    var ollamaEndpoint: String {
        get { d.string(forKey: Key.ollamaEndpoint) ?? "http://127.0.0.1:11434" }
        set { d.set(newValue, forKey: Key.ollamaEndpoint) }
    }

    var customEndpoint: String {
        get { d.string(forKey: Key.customEndpoint) ?? "" }
        set { d.set(newValue, forKey: Key.customEndpoint) }
    }

    // MARK: Window & snapping

    /// Last user-placed launcher origin, persisted across launches.
    /// Nil until the user first drags the panel.
    var savedLauncherOrigin: CGPoint? {
        get {
            guard let x = d.object(forKey: Key.originX) as? Double,
                  let y = d.object(forKey: Key.originY) as? Double else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            guard let point = newValue else {
                d.removeObject(forKey: Key.originX)
                d.removeObject(forKey: Key.originY)
                return
            }
            d.set(point.x, forKey: Key.originX)
            d.set(point.y, forKey: Key.originY)
        }
    }

    /// Snap distance in points: drag-release within this of a screen center
    /// axis settles onto it; otherwise the panel stays exactly where dropped.
    @Published var snapThreshold: Double = 12 {
        didSet { d.set(snapThreshold, forKey: Key.snapThreshold) }
    }

    @Published var launchAtLogin: Bool = false {
        didSet { d.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }

    // MARK: Hidden (disabled) apps

    /// Bundle identifiers hidden from search by the ⌘K "Hide from Search"
    /// action (issue #6 "disable"). Comma-separated in defaults.
    var hiddenBundleIDs: Set<String> {
        get {
            Set((d.string(forKey: Key.hiddenApps) ?? "").split(separator: ",").map(String.init))
        }
        set {
            d.set(newValue.sorted().joined(separator: ","), forKey: Key.hiddenApps)
            objectWillChange.send()
        }
    }

    func isHiddenApp(_ bundleID: String?) -> Bool {
        guard let bundleID, !bundleID.isEmpty else { return false }
        return hiddenBundleIDs.contains(bundleID)
    }

    // MARK: Permissions bookkeeping

    /// True once we have ever shown the accessibility request — we never
    /// auto-prompt again after that (issue #7's repeating-prompt loop).
    var didRequestAccessibilityOnce: Bool {
        get { d.bool(forKey: Key.didRequestAX) }
        set { d.set(newValue, forKey: Key.didRequestAX) }
    }

    // MARK: Appearance

    /// Dark tint opacity over the vibrancy material (0.3–0.8).
    @Published var tintOpacity: Double = 0.60 {
        didSet { d.set(tintOpacity, forKey: Key.tintOpacity) }
    }

    /// Outer window corner radius in points (8–24).
    @Published var cornerRadius: Double = 18 {
        didSet { d.set(cornerRadius, forKey: Key.windowCornerRadius) }
    }

    /// 0 = .hudWindow, 1 = .underWindowBackground, 2 = .menu
    @Published var blurMaterialIndex: Int = 0 {
        didSet { d.set(blurMaterialIndex, forKey: Key.blurMaterial) }
    }

    /// Interface density for the launcher list: 0 default, 1 large, 2 larger.
    @Published var interfaceSizeIndex: Int = 0 {
        didSet { d.set(interfaceSizeIndex, forKey: Key.interfaceSize) }
    }

    /// Launcher window width preset: 0 compact (~640pt), 1 expanded (~760pt).
    @Published var launcherSizeMode: Int = 1 {
        didSet { d.set(launcherSizeMode, forKey: Key.launcherSizeMode) }
    }

    // MARK: AI surface model overrides ("" = follow the provider default)

    var quickAIModel: String {
        get { d.string(forKey: Key.quickAIModel) ?? "" }
        set { d.set(newValue, forKey: Key.quickAIModel) }
    }

    var aiChatModel: String {
        get { d.string(forKey: Key.aiChatModel) ?? "" }
        set { d.set(newValue, forKey: Key.aiChatModel) }
    }
}

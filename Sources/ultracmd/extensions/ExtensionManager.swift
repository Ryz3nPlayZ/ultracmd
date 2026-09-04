import Foundation

/// Filesystem layout for extensions:
///   ~/.ultracmd/extensions/<extension-dir>/package.json   (manifest)
///   ~/.ultracmd/extensions/<extension-dir>/src/<command>.js or index.js
///   ~/.ultracmd/storage/<extension-dir>.json              (LocalStorage)
enum ExtensionPaths {
    static var rootURL: URL {
        URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".ultracmd", isDirectory: true)
    }

    static var extensionsFolderURL: URL {
        rootURL.appendingPathComponent("extensions", isDirectory: true)
    }

    static var storageFolderURL: URL {
        rootURL.appendingPathComponent("storage", isDirectory: true)
    }

    static func ensureExtensionsFolder() {
        try? FileManager.default.createDirectory(at: extensionsFolderURL, withIntermediateDirectories: true)
    }

    static func storageURL(for extensionID: String) -> URL {
        storageFolderURL.appendingPathComponent("\(extensionID).json")
    }
}

/// Parsed extension manifest + commands.
struct ExtensionManifest: Codable {
    struct Command: Codable {
        var name: String
        var title: String?
        var description: String?
        var icon: String?
        var script: String?
        var mode: String?
    }

    var name: String?
    var title: String?
    var description: String?
    var icon: String?
    var commands: [Command]?
    var main: String?
}

struct InstalledExtension {
    let id: String // directory name
    let displayName: String
    let directory: URL
    let commands: [ExtensionManifest.Command]
}

struct ExtensionCommandRef {
    let extensionID: String
    let extensionName: String
    let command: ExtensionManifest.Command
    let scriptPath: URL

    var id: String { "ext:\(extensionID):\(command.name)" }
    var title: String { command.title ?? command.name.replacingOccurrences(of: "-", with: " ").capitalized }
}

/// Scans ~/.ultracmd/extensions, resolves manifests, launches commands in
/// JSRuntime instances and exposes search items.
@MainActor
final class ExtensionManager: ObservableObject {
    @Published private(set) var extensions: [InstalledExtension] = []
    @Published private(set) var lastError: String?

    // Callbacks into the launcher UI.
    var onRender: ((String) -> Void)? // descriptor JSON
    var onLog: ((String) -> Void)?
    var onToastShow: ((_ id: String, _ style: String, _ title: String, _ message: String) -> Void)?
    var onToastHide: ((String) -> Void)?
    var onHUD: ((String) -> Void)?
    var onClose: (() -> Void)?
    var onLaunchCommand: ((_ extensionID: String, _ name: String, _ argumentsJSON: String) -> Void)?
    var onOpenExtensionPreferences: (() -> Void)?

    private var activeRuntime: JSRuntime?

    var allCommandRefs: [ExtensionCommandRef] {
        extensions.flatMap { ext in
            ext.commands.compactMap { command in
                scriptPath(extension: ext, command: command).map {
                    ExtensionCommandRef(extensionID: ext.id, extensionName: ext.displayName, command: command, scriptPath: $0)
                }
            }
        }
    }

    var searchItems: [SearchItem] {
        allCommandRefs.map { ref in
            SearchItem(
                id: ref.id,
                title: ref.title,
                subtitle: "\(ref.extensionName) · Extension",
                kind: .extensionCommand,
                icon: .symbol(IconMapper.symbol(for: ref.command.icon)),
                keywords: [ref.command.name, ref.extensionName] + (ref.command.description.map { [$0] } ?? []),
                path: ref.scriptPath.path
            )
        }
    }

    // MARK: Discovery

    func reload() {
        ExtensionPaths.ensureExtensionsFolder()
        var found: [InstalledExtension] = []
        let fm = FileManager.default
        guard let dirs = try? fm.contentsOfDirectory(
            at: ExtensionPaths.extensionsFolderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            extensions = []
            return
        }

        for dir in dirs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { continue }
            let manifestURL = dir.appendingPathComponent("package.json")
            if let data = try? Data(contentsOf: manifestURL),
               let manifest = try? JSONDecoder().decode(ExtensionManifest.self, from: data) {
                found.append(makeInstalled(dir: dir, id: dir.lastPathComponent, manifest: manifest))
            } else {
                // No manifest: treat a single index.js as a one-command extension.
                let index = dir.appendingPathComponent("index.js")
                guard fm.fileExists(atPath: index.path) else { continue }
                let name = dir.lastPathComponent
                found.append(InstalledExtension(
                    id: name,
                    displayName: name.replacingOccurrences(of: "-", with: " ").capitalized,
                    directory: dir,
                    commands: [ExtensionManifest.Command(name: "index", title: nil, description: nil, icon: nil, script: "index.js", mode: nil)]
                ))
            }
        }
        extensions = found
    }

    private func makeInstalled(dir: URL, id: String, manifest: ExtensionManifest) -> InstalledExtension {
        let name = manifest.title ?? manifest.name ?? id.replacingOccurrences(of: "-", with: " ").capitalized
        var commands = manifest.commands ?? []
        if commands.isEmpty {
            commands = [ExtensionManifest.Command(
                name: "index", title: nil, description: manifest.description, icon: manifest.icon,
                script: manifest.main ?? "index.js", mode: nil
            )]
        }
        return InstalledExtension(id: id, displayName: name, directory: dir, commands: commands)
    }

    private func scriptPath(extension ext: InstalledExtension, command: ExtensionManifest.Command) -> URL? {
        let fm = FileManager.default
        if let script = command.script {
            let direct = ext.directory.appendingPathComponent(script)
            if fm.fileExists(atPath: direct.path) { return direct }
            let src = ext.directory.appendingPathComponent("src/\(script)")
            if fm.fileExists(atPath: src.path) { return src }
        }
        let srcDefault = ext.directory.appendingPathComponent("src/\(command.name).js")
        if fm.fileExists(atPath: srcDefault.path) { return srcDefault }
        let index = ext.directory.appendingPathComponent("index.js")
        if fm.fileExists(atPath: index.path) { return index }
        return nil
    }

    func commandRef(id: String) -> ExtensionCommandRef? {
        allCommandRefs.first { $0.id == id }
    }

    func commandRef(extensionID: String, name: String) -> ExtensionCommandRef? {
        allCommandRefs.first { $0.extensionID == extensionID && ($0.command.name == name || $0.command.script == name) }
    }

    // MARK: Execution

    func launch(ref: ExtensionCommandRef) {
        guard let source = try? String(contentsOf: ref.scriptPath, encoding: .utf8) else {
            lastError = "Cannot read \(ref.scriptPath.path)"
            return
        }
        let transformed = ESMTransformer.transform(source)
        let runtime = JSRuntime(bridge: makeBridge(extensionID: ref.extensionID))
        activeRuntime = runtime

        let options: [String: Any] = [
            "extensionName": ref.extensionName,
            "commandName": ref.title,
            "isDevelopment": false,
        ]
        let optionsJSON = (try? JSONSerialization.serializedJSString(options)) ?? "{}"
        ExtensionPaths.ensureExtensionsFolder()
        try? FileManager.default.createDirectory(at: ExtensionPaths.storageFolderURL, withIntermediateDirectories: true)
        runtime.run(
            script: transformed,
            bootOptionsJSON: optionsJSON,
            storageFile: ExtensionPaths.storageURL(for: ref.extensionID)
        )
    }

    func dispatchEvent(_ event: String, _ a: String?, _ b: String?) {
        activeRuntime?.dispatch(event, a, b)
    }

    func terminateActive() {
        activeRuntime = nil
    }

    private func makeBridge(extensionID: String) -> JSRuntime.Bridge {
        var bridge = JSRuntime.Bridge()
        bridge.onRender = { [weak self] json in
            Task { @MainActor in self?.onRender?(json) }
        }
        bridge.onLog = { [weak self] message in
            Task { @MainActor in self?.onLog?(message) }
        }
        bridge.onClose = { [weak self] in
            Task { @MainActor in self?.onClose?() }
        }
        bridge.onHUD = { [weak self] text in
            Task { @MainActor in self?.onHUD?(text) }
        }
        bridge.onToastShow = { [weak self] id, style, title, message in
            Task { @MainActor in self?.onToastShow?(id, style, title, message) }
        }
        bridge.onToastHide = { [weak self] id in
            Task { @MainActor in self?.onToastHide?(id) }
        }
        bridge.onLaunchCommand = { [weak self] name, argumentsJSON in
            Task { @MainActor in self?.onLaunchCommand?(extensionID, name, argumentsJSON) }
        }
        bridge.onOpenExtensionPreferences = { [weak self] in
            Task { @MainActor in self?.onOpenExtensionPreferences?() }
        }
        return bridge
    }
}

extension JSONSerialization {
    /// JSON string with bare keywords that is safe to embed in scripts.
    static func serializedJSString(_ object: Any) throws -> String {
        let data = try data(withJSONObject: object, options: [.sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}

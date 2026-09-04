import AppKit

@main
enum UltraCMDApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // agent app: status item, no Dock icon
        app.run()
    }
}

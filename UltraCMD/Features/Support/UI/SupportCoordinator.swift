import AppKit
import SwiftUI

/// The support window's lifecycle. Every route lands here, so the anchor moves once per showing.
@MainActor
final class SupportCoordinator {
    /// The one place the outbound link is written down; every surface links to this.
    /// This fork takes no money: the link credits the project that wrote the code.
    static let checkout = URL(string: "https://github.com/abue-ammar/tinycast")!

    private let store: SupportReminderStore
    /// Environment injection and activity reads only — never for state this type owns.
    private unowned let core: AppCore
    private lazy var window = AppWindowController(
        title: "Support UltraCMD", contentSize: SupportWindowView.initialSize,
        activation: core.activationPolicy)

    init(store: SupportReminderStore, core: AppCore) {
        self.store = store
        self.core = core
    }

    func showSupport() {
        store.markAsked()
        window.show {
            SupportWindowView(support: self)
                .environment(self.core.settings)
        }
    }

    /// The reminder's path: it asks only when nothing else has the user's attention.
    func presentIfDue() {
        guard core.canInterruptUser else { return }
        showSupport()
    }

    func openCheckout() {
        NSWorkspace.shared.open(Self.checkout)
        window.close()
    }

    /// The window takes the height its content measured, so nothing is padded out with space.
    func fit(height: CGFloat) {
        window.fitContent(width: SupportWindowView.width, height: height)
    }

    func focusExisting() -> Bool {
        window.focus()
    }
}

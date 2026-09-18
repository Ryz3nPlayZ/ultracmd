import Foundation

/// Side-by-side apps with their own bundle ids, so a build updates within its own.
enum ReleaseChannel: Sendable {
    case stable
    case beta
    /// A local build. It has no release stream, and never updates itself.
    case development

    init(bundleID: String?) {
        switch bundleID {
        case "com.ultracmd.app": self = .stable
        case "com.ultracmd.app.beta": self = .beta
        default: self = .development
        }
    }

    /// This fork publishes no release feed, so no channel ever polls or offers one; the
    /// command, the daily check and the prompt all gate on this and stay gone.
    var updatesItself: Bool { false }

    /// Beta ships as a GitHub prerelease and stable does not; neither ever sees the other's.
    func accepts(prerelease: Bool) -> Bool {
        switch self {
        case .stable: return !prerelease
        case .beta: return prerelease
        case .development: return false
        }
    }
}

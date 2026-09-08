import Foundation

/// Watches the application / preference-pane directories for installs,
/// removals and renames using vnode events, and reports a debounced change
/// so the index can re-scan off the main thread. Without this, newly
/// installed apps stay invisible until a manual re-index or relaunch.
final class AppDirectoryWatcher {

    /// Fired on the watcher's own queue, at most once per debounce window.
    var onChange: () -> Void = {}

    private var sources: [DispatchSourceFileSystemObject] = []
    private let queue = DispatchQueue(label: "ultracmd.appwatch", qos: .utility)
    private var pendingReload: DispatchWorkItem?

    func start(directories: [String]) {
        stop()
        for dir in Set(directories) {
            let fd = open(dir, O_EVTONLY)
            guard fd >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename],
                queue: queue
            )
            // A directory vnode fires `.write` when its entry list changes.
            source.setEventHandler { [weak self] in
                self?.scheduleReload()
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            sources.append(source)
        }
    }

    func stop() {
        for source in sources { source.cancel() }
        sources.removeAll()
        pendingReload?.cancel()
        pendingReload = nil
    }

    deinit {
        // cancel handlers close the fds; sources keep themselves alive until
        // their cancel handler runs.
        for source in sources { source.cancel() }
    }

    private func scheduleReload() {
        pendingReload?.cancel()
        // Installers write bundles progressively — debounce until the
        // directory has been quiet for a moment, then re-scan.
        let work = DispatchWorkItem { [weak self] in
            self?.pendingReload = nil
            self?.onChange()
        }
        pendingReload = work
        queue.asyncAfter(deadline: .now() + 2.0, execute: work)
    }
}

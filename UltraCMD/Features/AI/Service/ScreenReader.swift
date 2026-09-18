import AppKit
import CoreGraphics
import ScreenCaptureKit
import Vision

/// Reads the front window of one app: a ScreenCaptureKit frame, then on-device OCR over it.
struct ScreenReader {
    enum ReadingError: Error, Equatable {
        /// No Screen Recording grant. The caller still sends the message, without the screen.
        case denied
        /// Nothing to read: the app left, owns no on-screen window, or the frame carried no text.
        case nothingToRead
    }

    func readFrontmostWindow(of app: NSRunningApplication?) async
        -> Result<ScreenReading, ReadingError>
    {
        guard let app, app.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return .failure(.nothingToRead)
        }
        guard CGPreflightScreenCaptureAccess() else { return .failure(.denied) }
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            guard
                let window = content.windows.first(where: {
                    $0.owningApplication?.processID == app.processIdentifier && $0.isActive
                }) ?? content.windows.first(where: {
                    $0.owningApplication?.processID == app.processIdentifier
                })
            else { return .failure(.nothingToRead) }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: SCStreamConfiguration())
            let text = try await Self.ocr(image)
            guard !text.isEmpty else { return .failure(.nothingToRead) }
            return .success(
                ScreenReading(
                    appName: app.localizedName ?? "the front app",
                    windowTitle: window.title ?? "",
                    text: text))
        } catch {
            return .failure(.nothingToRead)
        }
    }

    /// Vision's handler is synchronous and CPU-bound, so it runs detached off the main actor.
    /// `CGImage` predates Sendable and is immutable in practice, hence the box.
    private static func ocr(_ image: CGImage) async throws -> String {
        let boxed = BoxedCGImage(image: image)
        return try await Task.detached(priority: .userInitiated) { () throws -> String in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            try VNImageRequestHandler(cgImage: boxed.image).perform([request])
            return (request.results ?? [])
                .compactMap { $0.topCandidates(1).first?.string }
                .joined(separator: "\n")
        }.value
    }

    private struct BoxedCGImage: @unchecked Sendable {
        let image: CGImage
    }
}

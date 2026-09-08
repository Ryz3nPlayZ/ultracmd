import AppKit
import Vision

/// Live-text extraction for image clippings (Vision). Runs entirely off the
/// main thread; results land on the clipboard entry as searchable text.
enum ClipboardOCR {

    /// Recognize text in an image file. Returns nil when nothing was found.
    /// Never blocks the caller's actor — the request runs on a detached task.
    static func recognizeText(atPath path: String) async -> String? {
        guard let image = NSImage(contentsOf: URL(fileURLWithPath: path)),
              let tiff = image.tiffRepresentation,
              let cgImage = NSBitmapImageRep(data: tiff)?.cgImage else { return nil }
        return await Task.detached(priority: .utility) { () -> String? in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return nil
            }
            let lines = (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            let text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }.value
    }
}

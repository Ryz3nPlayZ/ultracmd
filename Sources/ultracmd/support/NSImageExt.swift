import AppKit
import Foundation

extension NSImage {
    /// PNG encoding via TIFF → bitmap rep.
    func pngData() -> Data? {
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { return nil }
        return data
    }

    /// Pixel dimensions (independent of DPI scaling).
    var pixelSize: (width: Int, height: Int) {
        if let rep = representations.compactMap({ $0 as? NSBitmapImageRep }).first {
            return (rep.pixelsWide, rep.pixelsHigh)
        }
        let s = size
        return (Int(s.width), Int(s.height))
    }
}

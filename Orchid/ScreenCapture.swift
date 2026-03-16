import CoreGraphics
import Foundation
import ImageIO

enum ScreenCapture {
    /// Captures the given rect in Quartz (bottom-left origin) screen coordinates.
    static func capture(rect: CGRect) -> CGImage? {
        CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        )
    }

    /// Saves a CGImage as PNG to the given URL. Returns true on success.
    static func save(image: CGImage, to url: URL) -> Bool {
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) else { return false }

        CGImageDestinationAddImage(dest, image, nil)
        return CGImageDestinationFinalize(dest)
    }
}

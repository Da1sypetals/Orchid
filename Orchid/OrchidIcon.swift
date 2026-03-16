import AppKit

/// Renders the Orchid SVG logo as an NSImage of any size.
/// SVG viewBox is 400×400; we scale all coordinates proportionally.
enum OrchidIcon {
    static func image(size: CGFloat = 18) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.isTemplate = false
        img.lockFocus()
        draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        img.unlockFocus()
        return img
    }

    private static func draw(in rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let s = rect.width / 400.0   // uniform scale from SVG 400×400

        // SVG Y is top-down; AppKit Y is bottom-up.
        // Flip the CTM so we can use raw SVG coordinates directly.
        ctx.saveGState()
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: s, y: -s)

        // Detect dark mode — use a tinted fill in dark, the original purple in light
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let fill = isDark
            ? NSColor(red: 0xed/255, green: 0x8e/255, blue: 0xa9/255, alpha: 1)  // accent pink
            : NSColor(red: 0xC9/255, green: 0xB8/255, blue: 0xE8/255, alpha: 1)  // original lavender

        fill.setFill()

        // Petal 1 (top)
        // M 200 200 C 175.96 164.64 79.79 129.29 109.84 93.93
        //           C 159.63 35.36 240.37 35.36 290.16 93.93
        //           C 320.21 129.29 224.04 164.64 200 200 Z
        let p1 = NSBezierPath()
        p1.move(to: NSPoint(x: 200, y: 200))
        p1.curve(to: NSPoint(x: 109.84, y: 93.93),
                 controlPoint1: NSPoint(x: 175.96, y: 164.64),
                 controlPoint2: NSPoint(x: 79.79,  y: 129.29))
        p1.curve(to: NSPoint(x: 290.16, y: 93.93),
                 controlPoint1: NSPoint(x: 159.63, y: 35.36),
                 controlPoint2: NSPoint(x: 240.37, y: 35.36))
        p1.curve(to: NSPoint(x: 200, y: 200),
                 controlPoint1: NSPoint(x: 320.21, y: 129.29),
                 controlPoint2: NSPoint(x: 224.04, y: 164.64))
        p1.close()
        p1.fill()

        // Petal 2 (bottom-right)
        // M 200 200 C 242.64 196.86 321.34 131.25 336.94 174.95
        //           C 362.77 247.36 322.40 317.28 246.78 331.12
        //           C 201.13 339.46 218.60 238.50 200 200 Z
        let p2 = NSBezierPath()
        p2.move(to: NSPoint(x: 200, y: 200))
        p2.curve(to: NSPoint(x: 336.94, y: 174.95),
                 controlPoint1: NSPoint(x: 242.64, y: 196.86),
                 controlPoint2: NSPoint(x: 321.34, y: 131.25))
        p2.curve(to: NSPoint(x: 246.78, y: 331.12),
                 controlPoint1: NSPoint(x: 362.77, y: 247.36),
                 controlPoint2: NSPoint(x: 322.40, y: 317.28))
        p2.curve(to: NSPoint(x: 200, y: 200),
                 controlPoint1: NSPoint(x: 201.13, y: 339.46),
                 controlPoint2: NSPoint(x: 218.60, y: 238.50))
        p2.close()
        p2.fill()

        // Petal 3 (bottom-left)
        // M 200 200 C 181.40 238.50 198.87 339.46 153.22 331.12
        //           C 77.60 317.28 37.23 247.36 63.06 174.95
        //           C 78.66 131.25 157.36 196.86 200 200 Z
        let p3 = NSBezierPath()
        p3.move(to: NSPoint(x: 200, y: 200))
        p3.curve(to: NSPoint(x: 153.22, y: 331.12),
                 controlPoint1: NSPoint(x: 181.40, y: 238.50),
                 controlPoint2: NSPoint(x: 198.87, y: 339.46))
        p3.curve(to: NSPoint(x: 63.06, y: 174.95),
                 controlPoint1: NSPoint(x: 77.60,  y: 317.28),
                 controlPoint2: NSPoint(x: 37.23,  y: 247.36))
        p3.curve(to: NSPoint(x: 200, y: 200),
                 controlPoint1: NSPoint(x: 78.66,  y: 131.25),
                 controlPoint2: NSPoint(x: 157.36, y: 196.86))
        p3.close()
        p3.fill()

        ctx.restoreGState()
    }
}

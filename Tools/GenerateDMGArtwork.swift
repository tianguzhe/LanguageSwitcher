import AppKit

@main
struct GenerateDMGArtwork {
    private static let canvas = NSSize(width: 720, height: 480)
    private static let ink = NSColor(srgbRed: 0.13, green: 0.16, blue: 0.23, alpha: 1)
    private static let secondary = NSColor(srgbRed: 0.39, green: 0.43, blue: 0.51, alpha: 1)
    private static let green = NSColor(srgbRed: 0.08, green: 0.49, blue: 0.39, alpha: 1)

    static func main() throws {
        guard CommandLine.arguments.count == 4 else {
            throw NSError(domain: "LanguageSwitcherArtwork", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Usage: GenerateArtwork <directory> <version> <icon>"])
        }
        guard let icon = NSImage(contentsOfFile: CommandLine.arguments[3]) else {
            throw NSError(domain: "LanguageSwitcherArtwork", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Cannot load app icon: \(CommandLine.arguments[3])"])
        }
        let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let representations = [1, 2].map {
            render(scale: $0, version: CommandLine.arguments[2], icon: icon)
        }
        let image = NSImage(size: canvas)
        representations.forEach { image.addRepresentation($0) }
        guard let tiff = image.tiffRepresentation,
              let preview = representations[1].representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try tiff.write(to: output.appendingPathComponent("background.tiff"))
        try preview.write(to: output.appendingPathComponent("background@2x.png"))
    }

    private static func text(_ value: String, rect: NSRect, size: CGFloat, weight: NSFont.Weight = .regular,
                             color: NSColor = ink, alignment: NSTextAlignment = .left) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        NSAttributedString(string: value, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]).draw(in: rect)
    }

    private static func render(scale: Int, version: String, icon: NSImage) -> NSBitmapImageRep {
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                                      pixelsWide: Int(canvas.width) * scale,
                                      pixelsHigh: Int(canvas.height) * scale,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB,
                                      bytesPerRow: 0, bitsPerPixel: 0)!
        bitmap.size = canvas
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        let context = NSGraphicsContext(bitmapImageRep: bitmap)!
        let cg = context.cgContext
        cg.translateBy(x: 0, y: canvas.height)
        cg.scaleBy(x: 1, y: -1)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)
        let bounds = NSRect(origin: .zero, size: canvas)
        NSGradient(colors: [
            NSColor(srgbRed: 0.975, green: 0.99, blue: 0.955, alpha: 1),
            NSColor(srgbRed: 0.91, green: 0.975, blue: 0.95, alpha: 1)
        ])!.draw(in: bounds, angle: -25)

        // Thin orbit lines echo the globe in the app's empty state.
        cg.saveGState()
        cg.clip(to: bounds)
        for offset in [0.0, 24.0, 48.0] {
            let orbit = NSBezierPath(ovalIn: NSRect(x: 560 - offset, y: -88 - offset,
                                                   width: 240 + offset * 2, height: 180 + offset * 2))
            NSColor(srgbRed: 0.18, green: 0.58, blue: 0.44, alpha: 0.07).setStroke()
            orbit.lineWidth = 1
            orbit.stroke()
        }
        cg.restoreGState()

        icon.draw(in: NSRect(x: 36, y: 30, width: 60, height: 60),
            from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        text("Language Switcher", rect: NSRect(x: 107, y: 40, width: 440, height: 35),
             size: 25, weight: .semibold)
        text("Choose how your apps speak.", rect: NSRect(x: 108, y: 76, width: 410, height: 22),
             size: 12, color: secondary)
        let pill = NSRect(x: 601, y: 46, width: 75, height: 27)
        NSColor.white.withAlphaComponent(0.8).setFill()
        NSBezierPath(roundedRect: pill, xRadius: 13.5, yRadius: 13.5).fill()
        text("v\(version)", rect: pill.offsetBy(dx: 0, dy: 6), size: 10, weight: .medium,
             color: green, alignment: .center)

        text("Drag LanguageSwitcher to Applications", rect: NSRect(x: 44, y: 135, width: 632, height: 24),
             size: 15, weight: .medium, alignment: .center)

        // Centres are shared with icon_locations in Tools/dmg-settings.py.
        for centerX in [190.0, 530.0] {
            let halo = NSBezierPath(ovalIn: NSRect(x: centerX - 79, y: 173, width: 158, height: 158))
            NSColor.white.withAlphaComponent(0.72).setFill()
            halo.fill()
            ink.withAlphaComponent(0.06).setStroke()
            halo.lineWidth = 1
            halo.stroke()
        }
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: 326, y: 252))
        arrow.line(to: NSPoint(x: 394, y: 252))
        arrow.move(to: NSPoint(x: 383, y: 241))
        arrow.line(to: NSPoint(x: 394, y: 252))
        arrow.line(to: NSPoint(x: 383, y: 263))
        arrow.lineWidth = 2.5
        arrow.lineCapStyle = .round
        arrow.lineJoinStyle = .round
        green.setStroke()
        arrow.stroke()
        text("Drag to install", rect: NSRect(x: 300, y: 280, width: 120, height: 20),
             size: 10, weight: .medium, color: secondary, alignment: .center)

        let divider = NSBezierPath()
        divider.move(to: NSPoint(x: 44, y: 379))
        divider.line(to: NSPoint(x: 676, y: 379))
        divider.lineWidth = 0.75
        ink.withAlphaComponent(0.09).setStroke()
        divider.stroke()
        text("Open LanguageSwitcher, then choose an app and a language.",
             rect: NSRect(x: 44, y: 403, width: 632, height: 24), size: 12,
             color: secondary, alignment: .center)
        text("macOS 14+   ·   Apple Silicon & Intel", rect: NSRect(x: 44, y: 444, width: 632, height: 20),
             size: 10, weight: .medium, color: secondary, alignment: .center)
        return bitmap
    }
}

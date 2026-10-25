import AppKit
import CoreText

// Two light language sheets on a mint porcelain tile. Each representation is
// rendered from vector artwork, with simpler edges at Finder's smallest sizes.
private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat,
                   _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
}

private func saved(_ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    draw()
}

private func rounded(_ rect: NSRect, _ radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

private func drawSheet(_ rect: NSRect, angle: CGFloat, text: String, small: Bool,
                       top: NSColor, bottom: NSColor, ink: NSColor) {
    saved {
        let transform = NSAffineTransform()
        transform.translateX(by: rect.midX, yBy: rect.midY)
        transform.rotate(byDegrees: angle)
        transform.translateX(by: -rect.midX, yBy: -rect.midY)
        transform.concat()
        let shape = rounded(rect, 72)
        saved {
            let shadow = NSShadow()
            shadow.shadowColor = color(0.12, 0.40, 0.32, 0.18)
            shadow.shadowBlurRadius = small ? 14 : 32
            shadow.shadowOffset = NSSize(width: 0, height: -14)
            shadow.set()
            bottom.setFill()
            shape.fill()
        }
        NSGradient(starting: top, ending: bottom)!.draw(in: shape, angle: -90)
        if !small {
            saved {
                shape.addClip()
                NSColor.white.withAlphaComponent(0.7).setStroke()
                rounded(rect.insetBy(dx: 2, dy: 2), 70).stroke()
            }
        }

        let font = text == "文"
            ? NSFont(name: "PingFangSC-Medium", size: 218) ?? .systemFont(ofSize: 218, weight: .medium)
            : .systemFont(ofSize: 240, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ink]
        let label = NSAttributedString(string: text, attributes: attributes)
        // Centre the actual glyph outlines, independent of different font ascenders.
        let line = CTLineCreateWithAttributedString(label)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let context = NSGraphicsContext.current!.cgContext
        context.textPosition = CGPoint(x: rect.midX - bounds.midX, y: rect.midY - bounds.midY + 4)
        CTLineDraw(line, context)
    }
}

private func drawArtwork(pixels: Int) {
    let small = pixels <= 32
    let tileRect = NSRect(x: 88, y: 88, width: 848, height: 848)
    let tile = rounded(tileRect, 190)
    saved {
        let shadow = NSShadow()
        shadow.shadowColor = color(0.20, 0.38, 0.31, 0.15)
        shadow.shadowBlurRadius = 22
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.set()
        color(0.88, 0.96, 0.92).setFill()
        tile.fill()
    }
    NSGradient(colors: [color(0.96, 0.99, 0.96), color(0.88, 0.97, 0.93), color(0.79, 0.92, 0.87)])!
        .draw(in: tile, angle: -65)
    if !small {
        saved {
            tile.addClip()
            NSGradient(colors: [color(0.99, 1, 0.84, 0.7), color(0.99, 1, 0.84, 0)])!
                .draw(fromCenter: NSPoint(x: 190, y: 870), radius: 0,
                      toCenter: NSPoint(x: 190, y: 870), radius: 650,
                      options: .drawsAfterEndingLocation)
            NSColor.white.withAlphaComponent(0.9).setStroke()
            rounded(tileRect.insetBy(dx: 2, dy: 2), 188).stroke()
        }
    }

    drawSheet(NSRect(x: 235, y: 414, width: 360, height: 382), angle: 9,
              text: "A", small: small, top: .white, bottom: color(0.96, 0.99, 0.98),
              ink: color(0.27, 0.59, 0.49))
    drawSheet(NSRect(x: 430, y: 245, width: 360, height: 382), angle: -9,
              text: "文", small: small, top: color(0.48, 0.84, 0.70), bottom: color(0.22, 0.68, 0.54),
              ink: .white)
}

private func pngData(pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                        isPlanar: false, colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }
    bitmap.size = NSSize(width: pixels, height: pixels)
    saved {
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        drawArtwork(pixels: pixels)
    }
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

let projectDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let iconDirectory = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    : projectDirectory.appendingPathComponent("LanguageSwitcher/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: iconDirectory, withIntermediateDirectories: true)
var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let filename = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try pngData(pixels: points * scale).write(to: iconDirectory.appendingPathComponent(filename))
        images.append(["filename": filename, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
        print("Created \(filename) (\(points * scale)px)")
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconDirectory.appendingPathComponent("Contents.json"))
print("AppIcon ready: \(iconDirectory.path)")

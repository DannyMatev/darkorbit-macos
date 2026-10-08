import AppKit
import Foundation

// Original geometric artwork. No game assets or third-party artwork are used.
let destination = URL(fileURLWithPath: CommandLine.arguments[1])
func bigEndianLength(_ length: Int) -> Data {
    var value = UInt32(length).bigEndian
    return withUnsafeBytes(of: &value) { Data($0) }
}
var entries = Data()
let sizes = [(16, 1, "icp4"), (16, 2, "ic11"), (32, 1, "icp5"), (32, 2, "ic12"),
             (128, 1, "ic07"), (128, 2, "ic13"), (256, 1, "ic08"), (256, 2, "ic14"),
             (512, 1, "ic09"), (512, 2, "ic10")]
for (points, scale, type) in sizes {
    let pixels = points * scale
    guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                        isPlanar: false, colorSpaceName: .deviceRGB,
                                        bytesPerRow: 0, bitsPerPixel: 0),
          let context = NSGraphicsContext(bitmapImageRep: bitmap) else { exit(1) }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let multiplier = CGFloat(pixels) / 1024
    context.cgContext.scaleBy(x: multiplier, y: multiplier)
    let background = NSBezierPath(roundedRect: NSRect(x: 72, y: 72, width: 880, height: 880), xRadius: 200, yRadius: 200)
    NSColor(calibratedRed: 0.055, green: 0.11, blue: 0.16, alpha: 1).setFill()
    background.fill()
    let orbit = NSBezierPath(ovalIn: NSRect(x: 198, y: 324, width: 628, height: 370))
    let transform = AffineTransform(translationByX: -512, byY: -512)
    orbit.transform(using: transform)
    var rotation = AffineTransform()
    rotation.rotate(byDegrees: 32)
    orbit.transform(using: rotation)
    orbit.transform(using: AffineTransform(translationByX: 512, byY: 512))
    NSColor(calibratedRed: 0.36, green: 0.79, blue: 0.83, alpha: 1).setStroke()
    orbit.lineWidth = 38
    orbit.stroke()
    NSColor(calibratedRed: 0.70, green: 0.94, blue: 0.93, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 392, y: 392, width: 240, height: 240)).fill()
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: 244, y: 279, width: 64, height: 64)).fill()
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
    entries.append(Data(type.utf8))
    entries.append(bigEndianLength(png.count + 8))
    entries.append(png)
}
var icon = Data("icns".utf8)
icon.append(bigEndianLength(entries.count + 8))
icon.append(entries)
try icon.write(to: destination)
guard NSImage(contentsOf: destination) != nil else { exit(1) }

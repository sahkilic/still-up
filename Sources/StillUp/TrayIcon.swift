import AppKit

enum TrayIcon {
    static func image(active: Bool) -> NSImage {
        let pixels = 32
        let bytesPerRow = pixels * 4
        var data = [UInt8](repeating: 0, count: pixels * bytesPerRow)
        let barAlpha: UInt8 = active ? 230 : 200
        fillRect(&data, pixels, 11, 8, 16, 3, barAlpha)
        fillRect(&data, pixels, 11, 15, 16, 3, barAlpha)
        fillRect(&data, pixels, 11, 22, 16, 3, barAlpha)
        fillCircle(&data, pixels, 6, 16, 3, active ? 255 : 110)

        let cfData = Data(data) as CFData
        guard let provider = CGDataProvider(data: cfData),
              let cg = CGImage(
                width: pixels,
                height: pixels,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              )
        else {
            return NSImage(size: NSSize(width: 16, height: 16))
        }
        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.addRepresentation(NSBitmapImageRep(cgImage: cg))
        image.isTemplate = true
        return image
    }

    private static func setPixel(_ data: inout [UInt8], _ width: Int, _ x: Int, _ y: Int, _ alpha: UInt8) {
        guard x >= 0, y >= 0, x < width, y < width else { return }
        let i = (y * width + x) * 4
        data[i] = 0
        data[i + 1] = 0
        data[i + 2] = 0
        data[i + 3] = max(data[i + 3], alpha)
    }

    private static func fillRect(_ data: inout [UInt8], _ width: Int, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ alpha: UInt8) {
        for py in y..<(y + h) {
            for px in x..<(x + w) {
                setPixel(&data, width, px, py, alpha)
            }
        }
    }

    private static func fillCircle(_ data: inout [UInt8], _ width: Int, _ cx: Int, _ cy: Int, _ radius: Int, _ alpha: UInt8) {
        let r2 = radius * radius
        for y in -radius...radius {
            for x in -radius...radius where x * x + y * y <= r2 {
                setPixel(&data, width, cx + x, cy + y, alpha)
            }
        }
    }
}

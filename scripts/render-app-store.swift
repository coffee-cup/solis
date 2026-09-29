import AppKit
import ImageIO
import UniformTypeIdentifiers

struct Configuration: Decodable {
    let locale: String
    let devices: [Device]
    let screens: [Screen]
}
struct Device: Decodable {
    let id: String
    let width: Int
    let height: Int
    let frame: String
}
struct Screen: Decodable {
    let id: String
    let headline: String
    let gradient: [String]
}

enum RenderError: Error {
    case invalid(String)
}

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

func color(_ hex: String) -> CGColor {
    let value = UInt32(hex, radix: 16)!
    return CGColor(colorSpace: srgb, components: [
        CGFloat((value >> 16) & 255) / 255,
        CGFloat((value >> 8) & 255) / 255,
        CGFloat(value & 255) / 255, 1
    ])!
}

func rounded(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

func loadImage(_ url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw RenderError.invalid("Cannot read \(url.path)")
    }
    return image
}

func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw RenderError.invalid("Cannot write \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw RenderError.invalid("PNG encoding failed: \(url.path)")
    }
}

func canvas(width: Int, height: Int) throws -> CGContext {
    // RGBX produces opaque RGB PNGs, as required by App Store Connect.
    guard let context = CGContext(data: nil, width: width, height: height,
                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                  space: srgb, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw RenderError.invalid("Could not allocate \(width) × \(height) canvas")
    }
    context.interpolationQuality = .high
    return context
}

func render(_ screenshot: CGImage, device: Device, screen: Screen) throws -> CGImage {
    guard screenshot.width == device.width, screenshot.height == device.height else {
        throw RenderError.invalid("\(device.id)/\(screen.id): expected \(device.width) × \(device.height), got \(screenshot.width) × \(screenshot.height)")
    }
    let context = try canvas(width: device.width, height: device.height)
    let w = CGFloat(device.width), h = CGFloat(device.height)
    let isPad = device.frame == "ipad"
    let gradient = CGGradient(colorsSpace: srgb, colors: screen.gradient.map(color) as CFArray,
                              locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: 0), options: [])

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let fontSize = w * (isPad ? 0.063 : 0.090)
    let title = NSAttributedString(string: screen.headline, attributes: [
        .font: NSFont.systemFont(ofSize: fontSize, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraph
    ])
    let titleHeight = title.boundingRect(with: CGSize(width: w * 0.9, height: h),
                                         options: [.usesLineFragmentOrigin, .usesFontLeading]).height
    title.draw(with: CGRect(x: w * 0.05, y: h - h * 0.067 - titleHeight, width: w * 0.9, height: titleHeight),
               options: [.usesLineFragmentOrigin, .usesFontLeading])
    NSGraphicsContext.restoreGraphicsState()

    let bezel = w * (isPad ? 0.017 : 0.014)
    let bodyHeight = h * 0.75
    let screenHeight = bodyHeight - 2 * bezel
    let screenWidth = screenHeight * w / h
    let bodyWidth = screenWidth + 2 * bezel
    let body = CGRect(x: (w - bodyWidth) / 2, y: h * 0.04, width: bodyWidth, height: bodyHeight)
    let display = body.insetBy(dx: bezel, dy: bezel)
    let screenRadius = screenWidth * (isPad ? 0.025 : 0.13)
    let outline = rounded(body, radius: screenRadius + bezel)

    context.saveGState()
    context.setShadow(offset: CGSize(width: w * 0.025, height: -h * 0.018), blur: w * 0.045,
                      color: CGColor(gray: 0, alpha: 0.32))
    context.addPath(outline)
    context.setFillColor(color("171719"))
    context.fillPath()
    context.restoreGState()

    // Thin metal edge and black bezel are vector geometry, so every export stays sharp.
    context.addPath(outline)
    context.setStrokeColor(color("414145"))
    context.setLineWidth(w * 0.0015)
    context.strokePath()
    context.addPath(rounded(body.insetBy(dx: w * 0.003, dy: w * 0.003), radius: screenRadius + bezel))
    context.setFillColor(color("080809"))
    context.fillPath()

    context.saveGState()
    context.addPath(rounded(display, radius: screenRadius))
    context.clip()
    context.draw(screenshot, in: display)
    context.restoreGState()

    if !isPad {
        // Simulator captures omit the hardware cutout. Coordinates use a 440-point display.
        let scale = screenWidth / 440
        let island = CGRect(x: display.midX - 63 * scale, y: display.maxY - 48 * scale,
                            width: 126 * scale, height: 37 * scale)
        context.setFillColor(color("000000"))
        context.addPath(rounded(island, radius: island.height / 2))
        context.fillPath()
        for (side, top, length) in [(false, 0.19, 0.045), (false, 0.255, 0.06), (false, 0.335, 0.06), (true, 0.27, 0.10)] {
            let button = CGRect(x: side ? body.maxX : body.minX - w * 0.003,
                                y: body.maxY - body.height * (top + length),
                                width: w * 0.003, height: body.height * length)
            context.addPath(rounded(button, radius: w * 0.0015))
            context.fillPath()
        }
    } else {
        context.setFillColor(color("292932"))
        let dot = bezel * 0.24
        context.fillEllipse(in: CGRect(x: body.maxX - bezel / 2 - dot / 2, y: body.midY - dot / 2,
                                      width: dot, height: dot))
    }
    return context.makeImage()!
}

do {
    guard CommandLine.arguments.count == 5 else {
        throw RenderError.invalid("Usage: render-app-store CONFIG RAW_DIRECTORY OUTPUT_DIRECTORY DEVICE_ID")
    }
    let config = try JSONDecoder().decode(Configuration.self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
    let raw = URL(fileURLWithPath: CommandLine.arguments[2])
    let output = URL(fileURLWithPath: CommandLine.arguments[3])
    guard let device = config.devices.first(where: { $0.id == CommandLine.arguments[4] }),
          ["iphone", "ipad"].contains(device.frame) else {
        throw RenderError.invalid("Unknown device or frame")
    }
    var images: [CGImage] = []
    for screen in config.screens {
        let screenshot = try loadImage(raw.appendingPathComponent("\(screen.id).png"))
        let result = try render(screenshot, device: device, screen: screen)
        try writePNG(result, to: output.appendingPathComponent("\(screen.id).png"))
        images.append(result)
    }
    let thumbWidth = 320
    let thumbHeight = Int(Double(thumbWidth) * Double(device.height) / Double(device.width))
    let gap = 16
    let sheet = try canvas(width: gap + images.count * (thumbWidth + gap), height: thumbHeight + gap * 2)
    sheet.setFillColor(color("F2F2F4"))
    sheet.fill(CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height))
    for (index, image) in images.enumerated() {
        sheet.draw(image, in: CGRect(x: gap + index * (thumbWidth + gap), y: gap, width: thumbWidth, height: thumbHeight))
    }
    try writePNG(sheet.makeImage()!, to: output.deletingLastPathComponent().appendingPathComponent("\(device.id)-contact-sheet.png"))
    print("Rendered \(images.count) screenshots for \(device.id)")
} catch {
    fputs("\(error)\n", stderr)
    exit(1)
}

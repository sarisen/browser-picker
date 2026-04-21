#!/usr/bin/env swift
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func drawIcon(size: Int) -> CGImage? {
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: size * 4,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let s = CGFloat(size)
    let r = s * 0.2  // corner radius

    // ── Background gradient ──────────────────────────────────────────────────
    let bgPath = CGMutablePath()
    bgPath.addRoundedRect(in: CGRect(x: 0, y: 0, width: s, height: s),
                          cornerWidth: r, cornerHeight: r)
    ctx.addPath(bgPath)
    ctx.clip()

    let top    = CGColor(red: 0.18, green: 0.44, blue: 0.96, alpha: 1)   // bright blue
    let bottom = CGColor(red: 0.07, green: 0.18, blue: 0.60, alpha: 1)   // deep navy
    if let grad = CGGradient(
        colorsSpace: cs,
        colors: [top, bottom] as CFArray,
        locations: [0, 1]
    ) {
        ctx.drawLinearGradient(grad,
            start: CGPoint(x: s * 0.2, y: s),
            end:   CGPoint(x: s * 0.8, y: 0),
            options: [])
    }
    ctx.resetClip()

    // ── Geometry ─────────────────────────────────────────────────────────────
    let nodeR  = s * 0.075         // circle radius
    let lx     = s * 0.20          // left input node x
    let cx     = s * 0.42          // branch point x
    let cy     = s * 0.50          // center y
    let rx     = s * 0.82          // right output nodes x
    let lw     = s * 0.065         // line width

    // Output y positions (top → bottom)
    let ys: [CGFloat] = [cy + s * 0.27, cy, cy - s * 0.27]

    // Output branch colors
    let colors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = [
        (0.28, 0.78, 0.48),   // green
        (1.00, 0.72, 0.10),   // amber
        (0.36, 0.68, 1.00),   // sky blue
    ]

    // ── Stem: input node → branch point ──────────────────────────────────────
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(lw)
    ctx.setLineCap(.round)
    ctx.move(to:    CGPoint(x: lx + nodeR, y: cy))
    ctx.addLine(to: CGPoint(x: cx, y: cy))
    ctx.strokePath()

    // ── Input dot ─────────────────────────────────────────────────────────────
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.fillEllipse(in: CGRect(x: lx - nodeR, y: cy - nodeR,
                               width: nodeR * 2, height: nodeR * 2))

    // ── Branches ─────────────────────────────────────────────────────────────
    for (i, by) in ys.enumerated() {
        let c = colors[i]
        let cg = CGColor(red: c.r, green: c.g, blue: c.b, alpha: 0.95)

        ctx.setStrokeColor(cg)
        ctx.setLineWidth(lw)

        // Curved branch
        let cp1 = CGPoint(x: cx + s * 0.12, y: cy)
        let cp2 = CGPoint(x: rx - s * 0.12, y: by)
        ctx.move(to: CGPoint(x: cx, y: cy))
        ctx.addCurve(to: CGPoint(x: rx, y: by), control1: cp1, control2: cp2)
        ctx.strokePath()

        // Output dot
        ctx.setFillColor(cg)
        ctx.fillEllipse(in: CGRect(x: rx - nodeR, y: by - nodeR,
                                   width: nodeR * 2, height: nodeR * 2))
    }

    return ctx.makeImage()
}

func save(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil) else {
        print("✗ Cannot create destination for \(path)"); return
    }
    CGImageDestinationAddImage(dest, image, nil)
    if CGImageDestinationFinalize(dest) {
        print("✓ \(path)")
    } else {
        print("✗ Failed to write \(path)")
    }
}

// ── Generate all required macOS icon sizes ──────────────────────────────────

let iconDir = "BrowserPicker/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: iconDir,
                                          withIntermediateDirectories: true)

let sizes: [(name: String, px: Int)] = [
    ("icon_16x16",      16),
    ("icon_16x16@2x",   32),
    ("icon_32x32",      32),
    ("icon_32x32@2x",   64),
    ("icon_128x128",    128),
    ("icon_128x128@2x", 256),
    ("icon_256x256",    256),
    ("icon_256x256@2x", 512),
    ("icon_512x512",    512),
    ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    guard let img = drawIcon(size: px) else { print("✗ draw failed for \(px)"); continue }
    save(img, to: "\(iconDir)/\(name).png")
}

// ── Contents.json ─────────────────────────────────────────────────────────────

let json = """
{
  "images" : [
    {"size":"16x16",   "idiom":"mac","filename":"icon_16x16.png",      "scale":"1x"},
    {"size":"16x16",   "idiom":"mac","filename":"icon_16x16@2x.png",   "scale":"2x"},
    {"size":"32x32",   "idiom":"mac","filename":"icon_32x32.png",      "scale":"1x"},
    {"size":"32x32",   "idiom":"mac","filename":"icon_32x32@2x.png",   "scale":"2x"},
    {"size":"128x128", "idiom":"mac","filename":"icon_128x128.png",    "scale":"1x"},
    {"size":"128x128", "idiom":"mac","filename":"icon_128x128@2x.png", "scale":"2x"},
    {"size":"256x256", "idiom":"mac","filename":"icon_256x256.png",    "scale":"1x"},
    {"size":"256x256", "idiom":"mac","filename":"icon_256x256@2x.png", "scale":"2x"},
    {"size":"512x512", "idiom":"mac","filename":"icon_512x512.png",    "scale":"1x"},
    {"size":"512x512", "idiom":"mac","filename":"icon_512x512@2x.png", "scale":"2x"}
  ],
  "info" : {"author":"xcode","version":1}
}
"""
try! json.write(toFile: "\(iconDir)/Contents.json", atomically: true, encoding: .utf8)
print("✓ Contents.json")
print("Done.")

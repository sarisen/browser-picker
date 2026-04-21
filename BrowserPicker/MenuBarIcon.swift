import AppKit

enum MenuBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { bounds in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let s = bounds.width

            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.setStrokeColor(NSColor.labelColor.cgColor)

            let lx: CGFloat = s * 0.14   // left (input)
            let cx: CGFloat = s * 0.44   // branch point
            let rx: CGFloat = s * 0.86   // right (outputs)
            let cy: CGFloat = s * 0.50
            let dotR: CGFloat = s * 0.085

            // Stem
            ctx.setLineWidth(s * 0.10)
            ctx.move(to:    CGPoint(x: lx + dotR, y: cy))
            ctx.addLine(to: CGPoint(x: cx, y: cy))
            ctx.strokePath()

            // Input dot
            ctx.setFillColor(NSColor.labelColor.cgColor)
            ctx.fillEllipse(in: CGRect(x: lx - dotR, y: cy - dotR,
                                       width: dotR * 2, height: dotR * 2))

            // Three branches (equal spacing)
            let offsets: [CGFloat] = [s * 0.30, 0, -s * 0.30]
            ctx.setLineWidth(s * 0.085)

            for dy in offsets {
                let by = cy + dy
                ctx.move(to: CGPoint(x: cx, y: cy))
                ctx.addCurve(
                    to:       CGPoint(x: rx, y: by),
                    control1: CGPoint(x: cx + s * 0.12, y: cy),
                    control2: CGPoint(x: rx - s * 0.12, y: by)
                )
                ctx.strokePath()

                // Output dot
                ctx.fillEllipse(in: CGRect(x: rx - dotR, y: by - dotR,
                                           width: dotR * 2, height: dotR * 2))
            }

            return true
        }
        image.isTemplate = true
        return image
    }
}

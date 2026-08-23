//
//  GuitarHeadstockView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 1.08.2026.
//

import SwiftUI

/// A stylized guitar headstock, viewed from the front — the side where the
/// strings actually run: each string starts at its tuning peg, converges at
/// the nut, then continues down along the neck in correct fretboard order
/// (low E far left, high E far right), the same way it crosses on a real
/// headstock. Purely illustrative/reactive; the pegs aren't tappable — the
/// mic already tells you which string you're on.
struct GuitarHeadstockView: View {
    let activeString: GuitarString?
    let statusColor: Color
    var lockedStrings: Set<GuitarString> = []

    var scale: CGFloat = 1

    private var canvasSize: CGSize { CGSize(width: 350 * scale, height: 378 * scale) }
    private var headstockRect: CGRect { CGRect(x: 101 * scale, y: 14 * scale, width: 148 * scale, height: 215 * scale) }
    private var neckWidth: CGFloat { 86 * scale }
    private var pegRowYs: [CGFloat] { [52, 113, 176].map { $0 * scale } }
    private let fretboardOrder: [GuitarString] = [.e2, .a2, .d3, .g3, .b3, .e4]

    private var nutPoint: CGPoint { CGPoint(x: headstockRect.midX, y: headstockRect.maxY) }


    private func isHighlighted(_ string: GuitarString) -> Bool {
        string == activeString || lockedStrings.contains(string)
    }

    private func highlightColor(for string: GuitarString) -> Color {
        lockedStrings.contains(string) ? .green : statusColor
    }

    private var neckRect: CGRect {
        CGRect(
            x: headstockRect.midX - neckWidth / 2, y: headstockRect.maxY,
            width: neckWidth, height: canvasSize.height - headstockRect.maxY
        )
    }

    /// Each string's x once it's past the nut, in correct fretboard order
    /// (low E far left, high E far right) — independent of which side its
    /// tuning peg is on.
    private func fretboardX(for string: GuitarString) -> CGFloat {
        let index = fretboardOrder.firstIndex(of: string) ?? 0
        let spacing: CGFloat = 15 * scale
        let span = spacing * CGFloat(fretboardOrder.count - 1)
        return headstockRect.midX - span / 2 + CGFloat(index) * spacing
    }

    /// The headstock tapers narrower toward the top (see `HeadstockShape`),
    /// so the wood's actual left/right edge at a given row sits further in
    /// than `headstockRect.minX/maxX` — most noticeably for the top row.
    /// Approximates the shape's taper linearly to find where the wood
    /// really is at that row, so posts/knobs don't float past it.
    private func edgeInset(forRow row: Int) -> CGFloat {
        let t = (pegRowYs[row] - headstockRect.minY) / headstockRect.height
        let topInset = headstockRect.width * 0.24
        return topInset * (1 - t)
    }

    private func trueEdgeX(isLeft: Bool, row: Int) -> CGFloat {
        let inset = edgeInset(forRow: row)
        return isLeft ? headstockRect.minX + inset : headstockRect.maxX - inset
    }

    /// Where the string actually threads through the wood — inset just
    /// inside the headstock's real (tapered) edge, not floating beside it.
    private func pegAnchor(isLeft: Bool, row: Int) -> CGPoint {
        let edge = trueEdgeX(isLeft: isLeft, row: row)
        let offset = 11 * scale
        return CGPoint(x: isLeft ? edge + offset : edge - offset, y: pegRowYs[row])
    }

    private func pegButtonCenter(isLeft: Bool, row: Int) -> CGPoint {
        let edge = trueEdgeX(isLeft: isLeft, row: row)
        let offset = 27 * scale
        return CGPoint(x: isLeft ? edge - offset : edge + offset, y: pegRowYs[row])
    }

    var body: some View {
        ZStack {
            // Neck, headstock, and strings all drawn in one Canvas pass so
            // their coordinates share one unambiguous space and the draw
            // order is exact: neck, then headstock wood, then the strings
            // laid across both — on a real front-view headstock the strings
            // are visible against the wood, not hidden underneath it.
            Canvas { context, _ in
                drawNeck(in: &context)
                drawHeadstock(in: &context)
                for (string, isLeft, row) in pegLayout {
                    drawString(string, isLeft: isLeft, row: row, in: &context)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)

            ForEach(pegLayout, id: \.0.id) { string, isLeft, row in
                pegStem(isLeft: isLeft, row: row, string: string)
                pegPost(string: string)
                    .position(pegAnchor(isLeft: isLeft, row: row))
                pegButton(for: string, isLeft: isLeft)
                    .position(pegButtonCenter(isLeft: isLeft, row: row))
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
    }

    private var pegLayout: [(GuitarString, Bool, Int)] {
        GuitarString.leftPegs.enumerated().map { ($1, true, $0) }
            + GuitarString.rightPegs.enumerated().map { ($1, false, $0) }
    }

    private func drawString(_ string: GuitarString, isLeft: Bool, row: Int, in context: inout GraphicsContext) {
        let anchor = pegAnchor(isLeft: isLeft, row: row)
        let x = fretboardX(for: string)
        let isActive = isHighlighted(string)

        var path = Path()
        path.move(to: anchor)
        path.addLine(to: CGPoint(x: x, y: nutPoint.y))
        path.addLine(to: CGPoint(x: x, y: canvasSize.height))

        context.stroke(
            path,
            with: .color(isActive ? highlightColor(for: string) : Color.akorioNeutral400.opacity(0.8)),
            lineWidth: isActive ? 2 : 1.2
        )
    }

    /// The fretboard the strings run along below the nut — without it the
    /// strings just float in empty space.
    private func drawNeck(in context: inout GraphicsContext) {
        let gradient = Gradient(colors: [Color.akorioAccent900, Color.akorioSurface])
        context.fill(
            Path(neckRect),
            with: .linearGradient(gradient, startPoint: CGPoint(x: neckRect.midX, y: neckRect.minY), endPoint: CGPoint(x: neckRect.midX, y: neckRect.maxY))
        )

        let fretCount = 3
        for i in 1...fretCount {
            let y = neckRect.minY + neckRect.height * CGFloat(i) / CGFloat(fretCount + 1)
            var fret = Path()
            fret.move(to: CGPoint(x: neckRect.minX, y: y))
            fret.addLine(to: CGPoint(x: neckRect.maxX, y: y))
            context.stroke(fret, with: .color(.akorioDivider), lineWidth: 1)
        }
    }

    private func drawHeadstock(in context: inout GraphicsContext) {
        let shape = HeadstockShape(rect: headstockRect).path(in: headstockRect)
        let gradient = Gradient(colors: [Color.akorioAccent900, Color.akorioSurface])
        context.fill(
            shape,
            with: .linearGradient(gradient, startPoint: CGPoint(x: headstockRect.midX, y: headstockRect.minY), endPoint: CGPoint(x: headstockRect.midX, y: headstockRect.maxY))
        )
        context.stroke(shape, with: .color(.akorioDivider), lineWidth: 1.5)
    }

    /// The metal grommet where the string actually threads through, right at
    /// the headstock edge — separate from the tuning knob itself.
    private func pegPost(string: GuitarString) -> some View {
        let isActive = isHighlighted(string)
        let color = highlightColor(for: string)

        return ZStack {
            if isActive {
                Circle()
                    .fill(color.opacity(0.55))
                    .frame(width: 30 * scale, height: 30 * scale)
                    .blur(radius: 10)
            }

            Circle()
                .fill(isActive ? color : Color.akorioNeutral400)
                .frame(width: 16 * scale, height: 16 * scale)
                .overlay(Circle().stroke(Color.akorioBg, lineWidth: 1.5))
        }
        .akorioAnimation(.spring(response: 0.25, dampingFraction: 1.0), value: isActive)
    }

    /// The shaft connecting the post to the tuning knob.
    private func pegStem(isLeft: Bool, row: Int, string: GuitarString) -> some View {
        let anchor = pegAnchor(isLeft: isLeft, row: row)
        let knob = pegButtonCenter(isLeft: isLeft, row: row)
        return Rectangle()
            .fill(isHighlighted(string) ? highlightColor(for: string) : Color.akorioNeutral500)
            .frame(width: max(0, abs(knob.x - anchor.x) - 12 * scale), height: 5 * scale)
            .position(x: (anchor.x + knob.x) / 2, y: anchor.y)
    }

    /// The tuning knob itself — a mushroom/teardrop lying on its side: a
    /// round bulb tapering to a point that meets the post, the way a real
    /// tuning machine button looks from this angle.
    private func pegButton(for string: GuitarString, isLeft: Bool) -> some View {
        let isActive = isHighlighted(string)
        let color = highlightColor(for: string)
        let width: CGFloat = 73 * scale
        let height: CGFloat = 43 * scale
        // Left pegs point right (toward the headstock); right pegs point left.
        let pointsRight = isLeft
        let textOffset = pointsRight ? -(width / 2 - height / 2) : (width / 2 - height / 2)

        return ZStack {
            TuningKnobShape(pointsRight: pointsRight)
                .fill(isActive ? color : Color.akorioSurface)
            TuningKnobShape(pointsRight: pointsRight)
                .stroke(isActive ? Color.clear : Color.akorioDivider, lineWidth: 1.5)

            HStack(spacing: 2 * scale) {
                Text(string.noteName)
                    .font(.akorioFixed(23 * scale, .bold))
                Text("\(string.octave)")
                    .font(.akorioFixed(13 * scale, .medium))
                    .opacity(0.7)
            }
            .foregroundColor(isActive ? .white : .akorioNeutral300)
            .offset(x: textOffset)
        }
        .frame(width: width, height: height)
        .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: 8)
        .akorioAnimation(.spring(response: 0.25, dampingFraction: 1.0), value: isActive)
    }
}

/// A mushroom/teardrop knob silhouette: a round bulb tapering to a point,
/// like the classic "butterbean" tuning machine button viewed side-on.
/// `pointsRight` puts the point (and bulb) on opposite ends so the same
/// shape can face either direction without mirrored, unreadable text.
private struct TuningKnobShape: Shape {
    let pointsRight: Bool

    func path(in rect: CGRect) -> Path {
        let r = rect.height / 2
        let bulbX = pointsRight ? rect.minX + r : rect.maxX - r
        let backX = pointsRight ? rect.minX : rect.maxX
        let tipX = pointsRight ? rect.maxX : rect.minX
        let midY = rect.midY
        let neckY = r * 0.45
        let neckCtrlX = pointsRight ? bulbX + r * 0.6 : bulbX - r * 0.6

        var path = Path()
        path.move(to: CGPoint(x: tipX, y: midY))
        path.addQuadCurve(to: CGPoint(x: bulbX, y: midY - r), control: CGPoint(x: neckCtrlX, y: midY - neckY))
        path.addQuadCurve(to: CGPoint(x: backX, y: midY), control: CGPoint(x: backX, y: midY - r))
        path.addQuadCurve(to: CGPoint(x: bulbX, y: midY + r), control: CGPoint(x: backX, y: midY + r))
        path.addQuadCurve(to: CGPoint(x: tipX, y: midY), control: CGPoint(x: neckCtrlX, y: midY + neckY))
        path.closeSubpath()
        return path
    }
}

/// Tapered, rounded silhouette — narrower at the nut (top), wider at the
/// base where the neck continues. Takes an explicit `rect` (ignoring the one
/// SwiftUI would normally pass to `path(in:)`) so `drawHeadstock` can call
/// `.path(in:)` directly inside the parent `Canvas` and get a path in the
/// same absolute coordinates the neck and strings are drawn in.
private struct HeadstockShape: Shape {
    let rect: CGRect

    func path(in _: CGRect) -> Path {
        let topInset = rect.width * 0.24

        let topRadius: CGFloat = rect.width * (24.0 / 148.0)
        let bottomRadius: CGFloat = rect.width * (13.0 / 148.0)

        let tl = CGPoint(x: rect.minX + topInset, y: rect.minY)
        let tr = CGPoint(x: rect.maxX - topInset, y: rect.minY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)

        var path = Path()
        path.move(to: CGPoint(x: bl.x, y: bl.y - bottomRadius))
        path.addLine(to: CGPoint(x: tl.x - topRadius * 0.4, y: tl.y + topRadius))
        path.addQuadCurve(to: CGPoint(x: tl.x + topRadius, y: tl.y), control: tl)
        path.addLine(to: CGPoint(x: tr.x - topRadius, y: tr.y))
        path.addQuadCurve(to: CGPoint(x: tr.x + topRadius * 0.4, y: tr.y + topRadius), control: tr)
        path.addLine(to: CGPoint(x: br.x, y: br.y - bottomRadius))
        path.addQuadCurve(to: CGPoint(x: br.x - bottomRadius, y: br.y), control: br)
        path.addLine(to: CGPoint(x: bl.x + bottomRadius, y: bl.y))
        path.addQuadCurve(to: CGPoint(x: bl.x, y: bl.y - bottomRadius), control: bl)
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        GuitarHeadstockView(activeString: .a2, statusColor: .akorioAccent400)
    }
}

//
//  TunerGaugeView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 5.08.2026.
//

import SwiftUI

/// A single analog-style gauge that replaces the old note-badge-circle +
/// chromatic-strip pair: one semicircular arc with a needle sweeping across
/// it for flat/sharp. The note name itself lives outside this view (shown
/// once, between the gauge and the guitar) rather than on a plate here.
struct TunerGaugeView: View {
    let pitch: NotePitch?
    let isInTune: Bool
    let statusColor: Color
    var scale: CGFloat = 1

    private var radius: CGFloat { 120 * scale }
    private let strokeWidth: CGFloat = 6
    private var canvasSize: CGSize { CGSize(width: radius * 2 + 80 * scale, height: radius + 8 * scale) }
    /// Sits exactly at the frame's bottom-center — lets the needle pivot via
    /// plain `ZStack(alignment: .bottom)` + `rotationEffect(anchor: .bottom)`
    /// instead of juggling manual offsets to fake a rotation origin.
    private var pivot: CGPoint { CGPoint(x: canvasSize.width / 2, y: canvasSize.height) }

    private var clampedCents: Double { max(-50, min(50, pitch?.cents ?? 0)) }
    /// -90° = straight up (0 cents), sweeping to -180° (-50, previous note
    /// edge) and 0° (+50, next note edge).
    private var needleAngle: Double { -90 + (clampedCents / 50) * 90 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(statusColor.opacity(isInTune ? 0.3 : 0.1))
                .frame(width: radius * 1.5, height: radius * 1.5)
                .blur(radius: 46)
                .opacity(pitch == nil ? 0 : 1)
                .position(x: pivot.x, y: pivot.y - radius * 0.35)

            Canvas { context, _ in
                drawTrack(in: &context)
                drawTicks(in: &context)
            }
            .frame(width: canvasSize.width, height: canvasSize.height)

            edgeLabel(pitch?.previousNoteName, atAngle: 180)
            edgeLabel(pitch?.nextNoteName, atAngle: 0)

            needle
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .akorioAnimation(.spring(response: 0.25, dampingFraction: 0.75), value: clampedCents)
        .akorioAnimation(.spring(response: 0.25, dampingFraction: 1.0), value: isInTune)
    }

    private func point(atAngleDegrees angle: Double, radius r: CGFloat) -> CGPoint {
        let radians: Double = angle * Double.pi / 180
        let dx: Double = Double(r) * cos(radians)
        let dy: Double = Double(r) * sin(radians)
        return CGPoint(x: pivot.x + CGFloat(dx), y: pivot.y + CGFloat(dy))
    }

    private func drawTrack(in context: inout GraphicsContext) {
        var path = Path()
        path.addArc(center: pivot, radius: radius, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        context.stroke(path, with: .color(.akorioSurface), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
    }

    /// Ticks every 12.5 cents; the center one (0 cents, perfectly in tune)
    /// is taller and picks up `statusColor` so it doubles as the target
    /// marker the needle is aiming for.
    private func drawTicks(in context: inout GraphicsContext) {
        for cents in stride(from: -50.0, through: 50.0, by: 12.5) {
            let angle = -90 + (cents / 50) * 90
            let isCenter = abs(cents) < 0.01
            let inner = point(atAngleDegrees: angle, radius: radius - (isCenter ? 16 : 10))
            let outer = point(atAngleDegrees: angle, radius: radius + 3)

            var path = Path()
            path.move(to: inner)
            path.addLine(to: outer)
            context.stroke(
                path,
                with: .color(isCenter ? statusColor : Color.akorioNeutral500),
                style: StrokeStyle(lineWidth: isCenter ? 3 : 1.5, lineCap: .round)
            )
        }
    }

    /// The chromatic neighbor names anchoring the arc's two ends — "what
    /// note am I drifting toward" at a glance, same job the old strip did.
    private func edgeLabel(_ text: String?, atAngle angle: Double) -> some View {
        let position = point(atAngleDegrees: angle, radius: radius + 24)
        return Text(text ?? "–")
            .font(.akorioFixed(14, .medium))
            .foregroundColor(.akorioNeutral500)
            .position(position)
    }

    private var needle: some View {
        ZStack(alignment: .bottom) {
            Capsule()
                .fill(LinearGradient(colors: [statusColor.opacity(0.25), statusColor], startPoint: .bottom, endPoint: .top))
                .frame(width: 5, height: max(0, radius - 34))
                .shadow(color: isInTune ? statusColor.opacity(0.8) : .clear, radius: 8)
                .opacity(pitch == nil ? 0.25 : 1)
                .rotationEffect(.degrees(needleAngle + 90), anchor: .bottom)

            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
    }

}

#Preview {
    ZStack {
        AkorioBackground()
        TunerGaugeView(pitch: NotePitch(frequency: 87.0), isInTune: false, statusColor: .akorioAccent400)
            .padding(.top, 40)
    }
}

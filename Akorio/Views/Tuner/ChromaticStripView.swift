//
//  ChromaticStripView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 1.08.2026.
//

import SwiftUI

/// Shows the current note flanked by its chromatic neighbors (e.g. D# – E –
/// F), with a needle sliding continuously between them based on `cents`.
/// Answers "am I drifting toward D# or toward F?" — not just "how far off
/// am I" — which a single centered meter can't show.
struct ChromaticStripView: View {
    let pitch: NotePitch?
    let isInTune: Bool
    let statusColor: Color

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Text(pitch?.previousNoteName ?? "–")
                    .frame(maxWidth: .infinity)
                Text(pitch?.noteName ?? "–")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.akorioText)
                    .frame(maxWidth: .infinity)
                Text(pitch?.nextNoteName ?? "–")
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.akorioNeutral500)

            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.akorioSurface)
                    .frame(height: 6)

                Rectangle()
                    .fill(Color.akorioDivider)
                    .frame(width: 2, height: 18)

                GeometryReader { proxy in
                    let cents = pitch?.cents ?? 0
                    let clamped = max(-50, min(50, cents))
                    let x = proxy.size.width / 2 + (clamped / 50) * (proxy.size.width / 2)

                    Capsule()
                        .fill(statusColor)
                        .frame(width: 6, height: 26)
                        .shadow(color: isInTune ? statusColor.opacity(0.8) : .clear, radius: 8)
                        .position(x: x, y: proxy.size.height / 2)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: cents)
                }
                .frame(height: 26)
                .opacity(pitch == nil ? 0 : 1)
            }
            .frame(height: 26)
        }
        .frame(maxWidth: 280)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        ChromaticStripView(
            pitch: NotePitch(frequency: 87.0),
            isInTune: false,
            statusColor: .akorioAccent400
        )
        .padding(40)
    }
}

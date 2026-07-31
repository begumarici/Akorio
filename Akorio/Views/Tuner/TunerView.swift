//
//  TunerView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import SwiftUI

struct TunerView: View {
    let viewModel: AppViewModel
    @State private var engine = TunerEngine()

    private var isInTune: Bool {
        guard let cents = engine.currentPitch?.cents else { return false }
        return abs(cents) < 5
    }

    private var statusColor: Color {
        guard engine.currentPitch != nil else { return .akorioNeutral700 }
        return isInTune ? .green : .akorioAccent400
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Spacer()

            switch engine.permissionState {
            case .denied:
                permissionDeniedContent
            default:
                tunerContent
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear { engine.start() }
        .onDisappear { engine.stop() }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(AkorioIconButtonStyle())

            VStack(alignment: .leading, spacing: 1) {
                Text("Akort Aleti")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.akorioText)
                Text("Standart Akort · 440Hz")
                    .font(.system(size: 12))
                    .foregroundColor(.akorioNeutral500)
            }

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Main content
    private var tunerContent: some View {
        VStack(spacing: 36) {
            noteBadge
            meter
        }
    }

    // MARK: - Note badge
    private var noteBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [statusColor.opacity(0.22), Color.clear],
                        center: .center, startRadius: 10, endRadius: 130
                    )
                )
                .frame(width: 240, height: 240)
                .animation(.easeOut(duration: 0.25), value: isInTune)

            Circle()
                .fill(Color.akorioSurface)
                .frame(width: 180, height: 180)

            Circle()
                .stroke(statusColor, lineWidth: 3)
                .frame(width: 180, height: 180)
                .shadow(color: isInTune ? statusColor.opacity(0.7) : .clear, radius: 14)
                .animation(.easeOut(duration: 0.25), value: statusColor)

            VStack(spacing: 2) {
                HStack(alignment: .top, spacing: 2) {
                    Text(engine.currentPitch?.noteName ?? "–")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.akorioText)
                        .contentTransition(.numericText())

                    if let octave = engine.currentPitch?.octave {
                        Text("\(octave)")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.akorioNeutral400)
                            .padding(.top, 10)
                    }
                }
                .animation(.easeOut(duration: 0.15), value: engine.currentPitch?.noteName)

                Text(engine.currentPitch.map { String(format: "%.1f Hz", $0.frequency) } ?? "Bir tele çal")
                    .font(.system(size: 12))
                    .foregroundColor(.akorioNeutral500)
            }
        }
    }

    /// -50...50 cent meter. Center = in tune; a ±5 cent dead zone reads as
    /// "close enough" so the indicator isn't hunting on every tiny wobble.
    private var meter: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.akorioSurface)
                    .frame(height: 8)

                HStack(spacing: 0) {
                    ForEach([-40, -20, 0, 20, 40], id: \.self) { tick in
                        if tick != -40 { Spacer() }
                        Rectangle()
                            .fill(Color.akorioDivider)
                            .frame(width: tick == 0 ? 2 : 1, height: tick == 0 ? 16 : 10)
                    }
                }

                GeometryReader { proxy in
                    let cents = engine.currentPitch?.cents ?? 0
                    let clamped = max(-50, min(50, cents))
                    let x = proxy.size.width / 2 + (clamped / 50) * (proxy.size.width / 2)

                    Capsule()
                        .fill(statusColor)
                        .frame(width: 6, height: 30)
                        .shadow(color: isInTune ? statusColor.opacity(0.8) : .clear, radius: 8)
                        .position(x: x, y: proxy.size.height / 2)
                        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: cents)
                }
                .frame(height: 30)
            }
            .frame(height: 30)
            .frame(maxWidth: 260)

            HStack {
                Text("PES")
                Spacer()
                statusLabel
                Spacer()
                Text("TİZ")
            }
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral600)
            .frame(maxWidth: 260)
        }
    }

    private var statusLabel: some View {
        Group {
            if let cents = engine.currentPitch?.cents {
                Text(isInTune ? "TAM" : (cents < 0 ? "PESLEŞTİR" : "SIKILAŞTIR"))
                    .foregroundColor(isInTune ? .green : .akorioNeutral500)
            } else {
                Text("—")
            }
        }
    }

    // MARK: - Permission denied
    private var permissionDeniedContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 32))
                .foregroundColor(.akorioNeutral500)
            Text("Akort aleti mikrofon erişimi gerektiriyor.")
                .font(.system(size: 14))
                .foregroundColor(.akorioNeutral400)
                .multilineTextAlignment(.center)
            Text("Ayarlar > Akorio > Mikrofon üzerinden izin verebilirsin.")
                .font(.system(size: 13))
                .foregroundColor(.akorioNeutral600)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        TunerView(viewModel: AppViewModel())
    }
}

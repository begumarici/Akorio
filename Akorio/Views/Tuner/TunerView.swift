//
//  TunerView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import SwiftUI
import UIKit

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

            if engine.permissionState == .denied {
                permissionDeniedContent
            } else if engine.failedToStart {
                startFailedContent
            } else {
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
        VStack(spacing: 24) {
            noteBadge
            ChromaticStripView(pitch: engine.currentPitch, isInTune: isInTune, statusColor: statusColor)
            GuitarHeadstockView(
                activeString: engine.currentPitch?.closestGuitarString,
                statusColor: statusColor
            )
        }
    }

    // MARK: - Note badge
    private var noteBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [statusColor.opacity(0.22), Color.clear],
                        center: .center, startRadius: 10, endRadius: 110
                    )
                )
                .frame(width: 200, height: 200)
                .animation(.easeOut(duration: 0.25), value: isInTune)

            Circle()
                .fill(Color.akorioSurface)
                .frame(width: 150, height: 150)

            Circle()
                .stroke(statusColor, lineWidth: 3)
                .frame(width: 150, height: 150)
                .shadow(color: isInTune ? statusColor.opacity(0.7) : .clear, radius: 14)
                .animation(.easeOut(duration: 0.25), value: statusColor)

            VStack(spacing: 2) {
                HStack(alignment: .top, spacing: 2) {
                    Text(engine.currentPitch?.noteName ?? "–")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.akorioText)
                        .contentTransition(.numericText())

                    if let octave = engine.currentPitch?.octave {
                        Text("\(octave)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.akorioNeutral400)
                            .padding(.top, 8)
                    }
                }
                .animation(.easeOut(duration: 0.15), value: engine.currentPitch?.noteName)

                Text(engine.currentPitch.map { String(format: "%.1f Hz", $0.frequency) } ?? "—")
                    .font(.system(size: 12))
                    .foregroundColor(.akorioNeutral500)
            }
        }
    }

    // MARK: - Start failed
    private var startFailedContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.akorioNeutral500)
            Text("Mikrofon başlatılamadı.")
                .font(.system(size: 14))
                .foregroundColor(.akorioNeutral400)
                .multilineTextAlignment(.center)
            Button("Tekrar Dene") { engine.start() }
                .buttonStyle(AkorioSecondaryButtonStyle())
        }
        .padding(.horizontal, 24)
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
            Button("Ayarlara Git") {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            .buttonStyle(AkorioSecondaryButtonStyle())
            .padding(.top, 4)
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

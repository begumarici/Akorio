//
//  TunerView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 31.07.2026.
//

import SwiftUI
import UIKit

struct TunerView: View {
    @State private var engine = TunerEngine()
    @State private var lockedStrings: Set<GuitarString> = []

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

            if engine.permissionState == .denied {
                Spacer()
                permissionDeniedContent
                Spacer()
            } else if engine.failedToStart {
                Spacer()
                startFailedContent
                Spacer()
            } else {
                tunerContent
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            // Deferred a tick so starting the audio session (a real,
            // synchronous AVFoundation cost) doesn't block the tab-switch
            // transition's first frame and make it stutter.
            DispatchQueue.main.async { engine.start() }
        }
        .onDisappear { engine.stop() }
        .onChange(of: isInTune) { _, newValue in
            guard newValue, let string = engine.currentPitch?.closestGuitarString else { return }
            lockedStrings.insert(string)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Akort Aleti")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.akorioText)
                Text("Standart Akort · 440Hz")
                    .font(.system(size: 12))
                    .foregroundColor(.akorioNeutral500)
            }

            Spacer()

            Button {
                lockedStrings.removeAll()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.akorioNeutral400)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.akorioSurface))
            }
            .disabled(lockedStrings.isEmpty)
            .opacity(lockedStrings.isEmpty ? 0.4 : 1)
        }
        .padding(.top, 8)
    }

    // MARK: - Main content
    private var tunerContent: some View {
        VStack(spacing: 0) {
            TunerGaugeView(pitch: engine.currentPitch, isInTune: isInTune, statusColor: statusColor)
                .padding(.top, 32)

            noteReadout
                .padding(.top, 20)

            Spacer(minLength: 24)

            GuitarHeadstockView(
                activeString: engine.currentPitch?.closestGuitarString,
                statusColor: statusColor,
                lockedStrings: lockedStrings
            )
        }
    }

    // MARK: - Note readout
    private var noteReadout: some View {
        VStack(spacing: 2) {
            HStack(alignment: .top, spacing: 2) {
                Text(engine.currentPitch?.noteName ?? "–")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.akorioText)
                    .contentTransition(.numericText())

                if let octave = engine.currentPitch?.octave {
                    Text("\(octave)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.akorioNeutral400)
                        .padding(.top, 6)
                }
            }
            .animation(.easeOut(duration: 0.15), value: engine.currentPitch?.noteName)

            Text(engine.currentPitch.map { String(format: "%.1f Hz", $0.frequency) } ?? "—")
                .font(.system(size: 12))
                .foregroundColor(.akorioNeutral500)
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
        TunerView()
    }
}

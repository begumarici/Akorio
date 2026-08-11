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
    @State private var showAllTunedOverlay = false

    private var isInTune: Bool {
        guard let cents = engine.currentPitch?.cents else { return false }
        return abs(cents) < 5
    }

    private var statusColor: Color {
        guard engine.currentPitch != nil else { return .akorioNeutral700 }
        return isInTune ? .green : .akorioAccent400
    }

    var body: some View {
        ZStack {
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
                    GeometryReader { geo in
                        let rawScale = min(geo.size.width / contentNaturalSize.width, geo.size.height / contentNaturalSize.height)
                        let scale = min(1, max(0.3, rawScale))
                        tunerContent(scale: scale)
                            .frame(width: geo.size.width, alignment: .top)
                    }
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
            .onChange(of: engine.lockedStrings) { _, newValue in
                if newValue.count == GuitarString.allCases.count {
                    showAllTunedOverlay = true
                }
            }

            if showAllTunedOverlay {
                allTunedOverlay
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showAllTunedOverlay)
    }

    // MARK: - All strings tuned overlay
    private var allTunedOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { showAllTunedOverlay = false }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.35))
                        .frame(width: 90, height: 90)
                        .blur(radius: 30)
                    Circle()
                        .fill(Color.akorioAccent900)
                        .frame(width: 64, height: 64)
                    Image(systemName: "checkmark")
                        .font(.akorio(24, .bold))
                        .foregroundColor(.green)
                }

                VStack(spacing: 6) {
                    Text("Harika! 🎉")
                        .font(.akorioSerif(26, .semibold))
                        .foregroundColor(.akorioText)
                    Text("Gitarının akordu tamamlandı.")
                        .font(.akorio(14))
                        .foregroundColor(.akorioNeutral400)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    if viewModel.hasLastPracticeSession {
                        Button {
                            showAllTunedOverlay = false
                            viewModel.selectedTab = .home
                            viewModel.continueLastPractice()
                        } label: {
                            Text("Son Pratik Seansına Devam Et")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AkorioPrimaryButtonStyle())
                    }

                    Button {
                        showAllTunedOverlay = false
                        viewModel.selectedTab = .home
                    } label: {
                        Text("Akor Seç")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AkorioSecondaryButtonStyle())

                    Button("Kapat") { showAllTunedOverlay = false }
                        .font(.akorio(13, .medium))
                        .foregroundColor(.akorioNeutral500)
                        .padding(.top, 2)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.lg)
                    .fill(Color.akorioSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AkorioRadius.lg)
                            .stroke(Color.akorioStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, y: 12)
            )
            .padding(.horizontal, 32)
            .scaleEffect(showAllTunedOverlay ? 1 : 0.9)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Akort Aleti")
                    .font(.akorioSerif(24, .semibold))
                    .foregroundColor(.akorioText)
                Text("Standart Akort · 440Hz")
                    .font(.akorio(12))
                    .foregroundColor(.akorioNeutral500)
            }

            Spacer()

            Button {
                engine.lockedStrings.removeAll()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.akorio(16, .semibold))
                    .foregroundColor(.akorioNeutral400)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.akorioSurface))
            }
            .disabled(engine.lockedStrings.isEmpty)
            .opacity(engine.lockedStrings.isEmpty ? 0.4 : 1)
        }
        .padding(.top, 20)
    }

    // MARK: - Main content
    private let contentNaturalSize = CGSize(width: 350, height: 702)

    private func tunerContent(scale: CGFloat) -> some View {
        VStack(spacing: 0) {
            TunerGaugeView(pitch: engine.currentPitch, isInTune: isInTune, statusColor: statusColor, scale: scale)
                .padding(.top, 40 * scale)

            noteReadout(scale: scale)
                .padding(.top, 16 * scale)

            Spacer(minLength: 20 * scale)

            GuitarHeadstockView(
                activeString: engine.currentPitch?.closestGuitarString,
                statusColor: statusColor,
                lockedStrings: engine.lockedStrings,
                scale: scale
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Note readout
    private func noteReadout(scale: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(isInTune ? 0.4 : 0.15))
                .frame(width: 120 * scale, height: 120 * scale)
                .blur(radius: 36)
                .opacity(engine.currentPitch == nil ? 0 : 1)

            VStack(spacing: 2) {
                HStack(alignment: .top, spacing: 2) {
                    Text(engine.currentPitch?.noteName ?? "–")
                        .font(.akorio(40 * scale, .bold))
                        .foregroundColor(.akorioText)
                        .contentTransition(.numericText())

                    if let octave = engine.currentPitch?.octave {
                        Text("\(octave)")
                            .font(.akorio(15 * scale, .semibold))
                            .foregroundColor(.akorioNeutral400)
                            .padding(.top, 6 * scale)
                    }
                }
                .animation(.easeOut(duration: 0.15), value: engine.currentPitch?.noteName)

                Text(engine.currentPitch.map { String(format: "%.1f Hz", $0.frequency) } ?? "—")
                    .font(.akorio(12 * scale))
                    .foregroundColor(.akorioNeutral500)
            }
        }
        .animation(.easeOut(duration: 0.25), value: isInTune)
    }

    // MARK: - Start failed
    private var startFailedContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.akorio(32))
                .foregroundColor(.akorioNeutral500)
            Text("Mikrofon başlatılamadı.")
                .font(.akorio(14))
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
                .font(.akorio(32))
                .foregroundColor(.akorioNeutral500)
            Text("Akort aleti mikrofon erişimi gerektiriyor.")
                .font(.akorio(14))
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
        AkorioBackground()
        TunerView(viewModel: AppViewModel())
    }
}

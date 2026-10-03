//
//  PracticeView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

struct PracticeView: View {
    @Bindable var viewModel: AppViewModel
    @State private var isSettingsExpanded = true

    private var upcomingChordLabel: String {
        if !viewModel.nextChordLabel.isEmpty { return viewModel.nextChordLabel }
        return viewModel.chords.first?.label ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            GeometryReader { geo in
                let scale = min(1.6, max(0.35, geo.size.height / 290))
                chordDisplay(scale: scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }

            DisclosureGroup("Ayarlar", isExpanded: $isSettingsExpanded) {
                VStack(spacing: 10) {
                    statRow
                    toggleRows
                }
                .padding(.top, 10)
            }
            .tint(.akorioNeutral500)
            .foregroundColor(.akorioNeutral500)
            .font(.akorio(13, .medium))
            .padding(.horizontal, 20)

            practiceControls
                .padding(20)
        }
        .akorioContentWidth()
        .alert("Akor Setini Kaydet", isPresented: $viewModel.saveDialogOpen) {
            TextField("Set adı", text: $viewModel.saveNameInput)
            Button("Kaydet") { viewModel.confirmSave() }
            Button("Vazgeç", role: .cancel) { viewModel.closeSaveDialog() }
        }
        .onDisappear {
            viewModel.metronome.stop()
            viewModel.persistLastPracticeSession()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.requestPracticeExit()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(AkorioIconButtonStyle())
            .alert(
                "Pratikten çıkmak istiyor musun?",
                isPresented: $viewModel.showPracticeExitAlert
            ) {
                Button("Vazgeç", role: .cancel) {
                    viewModel.cancelPracticeExit()
                }
                Button("Pratikten Çık", role: .destructive) {
                    viewModel.confirmPracticeExit()
                }
            } message: {
                Text("Mevcut pratik seansı sona erecek.")
            }

            Text("Pratik")
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)

            Spacer()

            Button("Kaydet") {
                viewModel.openSaveDialog()
            }
            .buttonStyle(AkorioSecondaryButtonStyle())
        }
    }

    // MARK: - Chord display
    @ViewBuilder
    private func chordDisplay(scale: CGFloat) -> some View {
        VStack(spacing: 18 * scale) {
            if viewModel.isCountingIn {
                Text("BAŞLIYOR")
                    .font(.akorio(13, .medium))
                    .tracking(1)
                    .foregroundColor(.akorioAccent300)
                Text("\(viewModel.countInBeatsLeft)")
                    .font(.akorio(104 * scale, .medium))
                    .foregroundColor(.akorioNeutral300)
                Text(String(format: String(localized: "Sıradaki: %@"), viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel))
                    .font(.akorio(14 * scale))
                    .foregroundColor(.akorioNeutral500)
            } else if viewModel.isPlaying || viewModel.isPracticePaused {
                if viewModel.showChordDiagram {
                    Text(viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel)
                        .font(.akorio(32 * scale, .bold))
                        .foregroundColor(.akorioText)

                    if !viewModel.currentChordLabel.isEmpty {
                        ChordDiagramView(shape: ChordShapeLibrary.shape(for: viewModel.currentChordLabel), scale: 1.4 * scale)
                            .padding(10 * scale)
                            .background(
                                RoundedRectangle(cornerRadius: AkorioRadius.md)
                                    .fill(Color.white)
                            )
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.akorioAccent900, Color.akorioSurface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 190 * scale, height: 190 * scale)

                        Circle()
                            .stroke(Color.akorioStroke, lineWidth: 1)
                            .frame(width: 190 * scale, height: 190 * scale)

                        Text(viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel)
                            .font(.akorio(64 * scale, .semibold))
                            .foregroundColor(.akorioAccent100)
                    }
                }

                Text(String(format: String(localized: "Sıradaki: %@"), upcomingChordLabel))
                    .font(.akorio(14 * scale))
                    .foregroundColor(.akorioNeutral500)

                HStack(spacing: 8 * scale) {
                    ForEach(0..<max(viewModel.beatsPerChord, 1), id: \.self) { index in
                        Circle()
                            .fill(index == viewModel.beatInCurrentChord ? Color.akorioAccent500 : Color.akorioNeutral700)
                            .frame(width: 9 * scale, height: 9 * scale)
                    }
                }
            } else {
                Text("—")
                    .font(.akorio(64 * scale, .semibold))
                    .foregroundColor(.akorioNeutral700)

                Text(String(format: String(localized: "Sıradaki: %@"), upcomingChordLabel))
                    .font(.akorio(14 * scale))
                    .foregroundColor(.akorioNeutral500)
            }
        }
    }

    // MARK: - BPM / beats
    private var statRow: some View {
        HStack(spacing: 10) {
            AkorioStatBox(title: String(localized: "BPM"), value: viewModel.bpm, onDecrement: viewModel.decBpm, onIncrement: viewModel.incBpm)
            AkorioStatBox(title: String(localized: "Vuruş/Akor"), value: viewModel.beatsPerChord, onDecrement: viewModel.decBeats, onIncrement: viewModel.incBeats)
        }
    }

    // MARK: - Toggles
    private var toggleRows: some View {
        VStack(spacing: 1) {
            HStack {
                Text("Akor diyagramı göster").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.showChordDiagram) { viewModel.toggleShowChordDiagram() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Üst üste gösterme").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.preventBackToBackRepeat) { viewModel.toggleBackToBackRepeat() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Başlangıç sayımı").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.countInEnabled) { viewModel.toggleCountIn() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Metronom sesi").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.metronomeSoundEnabled) { viewModel.toggleMetronomeSoundEnabled() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)
        }
        .cornerRadius(AkorioRadius.md)
    }

    // MARK: - Play button
    @ViewBuilder
    private var practiceControls: some View {
        if viewModel.isPracticePaused {
            HStack(spacing: 12) {
                Button {
                    viewModel.resumePracticeSession()
                } label: {
                    Label("Devam Et", systemImage: "play.fill")
                }
                .buttonStyle(AkorioPrimaryButtonStyle())

                Button {
                    viewModel.finishPracticeSession()
                } label: {
                    Label("Bitir", systemImage: "checkmark")
                }
                .buttonStyle(AkorioPrimaryButtonStyle())
            }
        } else {
            playButton
        }
    }

    private var playButton: some View {
        Button {
            if !viewModel.isPlaying {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isSettingsExpanded = false
                }
            }
            viewModel.togglePlay()
        } label: {
            Label(
                viewModel.isPlaying ? "Durdur" : "Başlat",
                systemImage: viewModel.isPlaying ? "stop.fill" : "play.fill"
            )
        }
        .buttonStyle(AkorioPrimaryButtonStyle())
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        PracticeView(viewModel: AppViewModel())
    }
}

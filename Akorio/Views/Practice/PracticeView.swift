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

            chordDisplay
                .frame(maxHeight: .infinity)

            DisclosureGroup("Ayarlar", isExpanded: $isSettingsExpanded) {
                VStack(spacing: 10) {
                    statRow
                    toggleRows
                }
                .padding(.top, 10)
            }
            .tint(.akorioNeutral500)
            .foregroundColor(.akorioNeutral500)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 20)

            playButton
                .padding(20)
        }
        .alert("Akor Setini Kaydet", isPresented: $viewModel.saveDialogOpen) {
            TextField("Set adı", text: $viewModel.saveNameInput)
            Button("Kaydet") { viewModel.confirmSave() }
            Button("Vazgeç", role: .cancel) { viewModel.closeSaveDialog() }
        }
        .onDisappear {
            viewModel.metronome.stop()
        }
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

            Text("Pratik")
                .font(.system(size: 20, weight: .semibold))
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
    private var chordDisplay: some View {
        VStack(spacing: 18) {
            if viewModel.isCountingIn {
                Text("BAŞLIYOR")
                    .font(.system(size: 13, weight: .medium))
                    .tracking(1)
                    .foregroundColor(.akorioAccent300)
                Text("\(viewModel.countInBeatsLeft)")
                    .font(.system(size: 104, weight: .medium))
                    .foregroundColor(.akorioNeutral300)
                Text("Sıradaki: \(viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel)")
                    .font(.system(size: 14))
                    .foregroundColor(.akorioNeutral500)
            } else if viewModel.isPlaying {
                if viewModel.showChordDiagram {
                    Text(viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.akorioText)

                    if !viewModel.currentChordLabel.isEmpty {
                        ChordDiagramView(shape: ChordShapeLibrary.shape(for: viewModel.currentChordLabel), scale: 1.4)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: AkorioRadius.md)
                                    .fill(Color.white)
                            )
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.akorioAccent900)
                            .frame(width: 180, height: 180)
                        Circle()
                            .stroke(Color.akorioAccent700, lineWidth: 1)
                            .frame(width: 180, height: 180)
                        Text(viewModel.currentChordLabel.isEmpty ? "—" : viewModel.currentChordLabel)
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundColor(.akorioAccent100)
                    }
                    .shadow(color: Color.akorioAccent500.opacity(0.25), radius: 30)
                }

                Text("Sıradaki: \(upcomingChordLabel)")
                    .font(.system(size: 14))
                    .foregroundColor(.akorioNeutral500)

                HStack(spacing: 8) {
                    ForEach(0..<max(viewModel.beatsPerChord, 1), id: \.self) { index in
                        Circle()
                            .fill(index == viewModel.beatInCurrentChord ? Color.akorioAccent500 : Color.akorioNeutral700)
                            .frame(width: 9, height: 9)
                    }
                }
            } else {
                Text("—")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.akorioNeutral700)

                Text("Sıradaki: \(upcomingChordLabel)")
                    .font(.system(size: 14))
                    .foregroundColor(.akorioNeutral500)
            }
        }
    }

    // MARK: - BPM / beats
    private var statRow: some View {
        HStack(spacing: 10) {
            AkorioStatBox(title: "BPM", value: viewModel.bpm, onDecrement: viewModel.decBpm, onIncrement: viewModel.incBpm)
            AkorioStatBox(title: "Vuruş/Akor", value: viewModel.beatsPerChord, onDecrement: viewModel.decBeats, onIncrement: viewModel.incBeats)
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
            .font(.system(size: 14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Üst üste gösterme").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.preventBackToBackRepeat) { viewModel.toggleBackToBackRepeat() }
            }
            .font(.system(size: 14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Başlangıç sayımı").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.countInEnabled) { viewModel.toggleCountIn() }
            }
            .font(.system(size: 14))
            .padding(14)
            .background(Color.akorioSurface)

            HStack {
                Text("Metronom sesi").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: viewModel.metronomeSoundEnabled) { viewModel.toggleMetronomeSoundEnabled() }
            }
            .font(.system(size: 14))
            .padding(14)
            .background(Color.akorioSurface)
        }
        .cornerRadius(AkorioRadius.md)
    }

    // MARK: - Play button
    private var playButton: some View {
        Button(viewModel.isPlaying ? "Durdur" : "Başlat") {
            viewModel.togglePlay()
        }
        .buttonStyle(AkorioPrimaryButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        PracticeView(viewModel: AppViewModel())
    }
}

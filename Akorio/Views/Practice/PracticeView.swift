//
//  PracticeView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

struct PracticeView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            chordDisplay
                .frame(maxHeight: .infinity)

            VStack(spacing: 10) {
                statRow
                orderPicker
                toggleRows
            }
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

                Text("Sıradaki: \(viewModel.nextChordLabel.isEmpty ? "—" : viewModel.nextChordLabel)")
                    .font(.system(size: 14))
                    .foregroundColor(.akorioNeutral500)

                HStack(spacing: 8) {
                    ForEach(0..<max(viewModel.beatsPerChord, 1), id: \.self) { index in
                        Circle()
                            .fill(index == viewModel.beatInCurrentChord ? Color.akorioAccent500 : Color.akorioNeutral700)
                            .frame(width: 9, height: 9)
                    }
                }
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

    // MARK: - Order picker
    private var orderPicker: some View {
        Button {
            viewModel.toggleOrderPicker()
        } label: {
            HStack {
                Text("Sıralama")
                    .foregroundColor(.akorioText)
                Spacer()
                Text(viewModel.orderMode.label)
                    .foregroundColor(.akorioAccent300)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.akorioNeutral500)
            }
            .font(.system(size: 14))
            .padding(14)
        }
        .buttonStyle(.plain)
        .background(Color.akorioSurface)
        .cornerRadius(AkorioRadius.md)
        .overlay(alignment: .top) {
            if viewModel.orderPickerOpen {
                VStack(spacing: 0) {
                    ForEach(OrderMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.selectOrderMode(mode)
                        } label: {
                            HStack {
                                Text(mode.label)
                                    .foregroundColor(mode == viewModel.orderMode ? .akorioAccent100 : .akorioText)
                                Spacer()
                            }
                            .font(.system(size: 14))
                            .padding(14)
                            .background(mode == viewModel.orderMode ? Color.akorioAccent800 : Color.akorioSurface)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cornerRadius(AkorioRadius.md)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                .offset(y: 48)
            }
        }
        .zIndex(1)
    }

    // MARK: - Toggles
    private var toggleRows: some View {
        VStack(spacing: 1) {
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

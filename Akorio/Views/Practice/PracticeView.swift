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
    @State private var isPracticePlanPresented = false

    private var upcomingChordLabel: String {
        if !viewModel.nextChordLabel.isEmpty { return viewModel.nextChordLabel }
        return viewModel.chords.first?.label ?? "—"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 8)

            sessionStatusBar
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
                    practicePlanSettings
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
        .sheet(isPresented: $isPracticePlanPresented) {
            PracticePlanSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onDisappear {
            viewModel.metronome.stop()
            viewModel.persistLastPracticeSession()
        }
    }

    @ViewBuilder
    private var sessionStatusBar: some View {
        if (viewModel.isPlaying || viewModel.isPracticePaused),
           viewModel.remainingPracticeSeconds != nil {
            TimelineView(
                .animation(
                    minimumInterval: 0.1,
                    paused: !viewModel.isPlaying
                )
            ) { _ in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kalan süre")
                        .textCase(.uppercase)
                        .font(.akorio(10, .bold))
                        .tracking(0.8)
                        .foregroundColor(.akorioNeutral500)

                    Text(formattedSessionTime)
                        .font(.akorio(18, .bold))
                        .foregroundColor(.akorioText)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: AkorioRadius.md)
                        .fill(Color.akorioSurface)
                )
            }
        }
    }

    private var formattedSessionTime: String {
        let seconds = viewModel.remainingPracticeSeconds ?? viewModel.elapsedPracticeSeconds
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
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
                    ForEach(0..<max(viewModel.practice.beatsPerChord, 1), id: \.self) { index in
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
            AkorioStatBox(
                title: String(localized: "BPM"),
                value: viewModel.practice.bpm,
                onDecrement: { viewModel.updatePractice { $0.bpm -= 1 } },
                onIncrement: { viewModel.updatePractice { $0.bpm += 1 } }
            )
            AkorioStatBox(
                title: String(localized: "Vuruş/Akor"),
                value: viewModel.practice.beatsPerChord,
                onDecrement: { viewModel.updatePractice { $0.beatsPerChord -= 1 } },
                onIncrement: { viewModel.updatePractice { $0.beatsPerChord += 1 } }
            )
        }
    }

    private var practicePlanSettings: some View {
        Button {
            isPracticePlanPresented = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.akorioAccent400)

                Text("Pratik seçenekleri")
                    .foregroundColor(.akorioText)

                Spacer()

                Text(viewModel.practice.durationGoal.title)
                    .foregroundColor(.akorioNeutral500)

                Image(systemName: "chevron.right")
                    .font(.akorio(11, .semibold))
                    .foregroundColor(.akorioNeutral600)
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)
            .cornerRadius(AkorioRadius.md)
        }
        .buttonStyle(.plain)
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

private struct PracticePlanSheet: View {
    @Bindable var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AkorioBackground()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Pratik seçenekleri")
                        .font(.akorioSerif(24, .semibold))
                        .foregroundColor(.akorioText)

                    Spacer()

                    Button("Bitti") { dismiss() }
                        .font(.akorio(14, .semibold))
                        .foregroundColor(.akorioAccent400)
                }

                ScrollView {
                    PracticePlanControls(viewModel: viewModel)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .padding(20)
            .akorioContentWidth()
        }
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        PracticeView(viewModel: AppViewModel())
    }
}

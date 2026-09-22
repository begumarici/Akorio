//
//  LibraryView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 15.09.2026.
//

import SwiftUI

struct LibraryView: View {
    @State private var selectedRoot: String = "C"
    @State private var selectedQuality: ChordQuality = .major
    @State private var isPlaying = false
    @State private var playbackEngine = ChordPlaybackEngine()

    private var identity: ChordIdentity {
        ChordIdentity(root: selectedRoot, quality: selectedQuality)
    }

    private var shape: ChordShape? {
        ChordShapeLibrary.shape(root: selectedRoot, quality: selectedQuality)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            selectionSection
            chordSection
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .akorioContentWidth()
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: selectedRoot) { _, _ in resetSelection() }
        .onChange(of: selectedQuality) { _, _ in resetSelection() }
        .onDisappear { playbackEngine.stop() }
    }

    private var rootColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
    }

    private var qualityColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    }

    private let chordCardHeight: CGFloat = 210

    // MARK: - Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Akor Kütüphanesi")
                .font(.akorioSerif(28, .semibold))
                .foregroundColor(.akorioText)
            Text("Akorları keşfet, pozisyonlarını gör.")
                .font(.akorio(14))
                .foregroundColor(.akorioNeutral500)
        }
    }

    // MARK: - Chord selection
    private var selectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AKORU SEÇ")
                .sectionHeaderStyle()

            VStack(alignment: .leading, spacing: 10) {
                Text("KÖK NOTA")
                    .sectionHeaderStyle()

                LazyVGrid(columns: rootColumns, spacing: 8) {
                    ForEach(akorioRootNotes, id: \.self) { root in
                        selectorButton(label: root, isSelected: root == selectedRoot) {
                            selectedRoot = root
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("AKOR TİPİ")
                    .sectionHeaderStyle()

                LazyVGrid(columns: qualityColumns, spacing: 8) {
                    ForEach(ChordQuality.allCases) { quality in
                        selectorButton(label: quality.displayName, isSelected: quality == selectedQuality) {
                            selectedQuality = quality
                        }
                    }
                }
            }
        }
    }

    private func selectorButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.akorio(14, .medium))
                .foregroundColor(isSelected ? .white : .akorioText)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: AkorioRadius.sm)
                        .fill(isSelected ? Color.akorioAccent500 : Color.akorioSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AkorioRadius.sm)
                                .stroke(isSelected ? Color.clear : Color.akorioStroke, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(AkorioPressableCardStyle())
        .akorioAnimation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }

    // MARK: - Diagram
    private var chordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AKOR POZİSYONU")
                .sectionHeaderStyle()

            if let shape {
                VStack(spacing: 12) {
                    HStack {
                        Text(identity.label)
                            .font(.akorio(28, .bold))
                            .foregroundColor(.black)

                        Spacer()

                        Button {
                            togglePlayback()
                        } label: {
                            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.akorioAccent500, in: Circle())
                        }
                        .accessibilityLabel(isPlaying ? "Durdur" : "Akoru çal")
                    }
                    .padding(.horizontal, 18)

                    ChordDiagramView(shape: shape, scale: 1.55)

                }
                .frame(maxWidth: .infinity)
                .frame(height: chordCardHeight)
                .background(
                    RoundedRectangle(cornerRadius: AkorioRadius.lg)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                )
            } else {
                Text("Bu akor tipi için pozisyon henüz eklenmedi")
                    .font(.akorio(14))
                    .foregroundColor(.akorioNeutral500)
                    .frame(maxWidth: .infinity)
                    .frame(height: chordCardHeight)
                    .background(
                        RoundedRectangle(cornerRadius: AkorioRadius.lg)
                            .fill(Color.akorioSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AkorioRadius.lg)
                                    .stroke(Color.akorioStroke, lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func resetSelection() {
        playbackEngine.stop()
        isPlaying = false
    }

    private func togglePlayback() {
        guard let shape else { return }
        if isPlaying {
            playbackEngine.stop()
            isPlaying = false
        } else {
            playbackEngine.play(shape: shape)
            isPlaying = true
        }
    }
}

private extension Text {
    func sectionHeaderStyle() -> some View {
        self
            .font(.akorio(11, .medium))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral500)
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        LibraryView()
    }
}

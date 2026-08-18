//
//  LevelDetailView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

struct LevelDetailView: View {
    let viewModel: AppViewModel
    let level: ChordLevel

    private var selectedCount: Int {
        viewModel.chords.filter { level.chordLabels.contains($0.label) }.count
    }

    private var allSelected: Bool {
        selectedCount == level.chordLabels.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.subtitle + ".")
                        .font(.akorio(13))
                        .foregroundColor(.akorioNeutral500)
                    Text("Pratiğe başlamak için akorlarını seç.")
                        .font(.akorio(13))
                        .foregroundColor(.akorioNeutral500)

                    HStack {
                        Text(String(format: String(localized: "%@ / %@ akor seçildi"), "\(selectedCount)", "\(level.chordLabels.count)"))
                            .font(.akorio(13))
                            .foregroundColor(.akorioNeutral500)

                        Spacer()

                        Button {
                            if allSelected {
                                viewModel.deselectAllChordLabels(level.chordLabels)
                            } else {
                                viewModel.selectAllChordLabels(level.chordLabels)
                            }
                        } label: {
                            Label(allSelected ? "Seçimi Kaldır" : "Hepsini Seç", systemImage: allSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        }
                        .buttonStyle(AkorioSecondaryButtonStyle())
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 105, maximum: 180), spacing: 10)], spacing: 10) {
                    ForEach(level.chordLabels, id: \.self) { label in
                        ChordCard(
                            label: label,
                            isSelected: viewModel.chords.contains { $0.label == label }
                        ) {
                            viewModel.toggleChordLabel(label)
                        }
                    }
                }
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .akorioIntegralWidth()
        .safeAreaInset(edge: .bottom) {
            if !viewModel.chords.isEmpty {
                Button("Pratiğe Başla") { viewModel.goToPractice() }
                    .buttonStyle(AkorioPrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .akorioContentWidth()
                    .background(.ultraThinMaterial)
            }
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

            Text(level.title)
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)
        }
    }
}

// MARK: - Chord card
private struct ChordCard: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(label)
                    .font(.akorio(18, .bold))
                    .foregroundColor(.black)
                ChordDiagramView(shape: ChordShapeLibrary.shape(for: label))
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(Color.white)
                    .shadow(color: isSelected ? Color.akorioAccent500.opacity(0.35) : .black.opacity(0.2), radius: 10, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .stroke(isSelected ? Color.akorioAccent500 : .clear, lineWidth: 2)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(Color.akorioAccent500)
                        Image(systemName: "checkmark")
                            .font(.akorio(10, .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 22, height: 22)
                    .offset(x: 7, y: -7)
                }
            }
        }
        .buttonStyle(AkorioPressableCardStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        LevelDetailView(viewModel: AppViewModel(), level: .beginner)
    }
}

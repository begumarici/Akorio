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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.subtitle + ".")
                        .font(.system(size: 13))
                        .foregroundColor(.akorioNeutral500)
                    Text("Pratiğe başlamak için akorlarını seç.")
                        .font(.system(size: 13))
                        .foregroundColor(.akorioNeutral500)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(level.chordLabels, id: \.self) { label in
                        ChordCard(
                            label: label,
                            isSelected: viewModel.chords.contains { $0.label == label }
                        ) {
                            viewModel.toggleChordLabel(label)
                        }
                    }
                }

                Text("\(selectedCount) / \(level.chordLabels.count) akor seçildi")
                    .font(.system(size: 13))
                    .foregroundColor(.akorioNeutral500)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            if !viewModel.chords.isEmpty {
                Button("Pratiğe Başla") { viewModel.goToPractice() }
                    .buttonStyle(AkorioPrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
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
                .font(.system(size: 20, weight: .semibold))
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                ChordDiagramView(shape: ChordShapeLibrary.shape(for: label))
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(Color.white)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    ZStack {
                        Circle().fill(Color.green)
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 20, height: 20)
                    .offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        LevelDetailView(viewModel: AppViewModel(), level: .beginner)
    }
}

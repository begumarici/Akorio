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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                Text(level.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.akorioNeutral500)

                AkorioFlowLayout(spacing: 8) {
                    ForEach(level.chordLabels, id: \.self) { label in
                        ChordPill(
                            label: label,
                            isSelected: viewModel.chords.contains { $0.label == label }
                        ) {
                            viewModel.toggleChordLabel(label)
                        }
                    }
                }
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

// MARK: - Chord pill
private struct ChordPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .akorioAccent100 : .akorioText)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(isSelected ? Color.akorioAccent800 : Color.clear)
                )
                .overlay(
                    Capsule().stroke(isSelected ? Color.akorioAccent500 : Color.akorioDivider, lineWidth: 1)
                )
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

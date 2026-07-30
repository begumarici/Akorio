//
//  SelectorView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

struct SelectorView: View {
    let viewModel: AppViewModel

    @Query(sort: \SavedChordSet.createdAt, order: .reverse)
    private var savedSets: [SavedChordSet]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                levelSection
            }
            .padding(20)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Akor Seçici")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.akorioText)
                Text("Bir seviye seç, sonra akorları işaretle")
                    .font(.system(size: 13))
                    .foregroundColor(.akorioNeutral500)
            }
            Spacer()
            
            Button {
                viewModel.goToSaved()
            } label: {
                Image(systemName: "music.note.list")
            }
            .buttonStyle(AkorioIconButtonStyle())
            .overlay(alignment: .topTrailing) {
                if !savedSets.isEmpty {
                    Text("\(savedSets.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.akorioAccent500))
                        .offset(x: 6, y: -6)
                }
            }

            Button {
                viewModel.goToSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(AkorioIconButtonStyle())
        }
    }

    // MARK: - Level picker
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SEVİYE SEÇ")
                .sectionHeaderStyle()

            VStack(spacing: 10) {
                ForEach(ChordLevel.allCases, id: \.self) { level in
                    LevelRow(
                        level: level,
                        selectedCount: viewModel.chords.filter { chord in level.chordLabels.contains(chord.label) }.count
                    ) {
                        viewModel.goToLevelDetail(level)
                    }
                }
            }
        }
    }
}

// MARK: - Level row
private struct LevelRow: View {
    let level: ChordLevel
    let selectedCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.akorioText)
                    Text(level.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.akorioNeutral500)
                }
                Spacer()
                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.akorioAccent100)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.akorioAccent800))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.akorioNeutral500)
            }
            .akorioCard()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header text style
private extension Text {
    func sectionHeaderStyle() -> some View {
        self
            .font(.system(size: 11, weight: .medium))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral500)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        SelectorView(viewModel: AppViewModel())
    }
    .modelContainer(for: [SavedChordSet.self, AppSettings.self], inMemory: true)
}

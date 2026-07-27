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

    private var visibleTypes: [ChordType] {
        viewModel.showMoreTypes ? akorioCommonTypes + akorioMoreTypes : akorioCommonTypes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                selectedChordsSection
                rootNoteSection
                if viewModel.selectedRoot != nil {
                    chordTypeSection
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
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Akor Seçici")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.akorioText)
                Text("Kök nota seç, sonra akor tipini işaretle")
                    .font(.system(size: 13))
                    .foregroundColor(.akorioNeutral500)
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    viewModel.goToSaved()
                } label: {
                    Text("Kayıtlı Setler\(savedSets.isEmpty ? "" : " (\(savedSets.count))")")
                }
                .buttonStyle(AkorioSecondaryButtonStyle())

                Button {
                    viewModel.goToSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(AkorioIconButtonStyle())
            }
        }
    }

    // MARK: - Selected chords
    private var selectedChordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SEÇİLEN AKORLAR (\(viewModel.chords.count))")
                .sectionHeaderStyle()

            if viewModel.chords.isEmpty {
                Text("Henüz akor eklenmedi")
                    .font(.system(size: 13))
                    .foregroundColor(.akorioNeutral600)
            } else {
                AkorioFlowLayout(spacing: 8) {
                    ForEach(viewModel.chords) { chord in
                        AkorioChordChip(label: chord.label) {
                            viewModel.removeChord(chord.label)
                        }
                        .draggable(chord.label)
                        .dropDestination(for: String.self) { items, _ in
                            guard
                                let draggedLabel = items.first,
                                let fromIndex = viewModel.chords.firstIndex(where: { $0.label == draggedLabel }),
                                let toIndex = viewModel.chords.firstIndex(where: { $0.label == chord.label }),
                                fromIndex != toIndex
                            else { return false }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.moveChords(
                                    from: IndexSet(integer: fromIndex),
                                    to: toIndex > fromIndex ? toIndex + 1 : toIndex
                                )
                            }
                            return true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Root note
    private var rootNoteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KÖK NOTA")
                .sectionHeaderStyle()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(akorioRootNotes, id: \.self) { note in
                    RootNoteButton(note: note, isSelected: viewModel.selectedRoot == note) {
                        viewModel.selectRoot(note)
                    }
                }
            }
        }
    }

    // MARK: - Chord type
    private var chordTypeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(viewModel.selectedRoot ?? "") AKOR TİPİ")
                .sectionHeaderStyle()

            AkorioFlowLayout(spacing: 8) {
                ForEach(visibleTypes) { type in
                    let label = (viewModel.selectedRoot ?? "") + type.suffix
                    ChordTypePill(
                        type: type,
                        isSelected: viewModel.chords.contains { $0.label == label }
                    ) {
                        viewModel.toggleType(type)
                    }
                }
            }

            Button {
                viewModel.toggleMoreTypes()
            } label: {
                Text(viewModel.showMoreTypes ? "Daha az göster ▴" : "Daha fazla tip göster ▾")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.akorioAccent300)
            }
        }
    }
}

// MARK: - Root note button
private struct RootNoteButton: View {
    let note: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(note)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : .akorioText)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: AkorioRadius.lg)
                        .fill(isSelected ? Color.akorioAccent900 : Color.akorioSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AkorioRadius.lg)
                        .stroke(isSelected ? Color.akorioAccent500 : Color.akorioDivider, lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Chord type pill
private struct ChordTypePill: View {
    let type: ChordType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.display)
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

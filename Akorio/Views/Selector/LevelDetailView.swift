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
    @State private var expandedQualities: Set<ChordQuality> = []

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
                            AkorioHaptics.impact(enabled: viewModel.settings.hapticEnabled)
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

                if level == .expert {
                    advancedChordGroups
                } else {
                    chordGrid(labels: level.chordLabels)
                }
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .akorioIntegralWidth()
        .safeAreaInset(edge: .bottom) {
            if !viewModel.chords.isEmpty {
                Button("Devam Et") { viewModel.goToPractice() }
                    .buttonStyle(AkorioPrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .akorioContentWidth()
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Advanced chord library
    private var advancedChordGroups: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "AKOR TÜRLERİ"))
                .font(.akorio(12, .bold))
                .foregroundColor(.akorioText)

            ForEach(ChordQuality.allCases) { quality in
                let labels = labels(for: quality)
                qualitySection(quality: quality, labels: labels, allLabels: labels)
            }
        }
    }

    private func qualitySection(
        quality: ChordQuality,
        labels: [String],
        allLabels: [String]
    ) -> some View {
        let selectedCount = allLabels.filter { label in
            viewModel.chords.contains { $0.label == label }
        }.count
        let isExpanded = expandedQualities.contains(quality)
        let allSelected = selectedCount == allLabels.count
        let selectionAccessibilityLabel = allSelected
            ? String(localized: "Tür seçimini kaldır")
            : String(localized: "Bu türün tamamını seç")

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button {
                    withAnimation {
                        if expandedQualities.contains(quality) {
                            expandedQualities.remove(quality)
                        } else {
                            expandedQualities.insert(quality)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.akorio(11, .bold))
                            .frame(width: 14)

                        Text(quality.displayName)
                            .font(.akorio(15, .semibold))

                        Spacer()

                        Text("\(selectedCount) / \(allLabels.count)")
                            .font(.akorio(12))
                            .foregroundColor(.akorioNeutral500)
                    }
                    .foregroundColor(.akorioText)
                }
                .buttonStyle(.plain)

                Button {
                    AkorioHaptics.impact(enabled: viewModel.settings.hapticEnabled)
                    if allSelected {
                        viewModel.deselectAllChordLabels(allLabels)
                    } else {
                        viewModel.selectAllChordLabels(allLabels)
                    }
                } label: {
                    Image(systemName: allSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(allSelected ? .akorioAccent500 : .akorioNeutral500)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selectionAccessibilityLabel)
            }

            if isExpanded {
                chordGrid(labels: labels)
            }
        }
        .padding(12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func labels(for quality: ChordQuality) -> [String] {
        akorioRootNotes.map { ChordIdentity(root: $0, quality: quality).label }
    }

    private func chordGrid(labels: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 105, maximum: 180), spacing: 10)], spacing: 10) {
            ForEach(labels, id: \.self) { label in
                ChordCard(
                    label: label,
                    isSelected: viewModel.chords.contains { $0.label == label }
                ) {
                    AkorioHaptics.selection(enabled: viewModel.settings.hapticEnabled)
                    viewModel.toggleChordLabel(label)
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.router.goBack()
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
        .akorioAnimation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        LevelDetailView(viewModel: AppViewModel(), level: .beginner)
    }
}

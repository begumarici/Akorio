//
//  PracticePlanControls.swift
//  Akorio
//

import SwiftUI

struct PracticePlanControls: View {
    @Bindable var viewModel: AppViewModel
    var showsExplanations = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Hedef süre")

                Spacer()

                Text(viewModel.practiceDurationGoal.title)
                    .font(.akorio(12, .medium))
                    .foregroundColor(.akorioNeutral500)
            }

            HStack(spacing: 6) {
                ForEach(PracticeDurationGoal.allCases) { goal in
                    PracticeSettingOptionButton(
                        title: compactTitle(for: goal),
                        accessibilityLabel: goal.title,
                        isSelected: viewModel.practiceDurationGoal == goal
                    ) {
                        viewModel.selectPracticeDurationGoal(goal)
                    }
                }
            }

            if showsExplanations {
                Text("Süre dolduğunda pratik otomatik tamamlanır.")
                    .font(.akorio(11))
                    .foregroundColor(.akorioNeutral500)
            }

            sectionTitle("Pratik seçenekleri")

            VStack(spacing: 1) {
                optionRow(
                    title: "Akor diyagramı göster",
                    isOn: viewModel.showChordDiagram,
                    action: viewModel.toggleShowChordDiagram
                )

                optionRow(
                    title: "Aynı akoru art arda getirme",
                    isOn: viewModel.preventBackToBackRepeat,
                    action: viewModel.toggleBackToBackRepeat
                )

                optionRow(
                    title: "Başlangıç sayımı",
                    isOn: viewModel.countInEnabled,
                    action: viewModel.toggleCountIn
                )

                optionRow(
                    title: "Metronom sesi",
                    isOn: viewModel.metronomeSoundEnabled,
                    action: viewModel.toggleMetronomeSoundEnabled
                )

                optionRow(
                    title: "Haptik geri bildirim",
                    isOn: viewModel.hapticEnabled,
                    action: viewModel.toggleHaptic
                )

                optionRow(
                    title: "Akorun ilk vuruşunu vurgula",
                    isOn: viewModel.accentFirstBeat,
                    action: viewModel.toggleAccentFirstBeat
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: AkorioRadius.md))
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .textCase(.uppercase)
            .font(.akorio(11, .bold))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral500)
    }

    private func compactTitle(for goal: PracticeDurationGoal) -> String {
        goal == .unlimited ? "∞" : "\(goal.rawValue)"
    }

    private func optionRow(
        title: LocalizedStringKey,
        isOn: Bool,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.akorio(14))
                .foregroundColor(.akorioText)

            Spacer()

            AkorioToggle(isOn: isOn, onToggle: action)
        }
        .padding(14)
        .background(Color.akorioSurface)
    }
}

private struct PracticeSettingOptionButton: View {
    let title: String
    let accessibilityLabel: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.akorio(12, .semibold))
                .foregroundColor(isSelected ? .akorioAccent100 : .akorioNeutral500)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 38)
                .background(
                    RoundedRectangle(cornerRadius: AkorioRadius.sm)
                        .fill(isSelected ? Color.akorioAccent900 : Color.akorioSurfaceHigh)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AkorioRadius.sm)
                        .stroke(isSelected ? Color.akorioAccent500.opacity(0.55) : Color.akorioStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

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

                Text(viewModel.practice.durationGoal.title)
                    .font(.akorio(12, .medium))
                    .foregroundColor(.akorioNeutral500)
            }

            HStack(spacing: 6) {
                ForEach(PracticeDurationGoal.allCases) { goal in
                    PracticeSettingOptionButton(
                        title: compactTitle(for: goal),
                        accessibilityLabel: goal.title,
                        isSelected: viewModel.practice.durationGoal == goal
                    ) {
                        viewModel.updatePractice { $0.durationGoal = goal }
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
                    isOn: viewModel.settings.showChordDiagram,
                    action: viewModel.settings.toggleShowChordDiagram
                )

                optionRow(
                    title: "Aynı akoru art arda getirme",
                    isOn: viewModel.practice.preventBackToBackRepeat,
                    action: { viewModel.updatePractice { $0.preventBackToBackRepeat.toggle() } }
                )

                optionRow(
                    title: "Başlangıç sayımı",
                    isOn: viewModel.practice.countInEnabled,
                    action: { viewModel.updatePractice { $0.countInEnabled.toggle() } }
                )

                optionRow(
                    title: "Metronom sesi",
                    isOn: viewModel.practice.metronomeSoundEnabled,
                    action: { viewModel.updatePractice { $0.metronomeSoundEnabled.toggle() } }
                )

                optionRow(
                    title: "Haptik geri bildirim",
                    isOn: viewModel.settings.hapticEnabled,
                    action: viewModel.settings.toggleHaptic
                )

                optionRow(
                    title: "Akorun ilk vuruşunu vurgula",
                    isOn: viewModel.practice.accentFirstBeat,
                    action: { viewModel.updatePractice { $0.accentFirstBeat.toggle() } }
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

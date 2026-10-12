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

            HStack {
                Text("Akorun ilk vuruşunu vurgula")
                    .font(.akorio(14))
                    .foregroundColor(.akorioText)

                Spacer()

                AkorioToggle(isOn: viewModel.accentFirstBeat) {
                    viewModel.toggleAccentFirstBeat()
                }
            }
            .padding(14)
            .background(Color.akorioSurface)
            .cornerRadius(AkorioRadius.md)
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

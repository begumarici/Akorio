//
//  PracticePlanView.swift
//  Akorio
//

import SwiftUI

struct PracticePlanView: View {
    @Bindable var viewModel: AppViewModel
    let onBack: () -> Void
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                selectedChords
                tempoControls
                PracticePlanControls(viewModel: viewModel, showsExplanations: false)
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            Button("Pratiğe Başla", action: onStart)
                .buttonStyle(AkorioPrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .akorioContentWidth()
                .background(Color.akorioBg.opacity(0.96))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(AkorioIconButtonStyle())

            Text("Pratik planı")
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)
        }
    }

    private var selectedChords: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                sectionTitle("SEÇİLEN AKORLAR")

                Text(selectedChordSummary)
                    .font(.akorio(16, .semibold))
                    .foregroundColor(.akorioText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(String(format: String(localized: "%@ akor"), "\(viewModel.chords.count)"))
                .font(.akorio(12, .medium))
                .foregroundColor(.akorioNeutral500)
        }
        .padding(14)
        .background(Color.akorioSurface)
        .clipShape(RoundedRectangle(cornerRadius: AkorioRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AkorioRadius.md)
                .stroke(Color.akorioStroke, lineWidth: 1)
        )
    }

    private var tempoControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Tempo")

            VStack(spacing: 0) {
                PracticePlanStepperRow(
                    title: String(localized: "BPM"),
                    value: viewModel.bpm,
                    onDecrement: viewModel.decBpm,
                    onIncrement: viewModel.incBpm
                )

                Divider()
                    .overlay(Color.akorioStroke)

                PracticePlanStepperRow(
                    title: String(localized: "Vuruş/Akor"),
                    value: viewModel.beatsPerChord,
                    onDecrement: viewModel.decBeats,
                    onIncrement: viewModel.incBeats
                )
            }
            .padding(.horizontal, 14)
            .background(Color.akorioSurface)
            .clipShape(RoundedRectangle(cornerRadius: AkorioRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .stroke(Color.akorioStroke, lineWidth: 1)
            )
        }
    }

    private var selectedChordSummary: String {
        let visibleChords = viewModel.chords.prefix(4).map(\.label)
        let remainingCount = viewModel.chords.count - visibleChords.count
        let summary = visibleChords.joined(separator: ", ")

        guard remainingCount > 0 else { return summary }
        return "\(summary) +\(remainingCount)"
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.akorio(11, .bold))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral500)
    }
}

private struct PracticePlanStepperRow: View {
    let title: String
    let value: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.akorio(14, .medium))
                .foregroundColor(.akorioText)

            Spacer()

            stepperButton(systemName: "minus", action: onDecrement)

            Text("\(value)")
                .font(.akorio(18, .bold))
                .foregroundColor(.akorioText)
                .monospacedDigit()
                .frame(minWidth: 42)

            stepperButton(systemName: "plus", action: onIncrement)
        }
        .frame(minHeight: 54)
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.akorioText)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.akorioSurfaceHigh))
                .overlay(Circle().stroke(Color.akorioStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let viewModel = AppViewModel()
    viewModel.chords = ["Am", "Em", "G"].map(ChordItem.init(label:))

    return ZStack {
        AkorioBackground()
        PracticePlanView(viewModel: viewModel, onBack: {}, onStart: {})
    }
}

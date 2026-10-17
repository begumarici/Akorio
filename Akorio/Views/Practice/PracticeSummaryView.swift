//
//  PracticeSummaryView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 29.09.2026.
//

import SwiftUI

struct PracticeSummaryView: View {
    let summary: PracticeSessionSummary
    let onRepeat: () -> Void
    let onReturnHome: () -> Void

    private var durationText: String {
        let minutes = summary.durationSeconds / 60
        let seconds = summary.durationSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var goalText: String {
        guard let targetMinutes = summary.targetDurationMinutes else {
            return String(localized: "Süresiz")
        }

        if summary.goalCompleted {
            return String(format: String(localized: "%lld dk ✓"), targetMinutes)
        }

        return String(format: String(localized: "%lld dk"), targetMinutes)
    }

    private var goalProgress: Double? {
        guard let targetMinutes = summary.targetDurationMinutes else { return nil }
        let targetSeconds = max(targetMinutes * 60, 1)
        return min(Double(summary.durationSeconds) / Double(targetSeconds), 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                celebrationHeader
                durationCard
                statisticsRow
                practicedChordsCard
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actionBar
        }
    }

    private var celebrationHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.akorioAccent900)
                    .frame(width: 104, height: 104)

                Circle()
                    .stroke(Color.akorioAccent500.opacity(0.35), lineWidth: 2)
                    .frame(width: 88, height: 88)

                Image(systemName: summary.goalCompleted ? "trophy.fill" : "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.akorioAccent300)

                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.akorioAccent400)
                    .offset(x: 54, y: -40)

                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.akorioAccent300)
                    .offset(x: -52, y: 34)
            }

            Text("Pratik tamamlandı")
                .font(.akorioSerif(30, .semibold))
                .foregroundColor(.akorioText)
                .multilineTextAlignment(.center)

            Text(
                summary.goalCompleted
                    ? String(localized: "Hedefini tamamladın!")
                    : String(localized: "Harika bir çalışma seansı!")
            )
                .font(.akorio(14, .medium))
                .foregroundColor(summary.goalCompleted ? .akorioAccent300 : .akorioNeutral500)
        }
        .padding(.top, 12)
    }

    private var durationCard: some View {
        VStack(spacing: 12) {
            Text("Pratik süresi")
                .textCase(.uppercase)
                .font(.akorio(11, .bold))
                .tracking(0.8)
                .foregroundColor(.akorioNeutral500)

            Text(durationText)
                .font(.akorio(44, .bold))
                .foregroundColor(.akorioText)
                .monospacedDigit()

            if let goalProgress {
                ProgressView(value: goalProgress)
                    .tint(.akorioAccent500)

                HStack {
                    Text("Hedef")
                    Spacer()
                    Text(goalText)
                }
                .font(.akorio(12, .medium))
                .foregroundColor(.akorioNeutral500)
            } else {
                Text(goalText)
                    .font(.akorio(12, .medium))
                    .foregroundColor(.akorioNeutral500)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AkorioRadius.lg)
                .fill(Color.akorioSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AkorioRadius.lg)
                        .stroke(Color.akorioAccent500.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var statisticsRow: some View {
        HStack(spacing: 8) {
            SummaryMetricCard(
                icon: "arrow.left.arrow.right",
                title: String(localized: "Akor geçişi"),
                value: "\(summary.chordTransitionCount)"
            )

            SummaryMetricCard(
                icon: "metronome",
                title: String(localized: "BPM"),
                value: "\(summary.bpm)"
            )

            SummaryMetricCard(
                icon: "circle.grid.2x2.fill",
                title: String(localized: "Vuruş/Akor"),
                value: "\(summary.beatsPerChord)"
            )
        }
    }

    private var practicedChordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ÇALIŞILAN AKORLAR")
                .font(.akorio(11, .bold))
                .tracking(0.6)
                .foregroundColor(.akorioNeutral500)

            AkorioFlowLayout(spacing: 8) {
                ForEach(summary.chordLabels, id: \.self) { chord in
                    Text(chord)
                        .font(.akorio(14, .semibold))
                        .foregroundColor(.akorioText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Color.akorioSurfaceHigh))
                        .overlay(Capsule().stroke(Color.akorioStroke, lineWidth: 1))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .akorioCard()
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button("Ana Sayfaya Dön", action: onReturnHome)
                .buttonStyle(AkorioPrimaryButtonStyle())

            Button(action: onRepeat) {
                Text("Tekrar Pratik Yap")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AkorioSecondaryButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .akorioContentWidth()
        .background(Color.akorioBg.opacity(0.96))
    }
}

private struct SummaryMetricCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.akorioAccent400)

            Text(value)
                .font(.akorio(22, .bold))
                .foregroundColor(.akorioText)

            Text(title)
                .font(.akorio(10, .medium))
                .foregroundColor(.akorioNeutral500)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 94)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: AkorioRadius.md)
                .fill(Color.akorioSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: AkorioRadius.md)
                        .stroke(Color.akorioStroke, lineWidth: 1)
                )
        )
    }
}

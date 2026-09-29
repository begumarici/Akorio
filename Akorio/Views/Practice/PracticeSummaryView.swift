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

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var durationText: String {
        let minutes = summary.durationSeconds / 60
        let seconds = summary.durationSeconds % 60

        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.akorioAccent900)
                            .frame(width: 76, height: 76)

                        Image(systemName: "checkmark")
                            .font(.akorio(30, .bold))
                            .foregroundColor(.akorioAccent300)
                    }

                    Text("Pratik tamamlandı")
                        .font(.akorioSerif(32, .semibold))
                        .foregroundColor(.akorioText)

                    Text("Harika bir çalışma seansı!")
                        .font(.akorio(14))
                        .foregroundColor(.akorioNeutral500)
                }

                LazyVGrid(columns: columns, spacing: 10) {
                    SummaryMetricCard(
                        title: String(localized: "Pratik süresi"),
                        value: durationText
                    )

                    SummaryMetricCard(
                        title: String(localized: "Akor geçişi"),
                        value: "\(summary.chordTransitionCount)"
                    )

                    SummaryMetricCard(
                        title: String(localized: "BPM"),
                        value: "\(summary.bpm)"
                    )

                    SummaryMetricCard(
                        title: String(localized: "Vuruş/Akor"),
                        value: "\(summary.beatsPerChord)"
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("ÇALIŞILAN AKORLAR")
                        .font(.akorio(12, .bold))
                        .foregroundColor(.akorioNeutral500)

                    AkorioFlowLayout(spacing: 8) {
                        ForEach(summary.chordLabels, id: \.self) { chord in
                            Text(chord)
                                .font(.akorio(14, .semibold))
                                .foregroundColor(.akorioText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.akorioSurfaceHigh)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.akorioStroke, lineWidth: 1)
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .akorioCard()

                VStack(spacing: 12) {
                    Button("Tekrar Pratik Yap", action: onRepeat)
                        .buttonStyle(AkorioPrimaryButtonStyle())

                    Button("Ana Sayfaya Dön", action: onReturnHome)
                        .buttonStyle(AkorioSecondaryButtonStyle())
                }
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

private struct SummaryMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.akorio(26, .bold))
                .foregroundColor(.akorioText)

            Text(title)
                .font(.akorio(12))
                .foregroundColor(.akorioNeutral500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
        .akorioCard()
    }
}

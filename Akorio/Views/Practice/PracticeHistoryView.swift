//
//  PracticeHistoryView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 03.10.2026.
//

import SwiftUI
import SwiftData

struct PracticeHistoryView: View {
    let viewModel: AppViewModel

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PracticeSession.completedAt, order: .reverse)
    private var sessions: [PracticeSession]

    @State private var pendingDelete: PracticeSession?
    @State private var isClearHistoryConfirmationPresented = false

    private var statistics: PracticeStatistics {
        PracticeStatisticsCalculator.calculate(from: sessions)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if sessions.isEmpty {
                    emptyState
                } else {
                    overview
                    sessionList
                }
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .akorioIntegralWidth()
        .alert(
            "Bu pratik kaydı silinsin mi?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { isPresented in
                    if !isPresented {
                        pendingDelete = nil
                    }
                }
            )
        ) {
            Button("Sil", role: .destructive) {
                if let pendingDelete {
                    modelContext.delete(pendingDelete)
                    try? modelContext.save()
                }
                pendingDelete = nil
            }
            Button("Vazgeç", role: .cancel) {
                pendingDelete = nil
            }
        }
        .alert(
            "Tüm pratik geçmişi silinsin mi?",
            isPresented: $isClearHistoryConfirmationPresented
        ) {
            Button("Tümünü Sil", role: .destructive) {
                deleteAllSessions()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Bu işlem geri alınamaz.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(AkorioIconButtonStyle())

            Text("Pratik Geçmişi")
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)
        }
    }

    private var overview: some View {
        HStack(spacing: 8) {
            HistoryMetric(
                icon: "flame.fill",
                value: "\(statistics.currentStreak)",
                title: String(localized: "Günlük seri")
            )

            HistoryMetric(
                icon: "clock.fill",
                value: formattedTotalDuration,
                title: String(localized: "Toplam süre")
            )

            HistoryMetric(
                icon: "checkmark.circle.fill",
                value: "\(statistics.completedSessionCount)",
                title: String(localized: "Seans")
            )
        }
    }

    private var sessionList: some View {
        LazyVStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TAMAMLANAN SEANSLAR")
                    .font(.akorio(11, .medium))
                    .tracking(0.6)
                    .foregroundColor(.akorioNeutral500)

                Spacer()

                Button("Tümünü Sil", role: .destructive) {
                    isClearHistoryConfirmationPresented = true
                }
                .font(.akorio(12, .medium))
                .foregroundColor(.red)
            }

            ForEach(sessions) { session in
                sessionRow(session)
            }
        }
    }

    private func sessionRow(_ session: PracticeSession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.chordLabels.joined(separator: ", "))
                    .font(.akorio(16, .semibold))
                    .foregroundColor(.akorioText)
                    .lineLimit(2)

                Text(
                    String(
                        format: String(localized: "%@ · %lld geçiş · %lld BPM"),
                        formattedDuration(session.durationSeconds),
                        session.chordTransitionCount,
                        session.bpm
                    )
                )
                .font(.akorio(12))
                .foregroundColor(.akorioNeutral500)

                Text(session.completedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.akorio(11))
                    .foregroundColor(.akorioNeutral600)
            }

            Spacer()

            Button {
                pendingDelete = session
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(AkorioIconButtonStyle(size: 32))
        }
        .akorioCard()
    }

    private func deleteAllSessions() {
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.xaxis")
                .font(.akorio(34))
                .foregroundColor(.akorioNeutral600)

            Text("Tamamladığın pratik seansları burada görüntülenir.")
                .font(.akorio(13))
                .foregroundColor(.akorioNeutral500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var formattedTotalDuration: String {
        let totalMinutes = statistics.totalDurationSeconds / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: String(localized: "%lld sa %lld dk"), hours, minutes)
        }

        return String(format: String(localized: "%lld dk"), totalMinutes)
    }

    private func formattedDuration(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct HistoryMetric: View {
    let icon: String
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.akorio(15, .semibold))
                .foregroundColor(.akorioAccent400)

            Text(value)
                .font(.akorio(17, .semibold))
                .foregroundColor(.akorioText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(title)
                .font(.akorio(10))
                .foregroundColor(.akorioNeutral500)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 82)
        .akorioCard()
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        PracticeHistoryView(viewModel: AppViewModel())
    }
    .modelContainer(for: [SavedChordSet.self, AppSettings.self, PracticeSession.self], inMemory: true)
}

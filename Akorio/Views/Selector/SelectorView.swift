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
                greetingSection
                if viewModel.hasLastPracticeSession {
                    continueSection
                }
                levelSection
            }
            .padding(20)
            .akorioContentWidth()
        }
        // On-device iOS 26.x lets a fitting page rubber-band in every
        // direction; only bounce when the content actually overflows.
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .akorioIntegralWidth()
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Text("Akorio")
                .font(.akorioSerif(36, .semibold))
                .foregroundColor(.akorioText)

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
                        .font(.akorio(10, .semibold))
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
        .zIndex(1)
    }

    // MARK: - Greeting
    private var greetingSection: some View {
        ZStack(alignment: .leading) {
            LinearGradient(
                colors: [Color.akorioAccent800, Color.akorioNeutral900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.clear
                .overlay(
                    Image("Guitar")
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
                .allowsHitTesting(false)
                .opacity(0.5)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.3),
                            .init(color: .black, location: 0.65),
                            .init(color: .black, location: 1),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Merhaba! 👋")
                    .font(.akorioSerif(26, .semibold))
                    .foregroundColor(.akorioText)
                Text("Düzenli pratik yap, gelişimini gör.")
                    .font(.akorio(14))
                    .foregroundColor(.akorioAccent200.opacity(0.85))
            }
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: AkorioRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: AkorioRadius.lg)
                .stroke(Color.akorioStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 8)
    }

    // MARK: - Continue last practice
    private var continueSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("KALDIĞIN YERDEN DEVAM ET")
                .sectionHeaderStyle()

            Button {
                viewModel.continueLastPractice()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.akorioAccent900)
                        Circle()
                            .fill(Color.akorioAccent500.opacity(0.5))
                            .frame(width: 26, height: 26)
                            .blur(radius: 12)
                        Image(systemName: "play.fill")
                            .font(.akorio(16, .medium))
                            .foregroundColor(.akorioAccent200)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Son Pratik Seansı")
                            .font(.akorio(16, .medium))
                            .foregroundColor(.akorioText)
                        Text(viewModel.lastPracticeSubtitle)
                            .font(.akorio(13))
                            .foregroundColor(.akorioNeutral500)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.akorio(14))
                        .foregroundColor(.akorioNeutral500)
                }
                .akorioCard()
            }
            .buttonStyle(AkorioPressableCardStyle())
        }
    }

    // MARK: - Level picker
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SEVİYE SEÇ")
                .sectionHeaderStyle()

            VStack(spacing: 10) {
                ForEach(ChordLevel.allCases, id: \.self) { level in
                    LevelRow(level: level) {
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.akorioAccent900)
                    Image(systemName: level.icon)
                        .font(.akorio(18, .medium))
                        .foregroundColor(.akorioAccent200)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.akorio(16, .medium))
                        .foregroundColor(.akorioText)
                    Text(level.subtitle)
                        .font(.akorio(13))
                        .foregroundColor(.akorioNeutral500)
                }
                Spacer()
                Text(String(format: String(localized: "%@ akor"), "\(level.chordLabels.count)"))
                    .font(.akorio(12, .medium))
                    .foregroundColor(.akorioNeutral500)
                Image(systemName: "chevron.right")
                    .font(.akorio(14))
                    .foregroundColor(.akorioNeutral500)
            }
            .akorioCard()
        }
        .buttonStyle(AkorioPressableCardStyle())
    }
}

// MARK: - Section header text style
private extension Text {
    func sectionHeaderStyle() -> some View {
        self
            .font(.akorio(11, .medium))
            .tracking(0.6)
            .foregroundColor(.akorioNeutral500)
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        SelectorView(viewModel: AppViewModel())
    }
    .modelContainer(for: [SavedChordSet.self, AppSettings.self], inMemory: true)
}

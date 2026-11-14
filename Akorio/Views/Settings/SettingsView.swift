//
//  SettingsView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    let viewModel: AppViewModel

    @State private var showMailCompose = false
    @State private var isSoundPickerOpen = false

    private var settings: SettingsStore { viewModel.settings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                metronomeSection
                    .zIndex(1)
                defaultPracticeSection
                aboutSection
            }
            .padding(20)
            .akorioContentWidth()
        }
        .scrollBounceBehavior(.basedOnSize, axes: [.vertical, .horizontal])
        .akorioIntegralWidth()
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipient: "aricibegum@gmail.com",
                subject: String(localized: "Akorio Geri Bildirim")
            )
            .ignoresSafeArea()
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

            Text("Ayarlar")
                .font(.akorioSerif(24, .semibold))
                .foregroundColor(.akorioText)
        }
    }

    // MARK: - Metronome
    private var metronomeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("METRONOM").sectionHeaderStyle()

            soundPicker

            HStack {
                Text("Haptik geri bildirim").foregroundColor(.akorioText)
                Spacer()
                AkorioToggle(isOn: settings.hapticEnabled) { settings.toggleHaptic() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)
            .cornerRadius(AkorioRadius.md)
        }
    }

    private var soundPicker: some View {
        Button {
            isSoundPickerOpen.toggle()
        } label: {
            HStack {
                Text("Metronom sesi")
                    .foregroundColor(.akorioText)
                Spacer()
                Text(settings.metronomeSound.label)
                    .foregroundColor(.akorioAccent300)
                Image(systemName: "chevron.down")
                    .font(.akorio(10))
                    .foregroundColor(.akorioNeutral500)
            }
            .font(.akorio(14))
            .padding(14)
        }
        .buttonStyle(.plain)
        .background(Color.akorioSurface)
        .cornerRadius(AkorioRadius.md)
        .overlay(alignment: .top) {
            if isSoundPickerOpen {
                VStack(spacing: 0) {
                    ForEach(MetronomeSound.allCases, id: \.self) { sound in
                        Button {
                            settings.selectMetronomeSound(sound)
                            isSoundPickerOpen = false
                        } label: {
                            HStack {
                                Text(sound.label)
                                    .foregroundColor(sound == settings.metronomeSound ? .akorioAccent100 : .akorioText)
                                Spacer()
                            }
                            .font(.akorio(14))
                            .padding(14)
                            .background(sound == settings.metronomeSound ? Color.akorioAccent800 : Color.akorioSurface)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(AkorioRadius.md)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                .offset(y: 48)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .zIndex(1)
        .akorioAnimation(.spring(response: 0.3, dampingFraction: 1.0), value: isSoundPickerOpen)
    }

    // MARK: - Default practice settings
    private var defaultPracticeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VARSAYILAN PRATİK AYARLARI").sectionHeaderStyle()

            HStack(spacing: 10) {
                AkorioStatBox(
                    title: String(localized: "BPM"),
                    value: settings.defaultBpm,
                    onDecrement: { settings.changeDefaultBpm(by: -1) },
                    onIncrement: { settings.changeDefaultBpm(by: 1) }
                )
                AkorioStatBox(
                    title: String(localized: "Vuruş/Akor"),
                    value: settings.defaultBeatsPerChord,
                    onDecrement: { settings.changeDefaultBeatsPerChord(by: -1) },
                    onIncrement: { settings.changeDefaultBeatsPerChord(by: 1) }
                )
            }

            Text("Yeni bir pratik oturumu bu değerlerle başlar.")
                .font(.akorio(12))
                .foregroundColor(.akorioNeutral500)
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HAKKINDA").sectionHeaderStyle()

            VStack(spacing: 1) {
                HStack {
                    Text("Versiyon").foregroundColor(.akorioText)
                    Spacer()
                    Text(appVersionDisplayString).foregroundColor(.akorioNeutral500)
                }
                .font(.akorio(14))
                .padding(14)
                .background(Color.akorioSurface)

                Button {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        Text("Dil").foregroundColor(.akorioText)
                        Spacer()
                        Text(currentLanguageDisplayName).foregroundColor(.akorioNeutral500)
                        Text("›").foregroundColor(.akorioNeutral500)
                    }
                    .font(.akorio(14))
                    .padding(14)
                    .background(Color.akorioSurface)
                }
                .buttonStyle(.plain)

                feedbackRow

                Button {
                    viewModel.appStoreReviewRequestWasHandled()
                    guard let url = URL(
                        string: "https://apps.apple.com/app/id6794922746?action=write-review"
                    ) else { return }
                    UIApplication.shared.open(url)
                } label: {
                    HStack {
                        Text("Akorio'yu Değerlendir").foregroundColor(.akorioText)
                        Spacer()
                        Text("›").foregroundColor(.akorioNeutral500)
                    }
                    .font(.akorio(14))
                    .padding(14)
                    .background(Color.akorioSurface)
                }
                .buttonStyle(.plain)

                Link(destination: URL(string: "https://begumarici.github.io/akorio-privacy-policy")!) {
                    HStack {
                        Text("Gizlilik Politikası").foregroundColor(.akorioText)
                        Spacer()
                        Text("›").foregroundColor(.akorioNeutral500)
                    }
                    .font(.akorio(14))
                    .padding(14)
                    .background(Color.akorioSurface)
                }
            }
            .cornerRadius(AkorioRadius.md)
        }
    }

    private var feedbackRow: some View {
        Group {
            if MailComposeView.canSend {
                Button {
                    showMailCompose = true
                } label: {
                    feedbackRowLabel
                }
                .buttonStyle(.plain)
            } else {
                let subject = String(localized: "Akorio Geri Bildirim")
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Akorio"
                Link(destination: URL(string: "mailto:aricibegum@gmail.com?subject=\(subject)")!) {
                    feedbackRowLabel
                }
            }
        }
    }

    private var feedbackRowLabel: some View {
        HStack {
            Text("Geri bildirim gönder")
                .foregroundColor(.akorioText)
            Spacer()
            Text("›").foregroundColor(.akorioNeutral500)
        }
        .font(.akorio(14))
        .padding(14)
        .background(Color.akorioSurface)
    }

    private var currentLanguageDisplayName: String {
        guard let code = Locale.current.language.languageCode?.identifier else { return "" }
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? ""
    }

    private var appVersionDisplayString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}

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
        SettingsView(viewModel: AppViewModel())
    }
}

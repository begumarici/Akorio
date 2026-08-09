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
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.goBack()
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
                AkorioToggle(isOn: viewModel.hapticEnabled) { viewModel.toggleHaptic() }
            }
            .font(.akorio(14))
            .padding(14)
            .background(Color.akorioSurface)
            .cornerRadius(AkorioRadius.md)
        }
    }

    private var soundPicker: some View {
        Button {
            viewModel.toggleSoundPicker()
        } label: {
            HStack {
                Text("Metronom sesi")
                    .foregroundColor(.akorioText)
                Spacer()
                Text(viewModel.metronomeSound.label)
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
            if viewModel.soundPickerOpen {
                VStack(spacing: 0) {
                    ForEach(MetronomeSound.allCases, id: \.self) { sound in
                        Button {
                            viewModel.selectMetronomeSound(sound)
                        } label: {
                            HStack {
                                Text(sound.label)
                                    .foregroundColor(sound == viewModel.metronomeSound ? .akorioAccent100 : .akorioText)
                                Spacer()
                            }
                            .font(.akorio(14))
                            .padding(14)
                            .background(sound == viewModel.metronomeSound ? Color.akorioAccent800 : Color.akorioSurface)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .cornerRadius(AkorioRadius.md)
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
                .offset(y: 48)
            }
        }
        .zIndex(1)
    }

    // MARK: - Default practice settings
    private var defaultPracticeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VARSAYILAN PRATİK AYARLARI").sectionHeaderStyle()

            HStack(spacing: 10) {
                AkorioStatBox(title: String(localized: "BPM"), value: viewModel.defaultBpm, onDecrement: viewModel.decDefaultBpm, onIncrement: viewModel.incDefaultBpm)
                AkorioStatBox(title: String(localized: "Vuruş/Akor"), value: viewModel.defaultBeatsPerChord, onDecrement: viewModel.decDefaultBeats, onIncrement: viewModel.incDefaultBeats)
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
                    Text("1.0.0").foregroundColor(.akorioNeutral500)
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

                Link(destination: URL(string: "mailto:aricibegum@gmail.com?subject=Akorio%20Geri%20Bildirim")!) {
                    HStack {
                        Text("Geri bildirim gönder / Değerlendir")
                            .foregroundColor(.akorioText)
                        Spacer()
                        Text("›").foregroundColor(.akorioNeutral500)
                    }
                    .font(.akorio(14))
                    .padding(14)
                    .background(Color.akorioSurface)
                }

                HStack {
                    Text("Gizlilik Politikası").foregroundColor(.akorioText)
                    Spacer()
                    Text("›").foregroundColor(.akorioNeutral500)
                }
                .font(.akorio(14))
                .padding(14)
                .background(Color.akorioSurface)
            }
            .cornerRadius(AkorioRadius.md)
        }
    }

    private var currentLanguageDisplayName: String {
        guard let code = Locale.current.language.languageCode?.identifier else { return "" }
        return Locale.current.localizedString(forLanguageCode: code)?.capitalized ?? ""
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

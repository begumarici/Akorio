//
//  ContentView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = AppViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            homeTab
                .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                .tag(AppTab.home)

            tunerTab
                .tabItem { Label("Akort Aleti", systemImage: "tuningfork") }
                .tag(AppTab.tuner)
        }
        .tint(.akorioAccent400)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.configure(context: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Backgrounding tears down the audio session's IO cycle; if the
            // metronome timer fires after that, AVAudioPlayerNode.play()
            // throws an uncaught NSException and crashes the app. Stop the
            // session the moment we leave the foreground.
            if newPhase != .active {
                viewModel.metronome.stop()
            }
        }
    }

    private var homeTab: some View {
        NavigationStack(path: $viewModel.path) {
            ZStack {
                AkorioBackground()
                SelectorView(viewModel: viewModel)
            }
            .toolbar(.hidden, for: .navigationBar)
            .enableSwipeBack()
            .navigationDestination(for: AppScreen.self) { screen in
                ZStack {
                    AkorioBackground()
                    switch screen {
                    case .saved:
                        SavedSetsView(viewModel: viewModel)
                    case .practice:
                        PracticeView(viewModel: viewModel)
                    case .settings:
                        SettingsView(viewModel: viewModel)
                    case .levelDetail(let level):
                        LevelDetailView(viewModel: viewModel, level: level)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private var tunerTab: some View {
        NavigationStack {
            ZStack {
                AkorioBackground()
                TunerView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedChordSet.self, AppSettings.self], inMemory: true)
}

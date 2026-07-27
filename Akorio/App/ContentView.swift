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
        NavigationStack(path: $viewModel.path) {
            ZStack {
                Color.akorioBg.ignoresSafeArea()
                SelectorView(viewModel: viewModel)
            }
            .toolbar(.hidden, for: .navigationBar)
            .enableSwipeBack()
            .navigationDestination(for: AppScreen.self) { screen in
                ZStack {
                    Color.akorioBg.ignoresSafeArea()
                    switch screen {
                    case .saved:
                        SavedSetsView(viewModel: viewModel)
                    case .practice:
                        PracticeView(viewModel: viewModel)
                    case .settings:
                        SettingsView(viewModel: viewModel)
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
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
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedChordSet.self, AppSettings.self], inMemory: true)
}

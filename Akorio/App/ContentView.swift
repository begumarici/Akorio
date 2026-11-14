//
//  ContentView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData
import StoreKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @State private var viewModel = AppViewModel()

    var body: some View {
        @Bindable var router = viewModel.router
        return ZStack {
            TabView(selection: $router.selectedTab) {
                homeTab
                    .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                    .tag(AppTab.home)

                libraryTab
                    .tabItem { Label("Kütüphane", systemImage: "books.vertical.fill") }
                    .tag(AppTab.library)

                tunerTab
                    .tabItem { Label("Akort Aleti", systemImage: "tuningfork") }
                    .tag(AppTab.tuner)
            }
            .tint(.akorioAccent400)

            if viewModel.isPracticePresented {
                PracticeFlowView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background {
                        AkorioBackground()
                            .ignoresSafeArea()
                    }
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .animation(
            .easeInOut(duration: 0.28),
            value: viewModel.isPracticePresented
        )
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.configure(context: modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.metronome.stop()
            }
        }
        .onChange(of: viewModel.shouldRequestReview) { _, shouldRequestReview in
            guard shouldRequestReview else { return }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(800))
                guard viewModel.shouldRequestReview else { return }
                requestReview()
                viewModel.appStoreReviewRequestWasHandled()
            }
        }
    }

    private var homeTab: some View {
        @Bindable var router = viewModel.router
        return NavigationStack(path: $router.path) {
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
                    case .practiceHistory:
                        PracticeHistoryView(viewModel: viewModel)
                    case .settings:
                        SettingsView(viewModel: viewModel)
                    case .levelDetail(let level):
                        LevelDetailView(viewModel: viewModel, level: level)
                    case .practicePlan:
                        PracticePlanView(
                            viewModel: viewModel,
                            onBack: viewModel.cancelPracticePlan,
                            onStart: viewModel.startPracticeFromPlan
                        )
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    private var libraryTab: some View {
        NavigationStack {
            ZStack {
                AkorioBackground()
                LibraryView()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var tunerTab: some View {
        NavigationStack {
            ZStack {
                AkorioBackground()
                TunerView(viewModel: viewModel)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedChordSet.self, AppSettings.self, PracticeSession.self], inMemory: true)
}

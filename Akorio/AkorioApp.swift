//
//  AkorioApp.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import SwiftData

@main
struct AkorioApp: App {
    init() {
        AkorioFont.registerAll()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedChordSet.self,
            AppSettings.self,
            PracticeSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    @State private var showSplash = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            ContentView()
                // Prevent accidental taps during splash
                .allowsHitTesting(!showSplash)
                .opacity(showSplash ? 0.98 : 1.0)

            if showSplash {
                SplashView()
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 1.02)),
                        removal: .opacity.combined(with: .scale(scale: 0.98))
                    ))
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: reduceMotion ? 0.2 : 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

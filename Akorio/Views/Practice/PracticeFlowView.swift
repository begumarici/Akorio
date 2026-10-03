//
//  PracticeFlowView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 29.09.2026.
//

import SwiftUI

private enum PracticeFlowScreen: Hashable {
    case summary
}

struct PracticeFlowView: View {
    @Bindable var viewModel: AppViewModel
    @State private var path: [PracticeFlowScreen] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                AkorioBackground()
                PracticeView(viewModel: viewModel)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PracticeFlowScreen.self) { screen in
                switch screen {
                case .summary:
                    if let summary = viewModel.currentPracticeSummary {
                        ZStack {
                            AkorioBackground()

                            PracticeSummaryView(
                                summary: summary,
                                onRepeat: repeatPractice,
                                onReturnHome: viewModel.returnHomeFromPracticeSummary
                            )
                        }
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
            }
            .onChange(of: viewModel.currentPracticeSummary) { _, summary in
                guard summary != nil else { return }

                if path.last != .summary {
                    path.append(.summary)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func repeatPractice() {
        viewModel.repeatPracticeSession()
        path = []
    }
}

//
//  SwipeBackEnabler.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import UIKit

/// Hiding the navigation bar's back button (`.toolbar(.hidden, for: .navigationBar)`)
/// also disables UIKit's edge-swipe-to-go-back gesture, since it normally
/// depends on that back button existing. This re-enables it directly on the
/// underlying `UINavigationController`.
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            guard let navigationController = uiViewController.parent?.navigationController else { return }
            navigationController.interactivePopGestureRecognizer?.delegate = nil
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

extension View {
    /// Restores the native edge-swipe-back gesture on a hidden-navigation-bar
    /// `NavigationStack`.
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler())
    }
}

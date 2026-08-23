//
//  Haptics.swift
//  Akorio
//
//  Created by Begüm Arıcı on 19.08.2026.
//

import UIKit

enum AkorioHaptics {
    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let notification = UINotificationFeedbackGenerator()
    private static let selectionGenerator = UISelectionFeedbackGenerator()

    static func impact(enabled: Bool) {
        guard enabled else { return }
        lightImpact.impactOccurred()
    }

    static func success(enabled: Bool) {
        guard enabled else { return }
        notification.notificationOccurred(.success)
    }

    static func selection(enabled: Bool) {
        guard enabled else { return }
        selectionGenerator.selectionChanged()
    }
}

//
//  Motion.swift
//  Akorio
//
//  Created by Begüm Arıcı on 19.08.2026.
//

import SwiftUI

extension View {
    /// `.animation(_:value:)`, but collapses to a short linear fade when the
    /// user has Reduce Motion on — springs and slides become a plain
    /// cross-fade instead of turning off feedback entirely.
    func akorioAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        modifier(AkorioAnimationModifier(animation: animation, value: value))
    }
}

private struct AkorioAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .linear(duration: 0.1) : animation, value: value)
    }
}

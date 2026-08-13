//
//  AkorioToggle.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// A pill-shaped on/off switch, used in Practice and Settings rows
/// (count-in, metronome sound, haptic feedback).
struct AkorioToggle: View {
    let isOn: Bool
    var onToggle: () -> Void

    private let width: CGFloat = 44
    private let height: CGFloat = 26
    private let knobSize: CGFloat = 22
    private let knobInset: CGFloat = 2

    var body: some View {
        Button(action: onToggle) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? Color.akorioAccent500 : Color.akorioNeutral700)
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .padding(knobInset)
            }
        }
        .buttonStyle(.plain)
        .frame(width: width, height: height)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOn)
    }
}

#Preview {
    ZStack {
        AkorioBackground()
        VStack(spacing: 20) {
            AkorioToggle(isOn: true) {}
            AkorioToggle(isOn: false) {}
        }
    }
}

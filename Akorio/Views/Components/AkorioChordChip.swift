//
//  AkorioChordChip.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// A single selected chord shown as a pill: drag handle, label, remove button.
/// Reordering itself (drag source / drop target) is wired up where this chip
/// is placed in a list, not inside the chip itself.
struct AkorioChordChip: View {
    let label: String
    var onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            dragHandle
            Text(label)
                .font(.system(size: 13, weight: .medium))
            Button(action: onRemove) {
                Text("✕")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .opacity(0.7)
        }
        .foregroundColor(.akorioAccent100)
        .padding(.leading, 10)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(Color.akorioAccent800)
        )
        .overlay(
            Capsule().stroke(Color.akorioAccent600, lineWidth: 1)
        )
    }

    private var dragHandle: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().frame(width: 3, height: 3)
                    Circle().frame(width: 3, height: 3)
                }
            }
        }
        .opacity(0.6)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        HStack {
            AkorioChordChip(label: "C") {}
            AkorioChordChip(label: "Cm") {}
        }
    }
}

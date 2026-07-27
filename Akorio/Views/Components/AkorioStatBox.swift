//
//  AkorioStatBox.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// A labeled numeric stepper card — used for BPM / beats-per-chord, both in
/// the live Practice session and the default values on the Settings screen.
struct AkorioStatBox: View {
    let title: String
    let value: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(0.6)
                .foregroundColor(.akorioNeutral500)
            HStack {
                Button(action: onDecrement) {
                    Text("−").font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(AkorioIconButtonStyle(size: 28))

                Spacer()
                Text("\(value)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.akorioText)
                Spacer()

                Button(action: onIncrement) {
                    Text("+").font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(AkorioIconButtonStyle(size: 28))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.akorioSurface)
        .cornerRadius(AkorioRadius.md)
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        HStack {
            AkorioStatBox(title: "BPM", value: 80, onDecrement: {}, onIncrement: {})
            AkorioStatBox(title: "Vuruş/Akor", value: 4, onDecrement: {}, onIncrement: {})
        }
        .padding(20)
    }
}

//
//  AkorioCard.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// The surface + padding + corner radius shared by card-style rows
/// (saved set rows, BPM/beats stat boxes, list rows).
private struct AkorioCardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(Color.akorioSurface)
            )
    }
}

extension View {
    func akorioCard() -> some View {
        modifier(AkorioCardBackground())
    }
}

#Preview {
    ZStack {
        Color.akorioBg.ignoresSafeArea()
        VStack(alignment: .leading, spacing: 4) {
            Text("Akor Seti 1")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.akorioText)
            Text("Am, G, F, E · 80 BPM")
                .font(.system(size: 13))
                .foregroundColor(.akorioNeutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .akorioCard()
        .padding(20)
    }
}

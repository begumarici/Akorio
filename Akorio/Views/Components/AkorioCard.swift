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
                    .overlay(
                        RoundedRectangle(cornerRadius: AkorioRadius.md)
                            .stroke(Color.akorioStroke, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
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
        AkorioBackground()
        VStack(alignment: .leading, spacing: 4) {
            Text("Akor Seti 1")
                .font(.akorio(16, .medium))
                .foregroundColor(.akorioText)
            Text("Am, G, F, E · 80 BPM")
                .font(.akorio(13))
                .foregroundColor(.akorioNeutral500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .akorioCard()
        .padding(20)
    }
}

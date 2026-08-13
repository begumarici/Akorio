//
//  AkorioButtonStyles.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// Full-width, filled accent button. Used for primary calls to action
/// like "Pratiğe Başla" / "Başlat".
struct AkorioPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.akorio(16, .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(configuration.isPressed ? Color.akorioAccent600 : Color.akorioAccent500)
                    .shadow(color: Color.akorioAccent500.opacity(configuration.isPressed ? 0.15 : 0.35), radius: 14, y: 6)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Filled neutral button. Used for secondary actions like
/// "Kayıtlı Setler", "Kaydet".
struct AkorioSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.akorio(13, .medium))
            .foregroundColor(.akorioText)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? Color.akorioSurfaceHigh : Color.akorioSurface)
            )
            .overlay(
                Capsule()
                    .stroke(Color.akorioStroke, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Fixed-size round icon button. Used for back arrows, the settings gear,
/// and the edit/delete icons on saved set rows.
struct AkorioIconButtonStyle: ButtonStyle {
    var size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.akorioText)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(configuration.isPressed ? Color.akorioSurfaceHigh : Color.akorioSurface)
            )
            .overlay(
                Circle()
                    .stroke(Color.akorioStroke, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// For card-shaped tappable rows (level rows, saved sets, chord cards):
/// a gentle press-down scale instead of the default opacity flash.
struct AkorioPressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

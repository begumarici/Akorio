//
//  AkorioButtonStyles.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// Full-width, outlined accent button. Used for primary calls to action
/// like "Pratiğe Başla" / "Başlat".
struct AkorioPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.akorioAccent300)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(configuration.isPressed ? Color.akorioAccent500.opacity(0.22) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .stroke(Color.akorioAccent500, lineWidth: 1)
            )
    }
}

/// Bordered neutral button. Used for secondary actions like
/// "Kayıtlı Setler", "Kaydet".
struct AkorioSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.akorioText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(configuration.isPressed ? Color.akorioText.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .stroke(Color.akorioDivider, lineWidth: 1)
            )
    }
}

/// Fixed-size square icon button. Used for back arrows, the settings gear,
/// and the edit/delete icons on saved set rows.
struct AkorioIconButtonStyle: ButtonStyle {
    var size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.akorioText)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .fill(configuration.isPressed ? Color.akorioText.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AkorioRadius.md)
                    .stroke(Color.akorioDivider, lineWidth: 1)
            )
    }
}

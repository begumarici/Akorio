//
//  Theme.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static let akBg = Color(hex: 0x161826)
    static let akSurface = Color(hex: 0x232532)

    static let akNeutral100 = Color(hex: 0xf3f5fe)
    static let akNeutral300 = Color(hex: 0xcfd3e5)
    static let akNeutral400 = Color(hex: 0xb2b6ca)
    static let akNeutral500 = Color(hex: 0x9397ab)
    static let akNeutral600 = Color(hex: 0x75798c)
    static let akNeutral700 = Color(hex: 0x595d6c)
    static let akNeutral800 = Color(hex: 0x3f424d)
    static let akNeutral900 = Color(hex: 0x292b31)

    static let akText = Color(hex: 0xe9e9ed)
    static let akDivider = Color.akText.opacity(0.16)

    static let akAccent100 = Color(hex: 0xf5f4ff)
    static let akAccent200 = Color(hex: 0xe7e5fe)
    static let akAccent300 = Color(hex: 0xd2cefd)
    static let akAccent400 = Color(hex: 0xb5abfc)
    static let akAccent500 = Color(hex: 0x968ae0)
    static let akAccent600 = Color(hex: 0x796cbf)
    static let akAccent700 = Color(hex: 0x5d5294)
    static let akAccent800 = Color(hex: 0x423a6a)
    static let akAccent900 = Color(hex: 0x2b2741)
}

enum AkRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 14
}

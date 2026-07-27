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

    static let akorioBg = Color(hex: 0x161826)
    static let akorioSurface = Color(hex: 0x232532)

    static let akorioNeutral100 = Color(hex: 0xf3f5fe)
    static let akorioNeutral300 = Color(hex: 0xcfd3e5)
    static let akorioNeutral400 = Color(hex: 0xb2b6ca)
    static let akorioNeutral500 = Color(hex: 0x9397ab)
    static let akorioNeutral600 = Color(hex: 0x75798c)
    static let akorioNeutral700 = Color(hex: 0x595d6c)
    static let akorioNeutral800 = Color(hex: 0x3f424d)
    static let akorioNeutral900 = Color(hex: 0x292b31)

    static let akorioText = Color(hex: 0xe9e9ed)
    static let akorioDivider = Color.akorioText.opacity(0.16)

    static let akorioAccent100 = Color(hex: 0xf5f4ff)
    static let akorioAccent200 = Color(hex: 0xe7e5fe)
    static let akorioAccent300 = Color(hex: 0xd2cefd)
    static let akorioAccent400 = Color(hex: 0xb5abfc)
    static let akorioAccent500 = Color(hex: 0x968ae0)
    static let akorioAccent600 = Color(hex: 0x796cbf)
    static let akorioAccent700 = Color(hex: 0x5d5294)
    static let akorioAccent800 = Color(hex: 0x423a6a)
    static let akorioAccent900 = Color(hex: 0x2b2741)
}

enum AkorioRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 14
}

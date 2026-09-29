//
//  Theme.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import CoreText
import UIKit

enum AkorioFont {

    static func registerAll() {
        for name in ["InstrumentSerif-Regular"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// Body/UI text — Apple's system font (San Francisco), scaling with the
    /// user's Dynamic Type setting.
    static func akorio(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let base = UIFont.systemFont(ofSize: size, weight: weight.uiKitWeight)
        return Font(UIFontMetrics.default.scaledFont(for: base, maximumPointSize: size * 1.3))
    }

    /// Display/heading text — Instrument Serif, same Dynamic Type scaling
    /// as `akorio`.
    static func akorioSerif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        guard let base = UIFont(name: "InstrumentSerif-Regular", size: size) else {
            return .custom("InstrumentSerif-Regular", size: size)
        }
        return Font(UIFontMetrics.default.scaledFont(for: base, maximumPointSize: size * 1.3))
    }

    static func akorioFixed(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// `akorioSerif`, fixed at its literal point size — see `akorioFixed`.
    static func akorioSerifFixed(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
    }
}

private extension Font.Weight {
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .black: .black
        case .heavy: .heavy
        case .bold: .bold
        case .semibold: .semibold
        case .medium: .medium
        case .light: .light
        case .thin: .thin
        case .ultraLight: .ultraLight
        default: .regular
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }

    static let akorioBg = Color(hex: 0x14120e)
    static let akorioSurface = Color(hex: 0x1f1b15)
    static let akorioSurfaceHigh = Color(hex: 0x2a2419)

    static let akorioNeutral100 = Color(hex: 0xf5f1e9)
    static let akorioNeutral300 = Color(hex: 0xd8d0c2)
    static let akorioNeutral400 = Color(hex: 0xb9af9e)
    static let akorioNeutral500 = Color(hex: 0x968c7b)
    static let akorioNeutral600 = Color(hex: 0x776d5d)
    static let akorioNeutral700 = Color(hex: 0x50493d)
    static let akorioNeutral800 = Color(hex: 0x3f392f)
    static let akorioNeutral900 = Color(hex: 0x2a251e)

    static let akorioText = Color(hex: 0xf3eee3)
    static let akorioDivider = Color.white.opacity(0.08)
    static let akorioStroke = Color.white.opacity(0.07)

    static let akorioAccent100 = Color(hex: 0xfbefdc)
    static let akorioAccent200 = Color(hex: 0xf6ddb0)
    static let akorioAccent300 = Color(hex: 0xeec17a)
    static let akorioAccent400 = Color(hex: 0xe4a24b)
    static let akorioAccent500 = Color(hex: 0xd6862b)
    static let akorioAccent600 = Color(hex: 0xb06b1e)
    static let akorioAccent700 = Color(hex: 0x855018)
    static let akorioAccent800 = Color(hex: 0x543310)
    static let akorioAccent900 = Color(hex: 0x2e1c09)
}


struct AkorioBackground: View {
    var body: some View {
        ZStack {
            Color.akorioBg

            GeometryReader { proxy in
                RadialGradient(
                    colors: [Color.black.opacity(0.35), .clear],
                    center: .center,
                    startRadius: proxy.size.width * 0.3,
                    endRadius: proxy.size.width * 0.9
                )
            }
        }
        .ignoresSafeArea()
    }
}

enum AkorioRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
}

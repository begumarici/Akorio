//
//  Theme.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI
import CoreText

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
    /// Body/UI text — Apple's system font (San Francisco).
    static func akorio(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// Display/heading text — Instrument Serif.
    static func akorioSerif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .custom("InstrumentSerif-Regular", size: size)
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

    static let akorioBg = Color(hex: 0x0f1120)
    static let akorioSurface = Color(hex: 0x1c1f33)
    static let akorioSurfaceHigh = Color(hex: 0x252941)

    static let akorioNeutral100 = Color(hex: 0xf3f5fe)
    static let akorioNeutral300 = Color(hex: 0xcfd3e5)
    static let akorioNeutral400 = Color(hex: 0xb2b6ca)
    static let akorioNeutral500 = Color(hex: 0x9397ab)
    static let akorioNeutral600 = Color(hex: 0x75798c)
    static let akorioNeutral700 = Color(hex: 0x4c5065)
    static let akorioNeutral800 = Color(hex: 0x3f424d)
    static let akorioNeutral900 = Color(hex: 0x292b31)

    static let akorioText = Color(hex: 0xeceef6)
    static let akorioDivider = Color.white.opacity(0.08)
    static let akorioStroke = Color.white.opacity(0.07)

    static let akorioAccent100 = Color(hex: 0xf5f4ff)
    static let akorioAccent200 = Color(hex: 0xe7e5fe)
    static let akorioAccent300 = Color(hex: 0xd2cefd)
    static let akorioAccent400 = Color(hex: 0xaea0fb)
    static let akorioAccent500 = Color(hex: 0x8b7af3)
    static let akorioAccent600 = Color(hex: 0x6f5fd8)
    static let akorioAccent700 = Color(hex: 0x5a4daf)
    static let akorioAccent800 = Color(hex: 0x3d3577)
    static let akorioAccent900 = Color(hex: 0x272346)
}


struct AkorioBackground: View {
    var body: some View {
        ZStack {
            Color.akorioBg

            GeometryReader { proxy in
                ZStack {
                    Circle()
                        .fill(Color.akorioAccent600.opacity(0.4))
                        .frame(width: 320, height: 320)
                        .blur(radius: 110)
                        .position(x: proxy.size.width * 0.15, y: -60)

                    Circle()
                        .fill(Color(hex: 0x4a5fd0).opacity(0.3))
                        .frame(width: 280, height: 280)
                        .blur(radius: 110)
                        .position(x: proxy.size.width * 0.9, y: 40)

                    Circle()
                        .fill(Color(hex: 0x7b3f8f).opacity(0.16))
                        .frame(width: 300, height: 300)
                        .blur(radius: 120)
                        .position(x: proxy.size.width * 0.7, y: proxy.size.height * 0.95)
                }
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

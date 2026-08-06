//
//  ChordLevel.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation

/// A curated practice level — each one has its own fixed chord list.
enum ChordLevel: String, CaseIterable, Hashable {
    case beginner
    case intermediate
    case advanced
    case expert

    var tabTitle: String {
        switch self {
        case .beginner: return String(localized: "Giriş")
        case .intermediate: return String(localized: "Orta")
        case .advanced: return String(localized: "Zor")
        case .expert: return String(localized: "İleri")
        }
    }

    var title: String {
        switch self {
        case .beginner: return String(localized: "Giriş Seviyesi")
        case .intermediate: return String(localized: "Orta Seviye")
        case .advanced: return String(localized: "Zor Seviye")
        case .expert: return String(localized: "İleri Seviye")
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return String(localized: "Başlangıç için en temel akorlar")
        case .intermediate: return String(localized: "Bilgini genişlet, yeni akorlar ekle")
        case .advanced: return String(localized: "Daha zorlu akorlar ve geçişler")
        case .expert: return String(localized: "Tüm akorlar, sınırlarını zorla")
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "target"
        case .intermediate: return "moon.stars.fill"
        case .advanced: return "flame.fill"
        case .expert: return "flag.checkered"
        }
    }

    var chordLabels: [String] {
        let beginner = ["Am", "Em", "Dm"]
        let intermediate = beginner + ["C", "G", "D", "A"]
        let advanced = intermediate + ["E", "F", "B", "Bm", "F#m"]
        let expert = akorioRootNotes.flatMap { [$0, $0 + "m"] }

        switch self {
        case .beginner: return beginner
        case .intermediate: return intermediate
        case .advanced: return advanced
        case .expert: return expert
        }
    }
}

//
//  SavedChordSet.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import Foundation
import SwiftData

@Model
final class SavedChordSet {
    var id: UUID
    var name: String
    var chordLabels: [String]
    var bpm: Int
    var beatsPerChord: Int
    var orderModeRaw: String
    var countInEnabled: Bool
    var metronomeSoundEnabled: Bool
    var createdAt: Date

    init(
        name: String,
        chordLabels: [String],
        bpm: Int,
        beatsPerChord: Int,
        orderMode: OrderMode,
        countInEnabled: Bool,
        metronomeSoundEnabled: Bool
    ) {
        self.id = UUID()
        self.name = name
        self.chordLabels = chordLabels
        self.bpm = bpm
        self.beatsPerChord = beatsPerChord
        self.orderModeRaw = orderMode.rawValue
        self.countInEnabled = countInEnabled
        self.metronomeSoundEnabled = metronomeSoundEnabled
        self.createdAt = Date()
    }

    var orderMode: OrderMode {
        get { OrderMode(rawValue: orderModeRaw) ?? .sequential }
        set { orderModeRaw = newValue.rawValue }
    }

    var subtitle: String {
        let chordsPart = chordLabels.isEmpty ? "—" : chordLabels.joined(separator: ", ")
        return "\(chordsPart) · \(bpm) BPM"
    }
}

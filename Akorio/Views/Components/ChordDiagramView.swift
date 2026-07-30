//
//  ChordDiagramView.swift
//  Akorio
//
//  Created by Begüm Arıcı on 26.07.2026.
//

import SwiftUI

/// A guitar fretboard diagram — six strings, a few frets, dots for finger
/// positions, and ×/○ markers for muted/open strings. Deliberately drawn
/// on a light card (not the app's dark surface) because that's how chord
/// charts read: black ink on paper, regardless of the app's own theme.
struct ChordDiagramView: View {
    let shape: ChordShape

    private let stringCount = 6
    private let fretCount = 4
    private let gridSize = CGSize(width: 84, height: 76)
    private let dotRadius: CGFloat = 5
    private let markerRowHeight: CGFloat = 14

    /// Both the grid lines and the ×/○ markers use this for a string's x
    /// position, so they always line up — inset by `dotRadius` on each
    /// side so the outer two strings' dots aren't clipped by the frame.
    private func stringX(_ index: Int, in width: CGFloat) -> CGFloat {
        let usableWidth = width - dotRadius * 2
        return dotRadius + CGFloat(index) * usableWidth / CGFloat(stringCount - 1)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if shape.baseFret > 1 {
                Text("\(shape.baseFret)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(.top, markerRowHeight + 6)
            }

            VStack(spacing: 4) {
                markerRow
                Canvas { context, size in
                    drawGrid(context: context, size: size)
                    drawDots(context: context, size: size)
                }
                .frame(width: gridSize.width, height: gridSize.height)
            }
        }
    }

    private var markerRow: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<stringCount, id: \.self) { index in
                Text(marker(for: index))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.black.opacity(0.55))
                    .position(x: stringX(index, in: gridSize.width), y: markerRowHeight / 2)
            }
        }
        .frame(width: gridSize.width, height: markerRowHeight)
    }

    private func marker(for stringIndex: Int) -> String {
        guard let fret = shape.frets[stringIndex] else { return "×" }
        return fret == 0 ? "○" : ""
    }

    private func drawGrid(context: GraphicsContext, size: CGSize) {
        let fretSpacing = size.height / CGFloat(fretCount)

        for i in 0..<stringCount {
            let x = stringX(i, in: size.width)
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.black.opacity(0.7)), lineWidth: 1)
        }

        let left = stringX(0, in: size.width)
        let right = stringX(stringCount - 1, in: size.width)
        for i in 0...fretCount {
            let y = CGFloat(i) * fretSpacing
            var path = Path()
            path.move(to: CGPoint(x: left, y: y))
            path.addLine(to: CGPoint(x: right, y: y))
            let isNut = i == 0 && shape.baseFret == 1
            context.stroke(path, with: .color(.black.opacity(0.7)), lineWidth: isNut ? 3 : 1)
        }
    }

    private func drawDots(context: GraphicsContext, size: CGSize) {
        let fretSpacing = size.height / CGFloat(fretCount)

        for (index, fret) in shape.frets.enumerated() {
            guard let fret, fret > 0 else { continue }
            let relativeFret = fret - shape.baseFret + 1
            guard relativeFret >= 1, relativeFret <= fretCount else { continue }

            let x = stringX(index, in: size.width)
            let y = (CGFloat(relativeFret) - 0.5) * fretSpacing
            let rect = CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(.black))
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ChordDiagramView(shape: ChordShapeLibrary.shape(for: "Am"))
        ChordDiagramView(shape: ChordShapeLibrary.shape(for: "F"))
        ChordDiagramView(shape: ChordShapeLibrary.shape(for: "F#m"))
    }
    .padding()
    .background(Color.white)
}

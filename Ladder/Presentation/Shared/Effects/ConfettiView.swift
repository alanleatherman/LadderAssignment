//
//  ConfettiView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/19/25.
//

import SwiftUI

struct ConfettiView: View {
    @State private var isAnimating = false

    let particleCount = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiPiece(
                        geometry: geometry,
                        index: index,
                        isAnimating: isAnimating
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ConfettiPiece: View {
    let geometry: GeometryProxy
    let index: Int
    let isAnimating: Bool

    @State private var yOffset: CGFloat = 0
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    private let color: Color
    private let size: CGFloat
    private let shapeType: Int
    private let startX: CGFloat
    private let delay: Double
    private let duration: Double

    init(geometry: GeometryProxy, index: Int, isAnimating: Bool) {
        self.geometry = geometry
        self.index = index
        self.isAnimating = isAnimating

        // Pre-compute random values in init
        self.color = [Color.ladderPrimary, .red, .blue, .green, .orange, .pink, .purple].randomElement() ?? .ladderPrimary
        self.size = CGFloat.random(in: 8...16)
        self.shapeType = Int.random(in: 0...2)
        self.startX = CGFloat.random(in: 0...geometry.size.width)
        self.delay = Double.random(in: 0...0.3)
        self.duration = Double.random(in: 2.5...4.0)
    }

    @ViewBuilder
    private var shape: some View {
        switch shapeType {
        case 0:
            Circle()
                .fill(color)
        case 1:
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
        default:
            Capsule()
                .fill(color)
        }
    }

    var body: some View {
        shape
            .frame(width: size, height: size)
            .offset(x: startX + xOffset, y: -50 + yOffset)
            .rotationEffect(Angle(degrees: rotation))
            .opacity(opacity)
            .onAppear {
                let finalYOffset = geometry.size.height + 100
                let finalXOffset = CGFloat.random(in: -100...100)
                let finalRotation = Double.random(in: 360...1080)

                withAnimation(
                    .easeIn(duration: duration)
                    .delay(delay)
                ) {
                    yOffset = finalYOffset
                    xOffset = finalXOffset
                    rotation = finalRotation
                    opacity = 0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ConfettiView()
    }
}

//
//  ButtonStyles.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/19/25.
//

import SwiftUI

// Custom button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

#Preview {
    Button("Tap Me") {
        print("Button tapped")
    }
    .buttonStyle(ScaleButtonStyle())
    .padding()
}

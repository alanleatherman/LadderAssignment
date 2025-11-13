//
//  View+Extensions.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

extension View {
    /// Applies a card-style modifier with rounded corners and shadow
    func cardStyle() -> some View {
        self.modifier(CardStyleModifier())
    }
}

struct CardStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

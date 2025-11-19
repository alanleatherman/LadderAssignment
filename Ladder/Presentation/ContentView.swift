//
//  ContentView.swift
//  Ladder
//
//  Created by Andrew Hulsizer on 11/20/24.
//

import SwiftUI
import Creed_Lite
import Dependencies


struct ContentView: View {
    
    @Dependency(\.featsClient) var featsClient
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

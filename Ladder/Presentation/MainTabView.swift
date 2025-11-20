//
//  MainTabView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/19/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            FeatsHomeView()
                .tabItem {
                    Label("Feats", systemImage: "figure.run")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(Color.ladderPrimary)
    }
}

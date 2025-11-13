//
//  MonthHeaderView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct MonthHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            /*
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.primary)
             */
            Text(subtitle)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .padding(.bottom, 8)
    }
}

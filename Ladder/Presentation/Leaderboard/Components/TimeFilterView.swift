//
//  TimeFilterView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct TimeFilterView: View {
    let selectedFilter: TimeFilter
    let onFilterChange: (TimeFilter) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        onFilterChange(filter)
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(
                            selectedFilter == filter ? .primary : .secondary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedFilter == filter ?
                                Color(uiColor: .systemBackground) : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color(uiColor: .systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

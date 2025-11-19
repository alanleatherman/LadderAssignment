//
//  TimeInterval+Formatting.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation

extension TimeInterval {
    /// Formats the time interval as MM:SS
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Formats the time interval as HH:MM:SS
    var formattedLongTime: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        let seconds = Int(self) % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}

//
//  Feat+Duration.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/18/25.
//

import Foundation
import Creed_Lite

extension Feat {
    /// Extracts the duration from the feat name (e.g., "1 MIN PUSH-UPS" -> "1 min")
    /// Falls back to "5 min" if no duration is found in the name
    var durationText: String {
        let name = self.name.uppercased()

        // Look for patterns like "1 MIN", "2 MIN", "5 MIN", etc.
        if let match = name.range(of: #"\d+\s*MIN"#, options: .regularExpression) {
            let durationPart = name[match]
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            return durationPart.lowercased()
        }

        // Fall back to 5 min as default
        return "5 min"
    }

    /// Returns the duration in minutes as an integer
    var durationMinutes: Int {
        let name = self.name.uppercased()

        if let match = name.range(of: #"\d+"#, options: .regularExpression) {
            let numberString = String(name[match])
            return Int(numberString) ?? 5
        }

        return 5
    }
}

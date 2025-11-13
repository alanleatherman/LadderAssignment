//
//  ProcessInfo+Extensions.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import Foundation

extension ProcessInfo {
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}

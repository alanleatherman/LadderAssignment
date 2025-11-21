//
//  NetworkError.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/21/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case noInternet
    case timeout
    case serverError(Int)
    case decodingError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverError(let code):
            return "Server Error (\(code))"
        case .decodingError:
            return "Data Format Error"
        case .unknown:
            return "Something Went Wrong"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Check your internet connection and try again."
        case .timeout:
            return "The request took too long. Please try again."
        case .serverError:
            return "Our servers are having issues. Please try again later."
        case .decodingError:
            return "We received unexpected data. Please try again."
        case .unknown:
            return "Please try again or contact support if this persists."
        }
    }

    var icon: String {
        switch self {
        case .noInternet:
            return "wifi.slash"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .serverError:
            return "server.rack"
        case .decodingError:
            return "doc.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    var canRetry: Bool {
        switch self {
        case .noInternet, .timeout, .serverError:
            return true
        case .decodingError, .unknown:
            return true
        }
    }
}

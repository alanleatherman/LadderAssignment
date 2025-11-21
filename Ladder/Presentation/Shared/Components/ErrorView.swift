//
//  ErrorView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    private var networkError: NetworkError {
        if let netError = error as? NetworkError {
            return netError
        }
        return .unknown(error)
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: networkError.icon)
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .symbolEffect(.bounce, value: error.localizedDescription)

            VStack(spacing: 8) {
                Text(networkError.localizedDescription)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                if let suggestion = networkError.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                if networkError.canRetry {
                    Button {
                        retryAction()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                if case .noInternet = networkError {
                    Button {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    } label: {
                        Text("Open Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("No Internet") {
    ErrorView(
        error: NetworkError.noInternet,
        retryAction: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Server Error") {
    ErrorView(
        error: NetworkError.serverError(500),
        retryAction: {}
    )
    .preferredColorScheme(.dark)
}

#Preview("Timeout") {
    ErrorView(
        error: NetworkError.timeout,
        retryAction: {}
    )
    .preferredColorScheme(.dark)
}

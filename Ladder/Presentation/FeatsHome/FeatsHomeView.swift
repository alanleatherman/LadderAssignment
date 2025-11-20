//
//  FeatsHomeView.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/12/25.
//

import SwiftUI
import Creed_Lite

struct FeatsHomeView: View {
    @Environment(\.container) private var container
    @Environment(\.appState) private var appState
    @State private var selectedFeat: Feat?

    private var interactor: FeatsInteractorProtocol {
        container.interactors.feats
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if interactor.isLoading {
                loadingView
            } else if let error = interactor.error {
                errorView(error)
            } else if let monthlyFeats = interactor.monthlyFeats {
                pagingContent(monthlyFeats)
            }
        }
        .task {
            await interactor.loadMonthlyFeats()
        }
        .onChange(of: appState.completionTimestamp) { _, _ in
            Task {
                await interactor.loadUserData()
            }
        }
        .sheet(item: $selectedFeat) { feat in
            FeatDetailView(feat: feat)
        }
    }

    @ViewBuilder
    private func pagingContent(_ monthlyFeats: MonthlyFeats) -> some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(monthlyFeats.feats.enumerated()), id: \.element.id) { index, feat in
                        ZStack(alignment: .topLeading) {
                            // Full screen card
                            FeatCardView(
                                feat: feat,
                                isFeatured: index == 0,
                                userBestScore: interactor.getUserBest(for: feat.id),
                                selectedFeat: $selectedFeat
                            )

                            // Header overlay only on first page
                            if index == 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Feats of Strength")
                                        .font(.title.bold())
                                        .foregroundStyle(.white)

                                    Text(monthlyFeats.subtitle)
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 28)
                                .padding(.top, max(geometry.safeAreaInsets.top, 50) + 16)
                                .background(
                                    LinearGradient(
                                        colors: [.black.opacity(0.4), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .offset(y: -20)
                                )
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading feats...")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: FeatsError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await interactor.loadMonthlyFeats()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Previews

#Preview("Feats Home - Loading") {
    FeatsHomeView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.feats.isLoading = true
        }
}

#Preview("Feats Home - Error") {
    FeatsHomeView()
        .inject(.preview)
        .preferredColorScheme(.dark)
        .onAppear {
            AppContainer.preview.interactors.feats.error = .notFound
        }
}

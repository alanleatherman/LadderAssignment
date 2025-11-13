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
    @State private var showFeatDetail = false

    private var interactor: FeatsInteractor {
        container.interactors.feats
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if interactor.isLoading {
                        loadingView
                    } else if let error = interactor.error {
                        errorView(error)
                    } else if let monthlyFeats = interactor.monthlyFeats {
                        featsContent(monthlyFeats)
                    }
                }
                .padding()
            }
            .navigationTitle("Feats of Strength")
            .task {
                await interactor.loadMonthlyFeats()
            }
            .refreshable {
                await interactor.refreshFeats()
            }
        }
    }

    @ViewBuilder
    private func featsContent(_ monthlyFeats: MonthlyFeats) -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            // Month header
            MonthHeaderView(
                title: monthlyFeats.title,
                subtitle: monthlyFeats.subtitle
            )

            // Challenge of the month (featured)
            if let featuredFeat = monthlyFeats.feats.first {
                FeatCardView(feat: featuredFeat,
                             isFeatured: true) {
                    interactor.selectFeat(featuredFeat)
                    showFeatDetail = true
                }
            }

            // Other feats
            ForEach(monthlyFeats.feats.dropFirst(), id: \.id) { feat in
                FeatCardView(feat: feat, isFeatured: false) {
                    interactor.selectFeat(feat)
                    showFeatDetail = true
                }
            }
        }
        .sheet(isPresented: $showFeatDetail) {
            if let feat = interactor.selectedFeat {
                FeatDetailView(feat: feat)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .shimmer()
            }
        }
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

// Shimmer effect for loading
extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

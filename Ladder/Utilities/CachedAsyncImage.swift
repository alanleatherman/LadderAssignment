//
//  CachedAsyncImage.swift
//  Ladder
//
//  Created by Alan Leatherman on 11/21/25.
//

import SwiftUI

/// A cached async image view that optimizes imgix URLs and uses URLCache for persistent caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let size: ImageSize
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?

    enum ImageSize {
        case thumbnail // 200x200
        case card // 400x400
        case detail // 800x800

        var dimension: Int {
            switch self {
            case .thumbnail: return 200
            case .card: return 400
            case .detail: return 800
            }
        }
    }

    init(url: URL?,
         size: ImageSize = .card,
         @ViewBuilder content: @escaping (Image) -> Content,
         @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.size = size
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if loadError != nil {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.title3)
                    Button {
                        loadError = nil
                        Task { await loadImage() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url = url else { return }
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        let optimizedURL = optimizeImgixURL(url, size: size)

        let urlCache = URLCache.shared
        let request = URLRequest(url: optimizedURL)

        if let cachedResponse = urlCache.cachedResponse(for: request),
           let cachedImage = UIImage(data: cachedResponse.data) {
            self.image = cachedImage
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let cachedResponse = CachedURLResponse(response: response, data: data)
            urlCache.storeCachedResponse(cachedResponse, for: request)

            if let downloadedImage = UIImage(data: data) {
                self.image = downloadedImage
                self.loadError = nil
            }
        } catch {
            self.loadError = error
        }
    }

    private func optimizeImgixURL(_ url: URL, size: ImageSize) -> URL {
        guard url.host?.contains("imgix.net") == true else {
            return url
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? []

        let dimension = size.dimension

        // Add imgix parameters for optimization
        // w: width, h: height, fit: crop mode, q: quality, auto: automatic format selection
        queryItems.append(contentsOf: [
            URLQueryItem(name: "w", value: "\(dimension)"),
            URLQueryItem(name: "h", value: "\(dimension)"),
            URLQueryItem(name: "fit", value: "crop"),
            URLQueryItem(name: "q", value: "80"),
            URLQueryItem(name: "auto", value: "format,compress")
        ])

        components?.queryItems = queryItems

        return components?.url ?? url
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    init(url: URL?, size: ImageSize = .card) {
        self.init(
            url: url,
            size: size,
            content: { $0.resizable() },
            placeholder: { Color.gray.opacity(0.2) }
        )
    }
}

extension CachedAsyncImage where Placeholder == EmptyView {
    init(url: URL?,
         size: ImageSize = .card,
         @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(
            url: url,
            size: size,
            content: content,
            placeholder: { EmptyView() }
        )
    }
}

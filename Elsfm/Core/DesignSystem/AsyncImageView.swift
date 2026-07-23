import SwiftUI
import Kingfisher

/// A Kingfisher-backed async image view with a shimmer placeholder and
/// configurable size / corner radius.
///
/// Usage:
/// ```swift
/// AsyncImageView(url: track.image, size: 48, cornerRadius: 8)
/// ```
struct AsyncImageView: View {
    let url: String?
    var size: CGFloat = 48
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let urlString = url, let imageURL = URL(string: urlString) {
                KFImage(imageURL)
                    .placeholder { ShimmerPlaceholder(size: size, cornerRadius: cornerRadius) }
                    .resizable()
                    .scaledToFill()
            } else {
                FallbackThumbnail(size: size, cornerRadius: cornerRadius)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Shimmer placeholder

private struct ShimmerPlaceholder: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.elsfmSurface,
                        Color.elsfmSurface.opacity(0.4),
                        Color.elsfmSurface,
                    ],
                    startPoint: .init(x: phase - 0.3, y: 0.5),
                    endPoint: .init(x: phase + 0.3, y: 0.5)
                )
            )
            .frame(width: size, height: size)
            .onAppear {
                withAnimation(
                    .linear(duration: 1.4)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1.6
                }
            }
    }
}

// MARK: - Fallback (no URL)

private struct FallbackThumbnail: View {
    let size: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.elsfmSurface)
            .overlay(
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.35))
                    .foregroundStyle(Color.elsfmTextSecondary)
            )
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        AsyncImageView(url: nil, size: 48, cornerRadius: 8)
        AsyncImageView(url: "https://example.com/bad.jpg", size: 64, cornerRadius: 12)
    }
    .padding()
    .background(Color.elsfmBackground)
}
#endif

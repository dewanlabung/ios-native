import SwiftUI

/// A heart toggle button that reflects the liked state of a track.
///
/// - Filled `heart.fill` in brand primary when `isLiked` is `true`.
/// - Outline `heart` in secondary text colour when `isLiked` is `false`.
/// - A brief scale animation plays on each toggle for tactile feedback.
///
/// Usage:
/// ```swift
/// LikeButton(isLiked: track.isLiked) {
///     viewModel.toggleLike(track)
/// }
/// ```
struct LikeButton: View {
    let isLiked: Bool
    let onToggle: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: isLiked ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isLiked ? Color.elsfmPrimary : Color.elsfmTextSecondary)
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isAnimating)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isLiked ? "Unlike" : "Like")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Private

    private func handleTap() {
        isAnimating = true
        onToggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isAnimating = false
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    HStack(spacing: 32) {
        LikeButton(isLiked: false, onToggle: {})
        LikeButton(isLiked: true, onToggle: {})
    }
    .padding()
    .background(Color.elsfmBackground)
    .preferredColorScheme(.dark)
}
#endif

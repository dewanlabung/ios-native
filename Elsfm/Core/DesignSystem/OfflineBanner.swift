import SwiftUI

/// A banner displayed at the top of a screen when the network is unavailable.
///
/// Designed to be shown conditionally via a `VStack` overlay or `.safeAreaInset`:
/// ```swift
/// .safeAreaInset(edge: .top, spacing: 0) {
///     if networkMonitor.isOffline {
///         OfflineBanner()
///     }
/// }
/// ```
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .semibold))

            Text("No connection — showing cached content")
                .font(.elsfmLabel)
                .lineLimit(1)
        }
        .foregroundStyle(Color(red: 0.25, green: 0.18, blue: 0))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.yellow.opacity(0.9))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline. Showing cached content.")
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        OfflineBanner()
        Spacer()
    }
    .background(Color.elsfmBackground)
    .preferredColorScheme(.dark)
}
#endif

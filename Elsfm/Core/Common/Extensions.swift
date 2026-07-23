import SwiftUI

// MARK: - String

extension String {
    /// Returns `true` when the string is empty or contains only whitespace/newlines.
    /// Mirrors Kotlin's `String.isBlank()`.
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Int

extension Int {
    /// Converts a duration in milliseconds to a human-readable "m:ss" string.
    ///
    /// Examples:
    /// - `222_000` → `"3:42"`
    /// - `65_000`  → `"1:05"`
    /// - `45_000`  → `"0:45"`
    func formatDuration() -> String {
        let totalSeconds = self / 1_000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - View

private struct OnFirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                action()
            }
    }
}

extension View {
    /// Calls `action` exactly once, the first time this view appears on screen.
    /// Subsequent `onAppear` invocations (e.g. after navigation) are ignored.
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
}

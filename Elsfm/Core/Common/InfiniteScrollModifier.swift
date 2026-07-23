import SwiftUI

/// A `ViewModifier` that fires a callback when the modified view becomes visible.
///
/// Attach this to a sentinel view placed *after* the last real item in a
/// `LazyVStack` or `List` to implement infinite / paginated scrolling.
///
/// Typical usage:
/// ```swift
/// LazyVStack {
///     ForEach(items) { item in
///         TrackRow(track: item)
///     }
///     // Sentinel — invisible, zero-height, fires when scrolled into view.
///     Color.clear
///         .frame(height: 1)
///         .onReachBottom { viewModel.loadNextPage() }
/// }
/// ```
///
/// The `action` is called every time the view appears, so guard against
/// duplicate requests inside the callback (e.g. check `!isLoading` and
/// `hasNextPage` in your view model).
struct InfiniteScrollModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                action()
            }
    }
}

extension View {
    /// Triggers `action` whenever this view scrolls into the visible area.
    ///
    /// Place on a sentinel view at the end of a lazy list to load the next page.
    func onReachBottom(perform action: @escaping () -> Void) -> some View {
        modifier(InfiniteScrollModifier(action: action))
    }
}

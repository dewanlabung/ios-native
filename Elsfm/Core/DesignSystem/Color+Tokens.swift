import SwiftUI
import UIKit

// MARK: - SwiftUI Color tokens

extension Color {
    /// Deep near-black background — adaptive (dark ≈ #111115, light ≈ #F7F7FA).
    static let elsfmBackground = Color(UIColor.elsfmBackground)

    /// Elevated surface above the background — cards, sheets, rows.
    static let elsfmSurface = Color(UIColor.elsfmSurface)

    /// Brand primary: coral/pink-red `#F24578` (`oklch(58% 0.22 358)`).
    static let elsfmPrimary = Color(red: 0.95, green: 0.27, blue: 0.47)

    /// Text placed on top of `elsfmPrimary` backgrounds — always white.
    static let elsfmOnPrimary = Color.white

    /// High-emphasis body text — near-white in dark mode, near-black in light.
    static let elsfmText = Color(UIColor.elsfmText)

    /// Low-emphasis / secondary labels — muted grey in both themes.
    static let elsfmTextSecondary = Color(UIColor.elsfmTextSecondary)

    /// Thin separator lines between rows and sections.
    static let elsfmDivider = Color(UIColor.elsfmDivider)
}

// MARK: - UIColor adaptive tokens (programmatic — no xcassets required)

extension UIColor {
    /// Deep near-black background.
    static let elsfmBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.067, green: 0.067, blue: 0.082, alpha: 1) // #111115
            : UIColor(red: 0.965, green: 0.965, blue: 0.980, alpha: 1) // #F7F7FA
    }

    /// Elevated surface colour for cards and rows.
    static let elsfmSurface = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.114, green: 0.114, blue: 0.137, alpha: 1) // #1D1D23
            : UIColor(red: 1.0,   green: 1.0,   blue: 1.0,   alpha: 1) // #FFFFFF
    }

    /// Primary text — near-white / near-black.
    static let elsfmText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.941, green: 0.941, blue: 0.953, alpha: 1) // #F0F0F3
            : UIColor(red: 0.082, green: 0.082, blue: 0.098, alpha: 1) // #151519
    }

    /// Secondary / muted text.
    static let elsfmTextSecondary = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.561, green: 0.561, blue: 0.600, alpha: 1) // #8F8F99
            : UIColor(red: 0.431, green: 0.431, blue: 0.471, alpha: 1) // #6E6E78
    }

    /// Hairline dividers.
    static let elsfmDivider = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.08)
            : UIColor(white: 0, alpha: 0.10)
    }
}

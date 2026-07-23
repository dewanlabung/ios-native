import SwiftUI

// MARK: - Font design tokens

extension Font {
    /// Hero / display heading — 28 pt bold.
    ///
    /// Use for page titles, large feature headlines.
    static let elsfmHero = Font.system(size: 28, weight: .bold)

    /// Section or card title — 20 pt semibold.
    ///
    /// Use for screen headings, playlist names, album titles.
    static let elsfmTitle = Font.system(size: 20, weight: .semibold)

    /// Body copy — 16 pt regular.
    ///
    /// Use for primary row labels, descriptions, body text.
    static let elsfmBody = Font.system(size: 16, weight: .regular)

    /// Caption — 13 pt regular.
    ///
    /// Use for secondary metadata: play counts, timestamps, subtitles.
    static let elsfmCaption = Font.system(size: 13, weight: .regular)

    /// Small label — 12 pt medium.
    ///
    /// Use for pill badges, tags, and tight UI labels.
    static let elsfmLabel = Font.system(size: 12, weight: .medium)
}

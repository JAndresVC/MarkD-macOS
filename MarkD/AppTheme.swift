import SwiftUI
import AppKit

// MARK: - Theme Colors

struct ThemeColors {
    let colorScheme: ColorScheme
    let background: Color
    let text: Color
    let secondaryText: Color
    let heading: Color
    let codeBackground: Color
    let codeBorder: Color
    let blockquoteBorder: Color
    let divider: Color
    // Per-theme accent for controls, the insertion cursor, and sidebar icons.
    let accent: Color
    // Text links and editor selection have stricter contrast requirements than
    // control tint, so they use dedicated semantic roles.
    let link: Color
    let selectionBackground: Color
    let selectionText: Color
    // Code syntax highlighting.
    let syntaxKeyword: Color
    let syntaxString: Color
    let syntaxComment: Color
    let syntaxNumber: Color
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
    case solarizedLight = "Solarized Light"
    case solarizedDark = "Solarized Dark"
    case dracula = "Dracula"

    var id: String { rawValue }

    // Welcome actions sit on the raised surface, whose contrast differs from
    // the document background (notably in Solarized Light).
    var welcomeActionText: Color {
        self == .solarizedLight ? Color(hex: "526970") : colors.text
    }

    static func resolved(storedValue: String) -> AppTheme {
        AppTheme(rawValue: storedValue) ?? .light
    }

    var windowAppearanceName: NSAppearance.Name {
        switch self {
        case .light, .sepia, .solarizedLight:
            return .aqua
        case .dark, .solarizedDark, .dracula:
            return .darkAqua
        }
    }

    // Opacity of the theme color overlaid on the sidebar's Liquid Glass material.
    // Lower = more glass visible; higher = theme color dominant.
    var sidebarTintOpacity: Double {
        switch self {
        // Light and dark match the system palette, so the plain glass already fits.
        case .light, .dark:            return 0.35
        case .sepia, .solarizedLight:  return 0.60
        case .solarizedDark, .dracula: return 0.70
        }
    }

    var colors: ThemeColors {
        switch self {
        case .light:
            ThemeColors(
                colorScheme: .light,
                background:      Color(hex: "F8F8F8"),
                text:            Color(hex: "1C1C1E"),
                secondaryText:   Color(hex: "6C6C70"),
                heading:         Color(hex: "1C1C1E"),
                codeBackground:  Color(hex: "EAEAEB"),
                codeBorder:      Color(hex: "D1D1D6"),
                blockquoteBorder:Color(hex: "C7C7CC"),
                divider:         Color(hex: "D1D1D6"),
                accent:          Color(hex: "007AFF"),
                link:            Color(hex: "005EB8"),
                selectionBackground: Color(hex: "005EB8"),
                selectionText:   Color(hex: "FFFFFF"),
                syntaxKeyword:   Color(hex: "9B2393"),
                syntaxString:    Color(hex: "C41A16"),
                syntaxComment:   Color(hex: "5C6B78"),
                syntaxNumber:    Color(hex: "1C00CF")
            )
        case .dark:
            ThemeColors(
                colorScheme: .dark,
                background:      Color(hex: "1C1C1E"),
                text:            Color(hex: "F2F2F7"),
                secondaryText:   Color(hex: "8E8E93"),
                heading:         Color(hex: "F2F2F7"),
                codeBackground:  Color(hex: "2C2C2E"),
                codeBorder:      Color(hex: "3A3A3C"),
                blockquoteBorder:Color(hex: "545456"),
                divider:         Color(hex: "3A3A3C"),
                accent:          Color(hex: "0A84FF"),
                link:            Color(hex: "0A84FF"),
                selectionBackground: Color(hex: "0060B8"),
                selectionText:   Color(hex: "FFFFFF"),
                syntaxKeyword:   Color(hex: "FF7AB2"),
                syntaxString:    Color(hex: "FF8170"),
                syntaxComment:   Color(hex: "8896A3"),
                syntaxNumber:    Color(hex: "D9C97C")
            )
        case .sepia:
            ThemeColors(
                colorScheme: .light,
                background:      Color(hex: "F4ECD8"),
                text:            Color(hex: "3B2D1F"),
                secondaryText:   Color(hex: "7A6552"),
                heading:         Color(hex: "3B2D1F"),
                codeBackground:  Color(hex: "EAE0C8"),
                codeBorder:      Color(hex: "C8B898"),
                blockquoteBorder:Color(hex: "B89878"),
                divider:         Color(hex: "C8B898"),
                accent:          Color(hex: "9C6B30"),
                link:            Color(hex: "78501F"),
                selectionBackground: Color(hex: "78501F"),
                selectionText:   Color(hex: "FFF9EA"),
                syntaxKeyword:   Color(hex: "8F3F71"),
                syntaxString:    Color(hex: "A54242"),
                syntaxComment:   Color(hex: "6E6049"),
                syntaxNumber:    Color(hex: "315F91")
            )
        case .solarizedLight:
            ThemeColors(
                colorScheme: .light,
                background:      Color(hex: "FDF6E3"),
                text:            Color(hex: "586E75"),
                // base00 instead of base1: 93A1A1 on FDF6E3 is ~2.4:1 contrast, unreadable.
                secondaryText:   Color(hex: "5F747B"),
                heading:         Color(hex: "006E9F"),
                codeBackground:  Color(hex: "EEE8D5"),
                codeBorder:      Color(hex: "D4C9A8"),
                blockquoteBorder:Color(hex: "2AA198"),
                divider:         Color(hex: "D4C9A8"),
                accent:          Color(hex: "268BD2"),
                link:            Color(hex: "006E68"),
                selectionBackground: Color(hex: "006E68"),
                selectionText:   Color(hex: "FDF6E3"),
                syntaxKeyword:   Color(hex: "586E00"),
                syntaxString:    Color(hex: "00756E"),
                syntaxComment:   Color(hex: "526970"),
                syntaxNumber:    Color(hex: "B01F65")
            )
        case .solarizedDark:
            ThemeColors(
                colorScheme: .dark,
                background:      Color(hex: "002B36"),
                // base1 for body: 839496 on 002B36 sits near 4.5:1; base1 reads cleanly.
                text:            Color(hex: "93A1A1"),
                secondaryText:   Color(hex: "839496"),
                heading:         Color(hex: "3AA7E8"),
                codeBackground:  Color(hex: "073642"),
                codeBorder:      Color(hex: "0D4A5A"),
                blockquoteBorder:Color(hex: "2AA198"),
                divider:         Color(hex: "586E75"),
                accent:          Color(hex: "2AA198"),
                link:            Color(hex: "2AA198"),
                selectionBackground: Color(hex: "2AA198"),
                selectionText:   Color(hex: "002B36"),
                syntaxKeyword:   Color(hex: "8FA300"),
                syntaxString:    Color(hex: "30AB9F"),
                syntaxComment:   Color(hex: "93A1A1"),
                syntaxNumber:    Color(hex: "EF6AA8")
            )
        case .dracula:
            ThemeColors(
                colorScheme: .dark,
                background:      Color(hex: "282A36"),
                text:            Color(hex: "F8F8F2"),
                // Lightened comment color: 6272A4 on 282A36 is ~2.9:1, too dim for UI text.
                secondaryText:   Color(hex: "8B99CC"),
                heading:         Color(hex: "BD93F9"),
                codeBackground:  Color(hex: "21222C"),
                codeBorder:      Color(hex: "44475A"),
                blockquoteBorder:Color(hex: "BD93F9"),
                divider:         Color(hex: "44475A"),
                accent:          Color(hex: "BD93F9"),
                link:            Color(hex: "BD93F9"),
                selectionBackground: Color(hex: "6D4A8E"),
                selectionText:   Color(hex: "F8F8F2"),
                syntaxKeyword:   Color(hex: "FF79C6"),
                syntaxString:    Color(hex: "F1FA8C"),
                syntaxComment:   Color(hex: "8B99CC"),
                syntaxNumber:    Color(hex: "BD93F9")
            )
        }
    }
}

// MARK: - Environment Keys

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .light
}

private struct EditorFontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = 14
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }

    var editorFontSize: CGFloat {
        get { self[EditorFontSizeKey.self] }
        set { self[EditorFontSizeKey.self] = newValue }
    }
}

// MARK: - Color Hex Initializer

extension Color {
    init(hex: String) {
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            .sRGB,
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Markdown Colors

extension AttributedString {
    /// SwiftUI renders Markdown links with the system accent unless their
    /// foreground color is explicit. Apply the active palette while preserving
    /// all semantic Markdown attributes and destinations.
    func applyingMarkdownTheme(_ colors: ThemeColors) -> AttributedString {
        var result = self
        for run in result.runs where run.link != nil {
            result[run.range].foregroundColor = colors.link
        }
        return result
    }
}

import AppKit
import SwiftUI

@main
enum ThemePaletteTests {
    private static var failures: [String] = []

    static func main() {
        for theme in AppTheme.allCases {
            checkContrast(
                theme.welcomeActionText,
                against: theme.colors.codeBackground,
                minimum: 4.5,
                label: "\(theme.rawValue) welcome action and shortcut"
            )
            checkContrast(
                theme.colors.text,
                against: theme.colors.background,
                minimum: 4.5,
                label: "\(theme.rawValue) body text"
            )
            checkContrast(
                theme.colors.secondaryText,
                against: theme.colors.background,
                minimum: 4.5,
                label: "\(theme.rawValue) secondary text"
            )
            checkContrast(
                theme.colors.heading,
                against: theme.colors.background,
                minimum: 4.5,
                label: "\(theme.rawValue) small heading"
            )
            checkContrast(
                theme.colors.link,
                against: theme.colors.background,
                minimum: 4.5,
                label: "\(theme.rawValue) link"
            )
            checkContrast(
                theme.colors.selectionText,
                against: theme.colors.selectionBackground,
                minimum: 4.5,
                label: "\(theme.rawValue) selected text"
            )
            NSAppearance(named: theme.windowAppearanceName)?.performAsCurrentDrawingAppearance {
                for background in [NSColor.selectedTextBackgroundColor, .unemphasizedSelectedTextBackgroundColor] {
                    checkContrast(Color(nsColor: .labelColor), against: Color(nsColor: background),
                                  minimum: 4.5, label: "\(theme.rawValue) native editor selection")
                }
            }

            let syntaxColors: [(String, Color)] = [
                ("keyword", theme.colors.syntaxKeyword),
                ("string", theme.colors.syntaxString),
                ("comment", theme.colors.syntaxComment),
                ("number", theme.colors.syntaxNumber)
            ]
            for (name, color) in syntaxColors {
                checkContrast(
                    color,
                    against: theme.colors.codeBackground,
                    minimum: 4.5,
                    label: "\(theme.rawValue) syntax \(name)"
                )
            }
        }

        checkMarkdownLinkUsesThemeAccent()
        checkStoredThemeResolution()

        if failures.isEmpty {
            print("ThemePaletteTests: passed")
        } else {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
    }

    private static func checkStoredThemeResolution() {
        if AppTheme.resolved(storedValue: AppTheme.dracula.rawValue) != .dracula {
            failures.append("stored Dracula theme did not resolve to Dracula")
        }
        if AppTheme.resolved(storedValue: "corrupted-theme") != .light {
            failures.append("invalid stored theme did not safely fall back to Light")
        }
        if AppTheme.dracula.windowAppearanceName != .darkAqua {
            failures.append("Dracula did not request the dark macOS window appearance")
        }
        if AppTheme.sepia.windowAppearanceName != .aqua {
            failures.append("Sepia did not request the light macOS window appearance")
        }
    }

    private static func checkMarkdownLinkUsesThemeAccent() {
        guard let source = try? AttributedString(markdown: "A [themed link](https://example.com)") else {
            failures.append("could not create Markdown link fixture")
            return
        }

        let theme = AppTheme.sepia
        let styled = source.applyingMarkdownTheme(theme.colors)
        guard let linkRun = styled.runs.first(where: { $0.link != nil }) else {
            failures.append("Markdown link run disappeared while applying the theme")
            return
        }
        guard let foreground = linkRun.foregroundColor else {
            failures.append("Markdown link did not receive an explicit theme color")
            return
        }

        let actual = NSColor(foreground).usingColorSpace(.sRGB)
        let expected = NSColor(theme.colors.link).usingColorSpace(.sRGB)
        guard let actual, let expected else {
            failures.append("could not resolve Markdown link colors in sRGB")
            return
        }

        let componentsMatch = abs(actual.redComponent - expected.redComponent) < 0.001
            && abs(actual.greenComponent - expected.greenComponent) < 0.001
            && abs(actual.blueComponent - expected.blueComponent) < 0.001
        if !componentsMatch {
            failures.append("Markdown link kept a system color instead of the Sepia link color")
        }
    }

    private static func checkContrast(
        _ foreground: Color,
        against background: Color,
        minimum: Double,
        label: String
    ) {
        let ratio = contrastRatio(foreground, background)
        if ratio + 0.0001 < minimum {
            failures.append("\(label) contrast \(String(format: "%.2f", ratio)):1 < \(minimum):1")
        }
    }

    private static func contrastRatio(_ first: Color, _ second: Color) -> Double {
        guard let foreground = NSColor(first).usingColorSpace(.sRGB),
              let background = NSColor(second).usingColorSpace(.sRGB) else {
            fatalError("Could not resolve contrast colors in sRGB")
        }
        let alpha = foreground.alphaComponent
        let composited = Color(.sRGB,
            red: Double(foreground.redComponent * alpha + background.redComponent * (1 - alpha)),
            green: Double(foreground.greenComponent * alpha + background.greenComponent * (1 - alpha)),
            blue: Double(foreground.blueComponent * alpha + background.blueComponent * (1 - alpha)))
        let firstLuminance = relativeLuminance(composited)
        let secondLuminance = relativeLuminance(second)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ color: Color) -> Double {
        guard let srgb = NSColor(color).usingColorSpace(.sRGB) else {
            fatalError("Could not resolve color in sRGB")
        }
        return 0.2126 * linearized(srgb.redComponent)
            + 0.7152 * linearized(srgb.greenComponent)
            + 0.0722 * linearized(srgb.blueComponent)
    }

    private static func linearized(_ component: CGFloat) -> Double {
        let value = Double(component)
        return value <= 0.04045
            ? value / 12.92
            : pow((value + 0.055) / 1.055, 2.4)
    }
}

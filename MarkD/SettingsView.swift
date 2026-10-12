import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue
    @Environment(\.appTheme) private var theme

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label(strings.general, systemImage: "gearshape") }
            AppearanceSettingsView()
                .tabItem { Label(strings.appearance, systemImage: "paintbrush") }
            EditorSettingsView()
                .tabItem { Label(strings.editor, systemImage: "character.cursor.ibeam") }
        }
        .frame(width: 420)
        .background(theme.colors.background.ignoresSafeArea())
    }
}

private struct SettingsSurface: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .foregroundStyle(theme.colors.text)
            .background(theme.colors.background)
    }
}

private extension View {
    func settingsSurface() -> some View {
        modifier(SettingsSurface())
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    private var versionDescription: String {
        "MarkD \(AppIdentity.versionDescription)"
    }

    var body: some View {
        Form {
            Section {
                Picker(strings.languageLabel, selection: $storedLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .pickerStyle(.inline)
            } footer: {
                Text(versionDescription)
            }
        }
        .formStyle(.grouped)
        .settingsSurface()
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsView: View {
    @AppStorage("selectedTheme") private var selectedThemeName: String = AppTheme.light.rawValue
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some View {
        Form {
            Picker(strings.themeLabel, selection: $selectedThemeName) {
                ForEach(AppTheme.allCases) { theme in
                    ThemeRow(theme: theme, name: strings.themeName(theme))
                        .tag(theme.rawValue)
                }
            }
            .pickerStyle(.inline)
        }
        .formStyle(.grouped)
        .settingsSurface()
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ThemeRow: View {
    let theme: AppTheme
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            ThemeSwatch(colors: theme.colors)
            Text(name)
        }
    }
}

private struct ThemeSwatch: View {
    let colors: ThemeColors

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(colors.background)
            Text("Aa")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(colors.text)
        }
        .frame(width: 28, height: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(.separator, lineWidth: 1)
        )
    }
}

// MARK: - Editor

private struct EditorSettingsView: View {
    @AppStorage("editorFontSize") private var fontSize: Double = 14
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some View {
        Form {
            LabeledContent(strings.fontSizeLabel) {
                HStack(spacing: 8) {
                    Slider(value: $fontSize, in: 10...32, step: 1)
                        .frame(width: 180)
                    Stepper(
                        "\(Int(fontSize)) pt",
                        value: $fontSize,
                        in: 10...32,
                        step: 1
                    )
                    .monospacedDigit()
                }
            }
            Button(strings.resetToDefault) { fontSize = 14 }
        }
        .formStyle(.grouped)
        .settingsSurface()
        .scrollDisabled(true)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    SettingsView()
}

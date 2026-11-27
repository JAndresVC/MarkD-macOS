import SwiftUI
import AppKit

@main
struct MarkDApp: App {
    @NSApplicationDelegateAdaptor(MarkDAppDelegate.self) private var appDelegate
    @AppStorage("appLanguage") private var storedLanguage = AppLanguage.system.rawValue
    @StateObject private var updater = AppUpdater()

    var body: some Scene {
        DocumentGroup(newDocument: MarkDocument()) { file in
            ThemedSceneContent(usesUnifiedDocumentToolbar: true) {
                ContentView(document: file.$document)
            }
        }
        .windowResizability(.contentMinSize)
        .defaultLaunchBehavior(.suppressed)
        .commands {
            UpdateCommands(updater: updater)
            FindCommands()
            ViewModeCommands()
            ThemeCommands()
            FontSizeCommands()
        }

        Window(AppLanguage.from(stored: storedLanguage).strings.welcome.windowTitle,
               id: AppIdentity.welcomeWindowID) {
            ThemedSceneContent {
                WelcomeView()
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 900, height: 560)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)

        // Standard Settings scene — enables the "Settings…" item in the app
        // menu with the system Cmd+, shortcut.
        Settings {
            ThemedSceneContent {
                SettingsView()
            }
        }
    }
}

final class MarkDAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // SwiftUI must create its document controller before configuring periodic autosaving.
        NSDocumentController.shared.autosavingDelay = 1
    }
}

struct FindCommands: Commands {
    @FocusedValue(\.previewFindActions) private var previewFindActions
    @FocusedValue(\.editorFindController) private var editorFindController
    @FocusedBinding(\.viewMode) private var viewMode: ViewMode?
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }
    private var hasDocument: Bool { viewMode != nil }

    var body: some Commands {
        CommandGroup(after: .pasteboard) {
            Menu(strings.find) {
                Button(strings.findEllipsis) {
                    if viewMode == .preview {
                        previewFindActions?.show()
                    } else {
                        performNativeFindAction(.showFindInterface)
                    }
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!hasDocument)

                Button(strings.findNext) {
                    if viewMode == .preview {
                        previewFindActions?.next()
                    } else {
                        performNativeFindAction(.nextMatch)
                    }
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(!hasDocument || (previewFindActions?.canNavigate == false))

                Button(strings.findPrevious) {
                    if viewMode == .preview {
                        previewFindActions?.previous()
                    } else {
                        performNativeFindAction(.previousMatch)
                    }
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(!hasDocument || (previewFindActions?.canNavigate == false))
            }
        }
    }

    private func performNativeFindAction(_ action: NSTextFinder.Action) {
        editorFindController?.perform(action)
    }
}

struct ViewModeCommands: Commands {
    @FocusedBinding(\.viewMode) private var viewMode: ViewMode?
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(strings.edit) { viewMode = .edit }
                .keyboardShortcut("1", modifiers: .command)
                .disabled(viewMode == nil)
            Button(strings.preview) { viewMode = .preview }
                .keyboardShortcut("2", modifiers: .command)
                .disabled(viewMode == nil)
            Button(strings.raw) { viewMode = .raw }
                .keyboardShortcut("3", modifiers: .command)
                .disabled(viewMode == nil)
        }
    }
}

struct ThemeCommands: Commands {
    @AppStorage("selectedTheme") private var selectedThemeName: String = AppTheme.light.rawValue
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()
            Picker(strings.theme, selection: $selectedThemeName) {
                ForEach(AppTheme.allCases) { theme in
                    Text(strings.themeName(theme)).tag(theme.rawValue)
                }
            }
        }
    }
}

struct FontSizeCommands: Commands {
    @AppStorage("editorFontSize") private var fontSize: Double = 14
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Menu(strings.fontSize) {
                Button(strings.increase) { fontSize = min(fontSize + 2, 32) }
                    .keyboardShortcut("=", modifiers: .command)
                Button(strings.decrease) { fontSize = max(fontSize - 2, 10) }
                    .keyboardShortcut("-", modifiers: .command)
                Divider()
                Button(strings.resetToDefault) { fontSize = 14 }
                    .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}

import SwiftUI

enum ViewMode: String, CaseIterable {
    case edit = "Edit"
    case preview = "Preview"
    case raw = "RAW"

    func title(_ strings: L10n) -> String {
        switch self {
        case .edit:    return strings.edit
        case .preview: return strings.preview
        case .raw:     return strings.raw
        }
    }

    var systemImage: String {
        switch self {
        case .edit:    return "pencil"
        case .preview: return "doc.richtext"
        case .raw:     return "chevron.left.forwardslash.chevron.right"
        }
    }
}

private struct ModeToolbarControl: View {
    @Binding var selection: ViewMode
    let strings: L10n
    let isCompact: Bool

    var body: some View {
        if isCompact {
            Menu {
                Picker(strings.mode, selection: $selection) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.title(strings)).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label(selection.title(strings), systemImage: selection.systemImage)
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help(strings.mode)
            .accessibilityLabel(strings.mode)
            .accessibilityValue(selection.title(strings))
        } else {
            expandedPicker.fixedSize()
        }
    }

    private var picker: some View {
        Picker(strings.mode, selection: $selection) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Text(mode.title(strings)).tag(mode)
            }
        }
    }

    @ViewBuilder private var expandedPicker: some View {
        // Xcode 26 remains usable; the new style requires both SDK and OS 27.
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            picker.pickerStyle(.tabs)
        } else {
            picker.pickerStyle(.segmented)
        }
        #else
        picker.pickerStyle(.segmented)
        #endif
    }
}

// Exposes the active window's view mode to menu commands (Cmd+1/2/3).
struct ViewModeKey: FocusedValueKey {
    typealias Value = Binding<ViewMode>
}

extension FocusedValues {
    var viewMode: Binding<ViewMode>? {
        get { self[ViewModeKey.self] }
        set { self[ViewModeKey.self] = newValue }
    }
}

struct ContentView: View {
    @Binding var document: MarkDocument
    @State private var viewMode: ViewMode = .edit
    @State private var editorFindController = EditorFindController()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var scrollToHeadingLine: Int? = nil
    @State private var availableWidth: CGFloat = 900
    @AppStorage("editorFontSize") private var storedFontSize: Double = 14
    @AppStorage("appLanguage") private var storedLanguage: String = AppLanguage.system.rawValue
    @Environment(\.appTheme) private var theme
    @Environment(\.dismissWindow) private var dismissWindow

    private var strings: L10n {
        AppLanguage.from(stored: storedLanguage).strings
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(text: document.text) { item in
                scrollToHeadingLine = item.id
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 280)
        } detail: {
            // The same editor stays alive across every mode. Recreating the
            // NSTextView here would destroy its undo stack and scroll position.
            ZStack {
                theme.colors.background
                    .ignoresSafeArea()

                EditorView(
                    text: $document.text,
                    scrollToLine: $scrollToHeadingLine,
                    isEditable: viewMode == .edit,
                    isVisible: viewMode != .preview,
                    findController: editorFindController
                )
                // RAW reuses the same NSTextView in read-only mode. That keeps
                // text selection, Find, and heading navigation fully native.
                .opacity(viewMode == .preview ? 0 : 1)
                .allowsHitTesting(viewMode != .preview)
                .accessibilityHidden(viewMode == .preview)

                switch viewMode {
                case .edit, .raw:
                    EmptyView()
                case .preview:
                    MarkdownPreviewView(markdown: document.text, scrollToLine: $scrollToHeadingLine)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ModeToolbarControl(
                        selection: $viewMode,
                        strings: strings,
                        isCompact: availableWidth < 780
                    )
                }
            }
        }
        // Keep the window chrome consistent across SwiftUI Preview and the
        // embedded AppKit editor. Otherwise macOS replaces the toolbar's glass
        // with an opaque white/black strip only in Edit and RAW.
        .toolbarBackground(.ultraThinMaterial, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .containerBackground(theme.colors.background, for: .window)
        .environment(\.editorFontSize, CGFloat(storedFontSize))
        .environment(\.l10n, strings)
        .focusedSceneValue(\.viewMode, $viewMode)
        .focusedSceneValue(\.editorFindController, viewMode == .preview ? nil : editorFindController)
        .onAppear { dismissWindow(id: AppIdentity.welcomeWindowID) }
        // Reserve room for the sidebar, a readable document, and the labelled
        // mode menu instead of letting AppKit move it into toolbar overflow.
        .frame(minWidth: 560, minHeight: 360)
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { width in
            availableWidth = width
        }
        .onChange(of: viewMode) { _, _ in
            // Clear any pending scroll target when switching modes
            scrollToHeadingLine = nil
        }
    }
}

#Preview {
    ContentView(document: .constant(MarkDocument()))
}

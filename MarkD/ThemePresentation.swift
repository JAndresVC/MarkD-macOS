import SwiftUI
import AppKit

/// Applies the persisted palette consistently to every SwiftUI scene.
/// Document windows and Settings are separate scenes, so the theme must wrap
/// both instead of living only inside ContentView.
struct ThemedSceneContent<Content: View>: View {
    @AppStorage("selectedTheme") private var selectedThemeName: String = AppTheme.light.rawValue
    private let content: Content
    private let usesUnifiedDocumentToolbar: Bool

    init(
        usesUnifiedDocumentToolbar: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.usesUnifiedDocumentToolbar = usesUnifiedDocumentToolbar
        self.content = content()
    }

    private var theme: AppTheme {
        AppTheme.resolved(storedValue: selectedThemeName)
    }

    var body: some View {
        content
            .environment(\.appTheme, theme)
            // A preferred scheme is lifted to the enclosing presentation, so
            // native window chrome (title, toolbar buttons, panels) updates as
            // well. Injecting only the environment value themed the document
            // content but left dark custom themes with black title-bar text.
            .preferredColorScheme(theme.colors.colorScheme)
            .tint(theme.colors.accent)
            .background(
                WindowAppearanceSetter(
                    appearanceName: theme.windowAppearanceName,
                    usesUnifiedDocumentToolbar: usesUnifiedDocumentToolbar
                )
            )
    }
}

/// SwiftUI does not expose NSWindow.appearance. This zero-sized bridge applies
/// it both on updates and when SwiftUI finally attaches the view to a window.
private struct WindowAppearanceSetter: NSViewRepresentable {
    let appearanceName: NSAppearance.Name
    let usesUnifiedDocumentToolbar: Bool

    func makeNSView(context: Context) -> WindowAppearanceTrackingView {
        WindowAppearanceTrackingView(
            appearanceName: appearanceName,
            usesUnifiedDocumentToolbar: usesUnifiedDocumentToolbar
        )
    }

    func updateNSView(_ nsView: WindowAppearanceTrackingView, context: Context) {
        nsView.appearanceName = appearanceName
        nsView.usesUnifiedDocumentToolbar = usesUnifiedDocumentToolbar
    }
}

final class WindowAppearanceTrackingView: NSView {
    var appearanceName: NSAppearance.Name {
        didSet { applyAppearanceIfNeeded() }
    }
    var usesUnifiedDocumentToolbar: Bool {
        didSet { applyAppearanceIfNeeded() }
    }

    private weak var configuredWindow: NSWindow?
    private var configuredAppearanceName: NSAppearance.Name?
    private var configuredUnifiedToolbar: Bool?

    init(
        appearanceName: NSAppearance.Name,
        usesUnifiedDocumentToolbar: Bool = false
    ) {
        self.appearanceName = appearanceName
        self.usesUnifiedDocumentToolbar = usesUnifiedDocumentToolbar
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyAppearanceIfNeeded()
    }

    private func applyAppearanceIfNeeded() {
        guard let window else { return }
        guard configuredWindow !== window
                || configuredAppearanceName != appearanceName
                || configuredUnifiedToolbar != usesUnifiedDocumentToolbar else { return }

        window.appearance = NSAppearance(named: appearanceName)
        if usesUnifiedDocumentToolbar {
            // SwiftUI's Preview scroll view supplies this treatment
            // automatically, while the embedded AppKit editor otherwise falls
            // back to a flat white/black title bar.
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .line
        } else {
            window.titlebarAppearsTransparent = false
            window.titlebarSeparatorStyle = .automatic
        }
        configuredWindow = window
        configuredAppearanceName = appearanceName
        configuredUnifiedToolbar = usesUnifiedDocumentToolbar
    }
}

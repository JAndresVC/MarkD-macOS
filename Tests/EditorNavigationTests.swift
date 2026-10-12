import SwiftUI
import AppKit

// Model a key document window without making a test window visible or taking
// focus from the user's app. The actual first responder remains AppKit's.
private final class FocusTestWindow: NSWindow {
    override var isKeyWindow: Bool { true }
}

@main
@MainActor
enum EditorNavigationTests {
    static func main() {
        _ = NSApplication.shared
        for separator in ["\n", "\r\n", "\r"] {
            verifyNavigation(source: "# 👩🏽‍💻 café\(separator)\(separator)## Destination\(separator)last", line: 2)
        }
        verifyNavigation(source: "# 👩🏽‍💻\r\nfirst\rsecond\n## Destination", line: 3)
        verifyFocusRestoration()
        print("EditorNavigationTests: 5 passed")
    }

    private static func verifyFocusRestoration() {
        let source = "Plain text café 日本語."
        let host = NSHostingView(rootView: EditorView(text: .constant(source), scrollToLine: .constant(nil)))
        let window = FocusTestWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                                     styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        settle(host)
        guard let editor = descendantTextView(in: host), window.makeFirstResponder(editor) else {
            fatalError("cannot focus the test editor")
        }
        for _ in 0..<2 {
            host.rootView = EditorView(text: .constant(source), scrollToLine: .constant(nil),
                                       isEditable: false, isVisible: false)
            settle(host)
            guard window.firstResponder !== editor else { fatalError("hidden editor retained focus") }
            host.rootView = EditorView(text: .constant(source), scrollToLine: .constant(nil),
                                       isEditable: false, isVisible: true)
            settle(host)
            guard descendantTextView(in: host) === editor,
                  window.firstResponder === editor, !editor.isEditable, editor.isSelectable,
                  editor.string == source else {
                fatalError("RAW did not restore the same selectable, read-only first responder")
            }
        }
    }

    private static func settle(_ host: NSView) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }

    private static func verifyNavigation(source: String, line: Int) {
        var target: Int? = line
        let host = NSHostingView(rootView: EditorView(
            text: .constant(source),
            scrollToLine: Binding(get: { target }, set: { target = $0 })
        ))
        // A hidden hosting window exercises the real representable and its
        // UTF-16 selection, without taking focus from the user's application.
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        guard let editor = descendantTextView(in: host) else {
            fatalError("editor was not created in the test window")
        }
        let expected = (source as NSString).range(of: "## Destination").location
        guard editor.selectedRange().location == expected, editor.string == source else {
            fputs("FAIL: source \(source.debugDescription): caret \(editor.selectedRange().location), expected \(expected)\n", stderr)
            exit(1)
        }
    }

    private static func descendantTextView(in view: NSView) -> NSTextView? {
        if let text = view as? NSTextView { return text }
        return view.subviews.lazy.compactMap { descendantTextView(in: $0) }.first
    }
}

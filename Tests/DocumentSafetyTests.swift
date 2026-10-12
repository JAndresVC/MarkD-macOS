import AppKit
import SwiftUI

@main
@MainActor
enum DocumentSafetyTests {
    private static var failures: [String] = []

    static func main() {
        _ = NSApplication.shared
        checkLocalCanonicalEdit()
        checkExternalCanonicalReload()
        checkExternalReloadUndo()
        checkImmediateExternalReload()
        checkExactTextAndIndependentDocuments()
        if !failures.isEmpty {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
        print("DocumentSafetyTests: 5 passed")
    }

    @MainActor
    private final class Fixture {
        var text: String
        let window: NSWindow
        let host: NSHostingView<EditorView>
        var editor: NSTextView { findText(in: host)! }

        init(_ source: String) {
            text = source
            host = NSHostingView(rootView: EditorView(text: .constant(source), scrollToLine: .constant(nil)))
            window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                              styleMask: [.titled], backing: .buffered, defer: false)
            window.contentView = host
            refresh()
        }

        func refresh() {
            host.rootView = EditorView(text: Binding(get: { self.text }, set: { self.text = $0 }),
                                       scrollToLine: .constant(nil))
            host.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        }

        func replace(_ replacement: String) {
            editor.insertText(replacement, replacementRange: NSRange(location: 0, length: (editor.string as NSString).length))
            // NSTextViewDelegate publishes the binding on the main run loop.
            // Let that real callback complete before asking SwiftUI to update.
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }
    }

    private static func checkLocalCanonicalEdit() {
        let fixture = Fixture("caf\u{00e9}")
        fixture.replace("cafe\u{0301}")
        expect(Array(fixture.text.utf8) == Array("cafe\u{0301}".utf8),
               "canonical-equivalent edit was not published to the document for saving")
    }

    private static func checkExternalCanonicalReload() {
        let fixture = Fixture("caf\u{00e9}")
        fixture.text = "cafe\u{0301}"
        fixture.refresh()
        expect(Array(fixture.editor.string.utf8) == Array(fixture.text.utf8),
               "external reload left old Unicode bytes in the editor")
    }

    private static func checkExternalReloadUndo() {
        let fixture = Fixture("BASE")
        fixture.replace("LOCAL")
        fixture.editor.breakUndoCoalescing()
        expect(fixture.editor.undoManager?.canUndo == true, "local edit did not register undo")
        fixture.refresh()
        fixture.text = "EXTERNAL"
        fixture.refresh()
        expect(fixture.editor.string == "EXTERNAL", "external reload was not applied")
        expect(fixture.editor.undoManager?.canUndo != true, "old undo actions survived external replacement")
    }

    private static func checkImmediateExternalReload() {
        let fixture = Fixture("BASE")
        fixture.replace("LOCAL")
        fixture.text = "EXTERNAL_IMMEDIATE"
        fixture.refresh()
        expect(fixture.editor.string == "EXTERNAL_IMMEDIATE",
               "reload immediately after a local edit was skipped permanently")
    }

    private static func checkExactTextAndIndependentDocuments() {
        let one = Fixture("# One\r\n\r\n👩🏽‍💻 cafe\u{0301}\r\n")
        let two = Fixture("# Two\r\nkeep\r\n")
        let expected = "# One\r\n\r\n👩🏽‍💻 cafe\u{0301}\r\nnew\r\n"
        one.replace(expected)
        one.refresh()
        two.refresh()
        expect(Data(one.text.utf8) == Data(expected.utf8), "edit changed source bytes or line endings")
        expect(two.text == "# Two\r\nkeep\r\n", "edit leaked into another document")
    }

    private static func expect(_ result: Bool, _ message: String) {
        if !result { failures.append(message) }
    }

    private static func findText(in view: NSView) -> NSTextView? {
        if let text = view as? NSTextView { return text }
        return view.subviews.lazy.compactMap { findText(in: $0) }.first
    }
}

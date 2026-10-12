import AppKit
import SwiftUI

// Keep integration windows hidden and simulate only which document is active.
// NSTextView, its first responder, and the native Find bar remain real AppKit.
private final class FindTestWindow: NSWindow {
    var activeDocument = true
    override var isKeyWindow: Bool { activeDocument }
}

@MainActor
private final class FindFixture {
    let controller = EditorFindController()
    let source = "First needle café 日本語\nSecond needle\n"
    let window = FindTestWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
                                styleMask: [.titled], backing: .buffered, defer: false)
    var host: NSHostingView<EditorView>!
    var editor: NSTextView!
    var scroll: NSScrollView { editor.enclosingScrollView! }

    init() {
        host = NSHostingView(rootView: view())
        window.contentView = host
        settle()
        editor = findTextView(host)
        require(editor != nil, "editor created")
        window.makeFirstResponder(nil)
        require(window.firstResponder !== editor, "fixture starts without editor focus")
    }

    func view(visible: Bool = true, editable: Bool = true) -> EditorView {
        EditorView(text: .constant(source), scrollToLine: .constant(nil),
                   isEditable: editable, isVisible: visible, findController: controller)
    }

    func settle() {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}

@MainActor
private func findTextView(_ view: NSView) -> NSTextView? {
    if let text = view as? NSTextView { return text }
    return view.subviews.lazy.compactMap { findTextView($0) }.first
}

private func require(_ condition: Bool, _ message: String) {
    guard condition else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
@MainActor
enum EditorFindTests {
    static func main() {
        _ = NSApplication.shared
        findWithoutInitialFocus()
        findInRAWWithoutPreviousFocus()
        onlyActiveWindowFinds()
        hiddenAndDetachedEditorsDoNotFind()
        sheetKeepsItsFocus()
        print("EditorFindTests: 5 passed")
    }

    private static func findWithoutInitialFocus() {
        let fixture = FindFixture()
        fixture.controller.perform(.showFindInterface)
        fixture.settle()
        require(fixture.scroll.isFindBarVisible, "Find opens before any click in the editor (QA-06)")
        require(fixture.editor.string == fixture.source, "Find preserves Unicode document text")
    }

    private static func findInRAWWithoutPreviousFocus() {
        let fixture = FindFixture()
        fixture.host.rootView = fixture.view(visible: false, editable: false)
        fixture.settle()
        fixture.host.rootView = fixture.view(editable: false)
        fixture.settle()
        require(fixture.window.firstResponder !== fixture.editor, "RAW has no prior focus restoration")
        fixture.controller.perform(.showFindInterface)
        fixture.settle()
        require(fixture.scroll.isFindBarVisible, "Preview to RAW opens Find without prior focus")
        require(findTextView(fixture.scroll.contentView) === fixture.editor,
                "mode changes retain the same editor")
        require(!fixture.editor.isEditable && fixture.editor.isSelectable,
                "RAW stays selectable and read-only")
    }

    private static func onlyActiveWindowFinds() {
        let first = FindFixture()
        let second = FindFixture()
        first.window.activeDocument = false
        first.controller.perform(.showFindInterface)
        require(!first.scroll.isFindBarVisible, "background document cannot open Find")
        second.controller.perform(.showFindInterface)
        second.settle()
        require(second.scroll.isFindBarVisible && !first.scroll.isFindBarVisible,
                "Find opens only in the active document")
        first.window.activeDocument = true
        second.window.activeDocument = false
        first.controller.perform(.showFindInterface)
        first.settle()
        require(first.scroll.isFindBarVisible, "Find follows the newly active document")
    }

    private static func hiddenAndDetachedEditorsDoNotFind() {
        let fixture = FindFixture()
        fixture.host.rootView = fixture.view(visible: false)
        fixture.settle()
        fixture.controller.perform(.showFindInterface)
        require(!fixture.scroll.isFindBarVisible, "Preview cannot activate hidden native Find")
        fixture.host.rootView = fixture.view()
        fixture.settle()
        // An old representable must not detach a newer editor association.
        fixture.controller.detach(NSTextView())
        fixture.controller.perform(.showFindInterface)
        fixture.settle()
        require(fixture.scroll.isFindBarVisible, "unrelated dismantle preserves the current editor")
        fixture.controller.perform(.hideFindInterface)
        fixture.controller.detach(fixture.editor)
        fixture.controller.perform(.showFindInterface)
        fixture.settle()
        require(!fixture.scroll.isFindBarVisible, "detached editor cannot reopen Find")
    }

    private static func sheetKeepsItsFocus() {
        let fixture = FindFixture()
        let sheet = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
                             styleMask: [.titled], backing: .buffered, defer: false)
        fixture.window.beginSheet(sheet)
        defer { fixture.window.endSheet(sheet) }
        require(fixture.window.attachedSheet === sheet, "fixture has an attached sheet")
        let previous = fixture.window.firstResponder
        fixture.controller.perform(.showFindInterface)
        require(!fixture.scroll.isFindBarVisible && fixture.window.firstResponder === previous,
                "Find leaves a document with an attached sheet alone")
    }
}

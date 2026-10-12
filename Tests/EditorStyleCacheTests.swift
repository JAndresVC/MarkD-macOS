import Foundation
import AppKit

@main
@MainActor
enum EditorStyleCacheTests {
    static func main() {
        var failures: [String] = []
        var cache = EditorStyleCache()

        let dark14 = EditorStyleKey(themeName: AppTheme.dark.rawValue, fontSize: 14)
        if !cache.needsApplying(dark14) {
            failures.append("the first style was not applied")
        }

        // Text edits are deliberately absent from the key. SwiftUI updates the
        // representable after each keystroke, but an unchanged visual style
        // must not recolor the entire NSTextView again.
        for _ in 0..<1_000 where cache.needsApplying(dark14) {
            failures.append("an unchanged style was reapplied")
            break
        }

        let dracula14 = EditorStyleKey(themeName: AppTheme.dracula.rawValue, fontSize: 14)
        if !cache.needsApplying(dracula14) {
            failures.append("a theme change did not invalidate the style")
        }
        if cache.needsApplying(dracula14) {
            failures.append("the changed theme was applied more than once")
        }

        let dracula18 = EditorStyleKey(themeName: AppTheme.dracula.rawValue, fontSize: 18)
        if !cache.needsApplying(dracula18) {
            failures.append("a font-size change did not invalidate the style")
        }

        var focusState = EditorFocusRestorationState()
        focusState.recordDeactivation(wasFirstResponder: false)
        if focusState.consumeRestorationRequest(isActive: true, windowIsKey: true) {
            failures.append("focus was requested although the editor never owned it")
        }

        focusState.recordDeactivation(wasFirstResponder: true)
        if focusState.consumeRestorationRequest(isActive: false, windowIsKey: true) {
            failures.append("focus was requested while the editor was hidden")
        }
        if focusState.consumeRestorationRequest(isActive: true, windowIsKey: false) {
            failures.append("focus was stolen by a background document window")
        }
        if !focusState.consumeRestorationRequest(isActive: true, windowIsKey: true) {
            failures.append("focus was not restored when returning to Edit")
        }
        if focusState.consumeRestorationRequest(isActive: true, windowIsKey: true) {
            failures.append("focus restoration request was consumed more than once")
        }

        let scrollView = NSTextView.scrollableTextView()
        if let textView = scrollView.documentView as? NSTextView {
            configureEditorBackground(textView, backgroundColor: .magenta)
            if !textView.drawsBackground {
                failures.append("the text view does not paint the theme background")
            }
            if !scrollView.drawsBackground {
                failures.append("the scroll view does not paint the theme background")
            }
            if !scrollView.contentView.drawsBackground {
                failures.append("the clip view does not paint the theme background")
            }
        } else {
            failures.append("could not create the editor scroll surface")
        }

        if failures.isEmpty {
            print("EditorStyleCacheTests: passed")
        } else {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
    }
}

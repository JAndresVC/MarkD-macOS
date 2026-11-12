import SwiftUI
import AppKit

/// A document owns its Find destination even before its editor receives focus.
@MainActor
final class EditorFindController {
    private weak var textView: NSTextView?
    private var isVisible = false

    func attach(_ textView: NSTextView, isVisible: Bool) {
        self.textView = textView
        self.isVisible = isVisible
    }

    func detach(_ textView: NSTextView) {
        guard self.textView === textView else { return }
        self.textView = nil
        isVisible = false
    }

    func perform(_ action: NSTextFinder.Action) {
        guard isVisible, let textView, let window = textView.window,
              window.isKeyWindow, window.attachedSheet == nil else { return }

        // Find must work before the first click in a newly opened document.
        // Next/previous keep the search field focused when its bar is open.
        if action == .showFindInterface, !window.makeFirstResponder(textView) { return }
        let sender = NSMenuItem()
        sender.tag = action.rawValue
        textView.performTextFinderAction(sender)
    }
}

struct EditorFindControllerKey: FocusedValueKey {
    typealias Value = EditorFindController
}

extension FocusedValues {
    var editorFindController: EditorFindController? {
        get { self[EditorFindControllerKey.self] }
        set { self[EditorFindControllerKey.self] = newValue }
    }
}

/// The only values that require restyling the complete NSTextView.
/// Document text is intentionally not part of this key.
struct EditorStyleKey: Equatable {
    let themeName: String
    let fontSize: CGFloat
}

struct EditorStyleCache {
    private var appliedKey: EditorStyleKey?

    mutating func needsApplying(_ key: EditorStyleKey) -> Bool {
        guard appliedKey != key else { return false }
        appliedKey = key
        return true
    }
}

struct EditorFocusRestorationState {
    private var shouldRestore = false

    mutating func recordDeactivation(wasFirstResponder: Bool) {
        if wasFirstResponder { shouldRestore = true }
    }

    mutating func consumeRestorationRequest(isActive: Bool, windowIsKey: Bool) -> Bool {
        guard shouldRestore, isActive, windowIsKey else { return false }
        shouldRestore = false
        return true
    }
}

@MainActor
func configureEditorBackground(_ textView: NSTextView, backgroundColor: NSColor) {
    textView.backgroundColor = backgroundColor
    textView.drawsBackground = true

    guard let scrollView = textView.enclosingScrollView else { return }
    scrollView.backgroundColor = backgroundColor
    scrollView.drawsBackground = true
    scrollView.contentView.backgroundColor = backgroundColor
    scrollView.contentView.drawsBackground = true
}

struct EditorView: View {
    @Binding var text: String
    @Binding var scrollToLine: Int?
    var isEditable: Bool = true
    var isVisible: Bool = true
    var findController: EditorFindController? = nil
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    var body: some View {
        TextEditorRepresentable(
            text: $text,
            scrollToLine: $scrollToLine,
            fontSize: fontSize,
            colors: theme.colors,
            styleKey: EditorStyleKey(themeName: theme.rawValue, fontSize: fontSize),
            isEditable: isEditable,
            isVisible: isVisible,
            findController: findController
        )
        // Fill the complete editor, including the area below short documents.
        .background(theme.colors.background)
    }
}

// MARK: - NSTextView wrapper

private struct TextEditorRepresentable: NSViewRepresentable {
    @Binding var text: String
    @Binding var scrollToLine: Int?
    var fontSize: CGFloat
    var colors: ThemeColors
    var styleKey: EditorStyleKey
    var isEditable: Bool
    var isVisible: Bool
    var findController: EditorFindController?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        // Smart substitutions turn straight quotes/dashes into typographic ones,
        // which corrupts Markdown syntax and code samples.
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.textContainerInset = NSSize(width: 40, height: 24)
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        textView.string = text
        applyStyle(to: textView)
        _ = context.coordinator.styleCache.needsApplying(styleKey)

        context.coordinator.textView = textView
        context.coordinator.findController = findController
        findController?.attach(textView, isVisible: isVisible)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.text = $text
        context.coordinator.isVisible = isVisible
        if context.coordinator.findController !== findController {
            context.coordinator.findController?.detach(textView)
            context.coordinator.findController = findController
        }
        findController?.attach(textView, isVisible: isVisible)

        // RAW remains focusable for selection, copying, and native Find while
        // Preview hides the text view completely.
        textView.isEditable = isEditable
        let wasFirstResponder = textView.window?.firstResponder === textView
        if !isVisible, wasFirstResponder {
            context.coordinator.focusRestorationState.recordDeactivation(
                wasFirstResponder: true
            )
            textView.window?.makeFirstResponder(nil)
        }

        let shouldRestoreFocus = context.coordinator.focusRestorationState
            .consumeRestorationRequest(
                isActive: isVisible,
                windowIsKey: textView.window?.isKeyWindow == true
            )
        if shouldRestoreFocus {
            DispatchQueue.main.async { [weak textView, weak coordinator = context.coordinator] in
                guard let textView,
                      coordinator?.isVisible == true,
                      let window = textView.window,
                      window.isKeyWindow else { return }
                window.makeFirstResponder(textView)
            }
        }

        // Exact equality already identifies changes originating in this editor.
        // A delayed "updating" flag can suppress an external replacement in the
        // same run-loop turn without scheduling another SwiftUI update.
        if !textView.string.utf8.elementsEqual(text.utf8) {
            let sel = textView.selectedRange()
            // Old text-edit ranges belong to the previous contents. AppKit's
            // string setter does not invalidate them; undoing one after reload
            // can reintroduce stale text or apply a range to a shorter document.
            textView.breakUndoCoalescing()
            textView.undoManager?.removeAllActions()
            textView.string = text
            let maxLen = (text as NSString).length
            let location = min(sel.location, maxLen)
            let length = min(sel.length, maxLen - location)
            textView.setSelectedRange(NSRange(location: location, length: length))
        }

        if context.coordinator.styleCache.needsApplying(styleKey) {
            applyStyle(to: textView)
        }

        if let line = scrollToLine {
            performScroll(to: line, in: textView)
            let binding = $scrollToLine
            DispatchQueue.main.async { binding.wrappedValue = nil }
        }
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        if let textView = scrollView.documentView as? NSTextView {
            coordinator.findController?.detach(textView)
        }
    }

    private func applyStyle(to textView: NSTextView) {
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let nsText = NSColor(colors.text)
        let nsBg = NSColor(colors.background)
        let nsAccent = NSColor(colors.accent)
        configureEditorBackground(textView, backgroundColor: nsBg)
        textView.insertionPointColor = nsAccent
        textView.font = font
        textView.textColor = nsText
        textView.typingAttributes = [.font: font, .foregroundColor: nsText]
        // AppKit grays an inactive selection; keep its text legible in every palette.
        textView.selectedTextAttributes[.foregroundColor] = NSColor.labelColor
    }

    private func performScroll(to lineIndex: Int, in textView: NSTextView) {
        guard let range = editorSourceLineRange(in: textView.string, lineIndex: lineIndex) else { return }
        textView.scrollRangeToVisible(range)
        textView.setSelectedRange(NSRange(location: range.location, length: 0))
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        // Plain Binding (not @Binding) so updateNSView can swap in the latest
        // binding — the one captured at init goes stale if the representable
        // is recreated for a different document.
        var text: Binding<String>
        weak var textView: NSTextView?
        weak var findController: EditorFindController?
        var isVisible = true
        var styleCache = EditorStyleCache()
        var focusRestorationState = EditorFocusRestorationState()

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            // Swift String equality treats composed/decomposed Unicode as equal.
            // An editor must preserve the exact source that will be saved.
            guard let tv = notification.object as? NSTextView,
                  !tv.string.utf8.elementsEqual(text.wrappedValue.utf8) else { return }
            text.wrappedValue = tv.string
        }
    }
}

/// Locate parser line numbers in the original UTF-16 source. Do not normalize
/// the document: CRLF occupies two code units and emoji can occupy several.
func editorSourceLineRange(in text: String, lineIndex: Int) -> NSRange? {
    guard lineIndex >= 0 else { return nil }
    let source = text as NSString
    var currentLine = 0
    var start = 0
    var cursor = 0
    while cursor < source.length {
        let character = source.character(at: cursor)
        if character == 10 || character == 13 {
            if currentLine == lineIndex {
                return NSRange(location: start, length: cursor - start)
            }
            if character == 13, cursor + 1 < source.length,
               source.character(at: cursor + 1) == 10 {
                cursor += 1
            }
            currentLine += 1
            start = cursor + 1
        }
        cursor += 1
    }
    return currentLine == lineIndex
        ? NSRange(location: start, length: source.length - start)
        : nil
}

#Preview {
    EditorView(
        text: .constant("# Hello\n\nSome **bold** text."),
        scrollToLine: .constant(nil)
    )
    .frame(width: 600, height: 400)
}

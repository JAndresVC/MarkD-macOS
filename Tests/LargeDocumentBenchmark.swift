import AppKit
import SwiftUI

/// Optimized, reproducible observations; no machine-dependent timing assertions.
@main
@MainActor
enum LargeDocumentBenchmark {
    static func measure<T>(_ label: String, _ operation: () -> T) -> T {
        let start = ContinuousClock.now
        let value = operation()
        let elapsed = start.duration(to: .now).components
        print("\(label): \(String(format: "%.2f", Double(elapsed.seconds) * 1000 + Double(elapsed.attoseconds) / 1e15)) ms")
        fflush(stdout)
        return value
    }

    static func main() {
        _ = NSApplication.shared
        for chapters in [100, 500, 1500] {
            let paragraph = String(repeating: "Texto del libro **fuerza** y *movimiento*, café 日本語 👩🏽‍💻. ", count: 12)
            let source = (0..<chapters).map { "## Capítulo \($0)\n\n" + String(repeating: paragraph + "\n\n", count: 3) }.joined()
            print("BOOK \(chapters) chapters, \(source.utf8.count) bytes")
            let headings = measure("outline") { parseHeadings(from: source) }
            precondition(headings.count == chapters)
            let blocks = measure("parse") { parseBlocks(from: source) }
            precondition(blocks.count == chapters * 4)
            let matches = measure("search") { previewSearchMatches(in: blocks, query: "fuerza") }
            precondition(matches.count == chapters * 36)
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                                  styleMask: [.titled], backing: .buffered, defer: false)
            let host = NSHostingView(rootView: MarkdownPreviewView(markdown: source, scrollToLine: .constant(nil)))
            measure("preview initial layout") {
                window.contentView = host
                host.layoutSubtreeIfNeeded()
            }
            let readyStart = ContinuousClock.now
            let deadline = Date().addingTimeInterval(15)
            var longestTurn = 0.0
            while scrollHeight(in: host) < 1000, Date() < deadline {
                let tick = ContinuousClock.now
                RunLoop.main.run(until: Date().addingTimeInterval(0.005))
                host.layoutSubtreeIfNeeded()
                longestTurn = max(longestTurn, milliseconds(tick.duration(to: .now)))
            }
            precondition(scrollHeight(in: host) >= 1000, "preview never became ready")
            print("preview content ready: \(String(format: "%.2f", milliseconds(readyStart.duration(to: .now)))) ms; longest observed UI turn: \(String(format: "%.2f", longestTurn)) ms")
            fflush(stdout)
            window.contentView = nil
        }
        for count in [1000, 2000, 4000] {
            let text = String(repeating: "word café 日本語 🚀 ", count: count)
            let blocks = [MarkdownBlock(lineNumber: 0, content: .paragraph(AttributedString(text)))]
            let matches = previewSearchMatches(in: blocks, query: "word")
            let highlighted = measure("highlights \(count)") {
                applyingPreviewSearchHighlights(to: AttributedString(text), matches: matches,
                                                activeMatchID: count - 1, colors: AppTheme.light.colors)
            }
            precondition(String(highlighted.characters) == text)
        }
    }

    private static func milliseconds(_ duration: Duration) -> Double {
        let c = duration.components
        return Double(c.seconds) * 1000 + Double(c.attoseconds) / 1e15
    }

    private static func scrollHeight(in view: NSView) -> CGFloat {
        if let scroll = view as? NSScrollView { return scroll.documentView?.bounds.height ?? 0 }
        return view.subviews.map { scrollHeight(in: $0) }.max() ?? 0
    }
}

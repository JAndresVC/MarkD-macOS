import AppKit
import SwiftUI

@MainActor
private final class PreviewDocumentState: ObservableObject {
    @Published var source: String
    @Published var line: Int?
    init(_ source: String) { self.source = source }
}

private struct PreviewDocumentFixture: View {
    @ObservedObject var state: PreviewDocumentState
    var body: some View {
        MarkdownPreviewView(markdown: state.source, scrollToLine: $state.line)
    }
}

@main
@MainActor
enum PreviewDocumentTests {
    static func main() async throws {
        _ = NSApplication.shared
        let offMain = await backgroundMarkdownAnalysis { !Thread.isMainThread }
        precondition(offMain == true, "analysis occupied the UI thread")

        let cancelled = Task {
            await backgroundMarkdownAnalysis {
                let deadline = Date().addingTimeInterval(2)
                while !Task.isCancelled, Date() < deadline { Thread.sleep(forTimeInterval: 0.001) }
                return Task.isCancelled
            }
        }
        try await Task.sleep(for: .milliseconds(20))
        cancelled.cancel()
        let cancelledValue = await cancelled.value
        precondition(cancelledValue == nil, "cancelled analysis published a value")

        try await verifyPreview()
        print("PreviewDocumentTests: 3 groups passed (background, cancellation, lazy navigation/replacement)")
    }

    private static func verifyPreview() async throws {
        let source = (0..<300).map { "## Chapter \($0)\n\n" + String(repeating: "paragraph café 👩🏽‍💻 ", count: 40) + "\n\n" }.joined()
        let state = PreviewDocumentState(source)
        state.line = 299 * 4
        let host = NSHostingView(rootView: PreviewDocumentFixture(state: state))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        try await settle(host, until: { scroll(in: host)?.documentView?.bounds.height ?? 0 > 1000 })
        // A sidebar request can arrive while the background parser is running.
        // Preserve it until lazy blocks exist instead of consuming it early.
        try await settle(host, until: { scroll(in: host)?.contentView.bounds.minY ?? 0 > 10000 })
        state.line = 0
        try await settle(host, until: { scroll(in: host)?.contentView.bounds.minY ?? 1000 < 100 })
        // Rapid replacement must cancel obsolete work and show the short source.
        state.source = String(repeating: source, count: 4)
        try await Task.sleep(for: .milliseconds(5))
        state.source = "# Latest\n\nSmall replacement."
        try await settle(host, until: { scroll(in: host)?.documentView?.bounds.height ?? 1000 < 600 })
        try await Task.sleep(for: .milliseconds(200))
        host.layoutSubtreeIfNeeded()
        precondition(scroll(in: host)?.documentView?.bounds.height ?? 1000 < 600,
                     "obsolete analysis replaced the latest short document")
        precondition(state.source == "# Latest\n\nSmall replacement.", "analysis changed source text")
        window.contentView = nil
    }

    private static func settle(_ host: NSView, until condition: () -> Bool) async throws {
        for _ in 0..<400 {
            host.layoutSubtreeIfNeeded()
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        preconditionFailure("preview did not load or navigate within the test deadline")
    }

    private static func scroll(in view: NSView) -> NSScrollView? {
        if let scroll = view as? NSScrollView { return scroll }
        return view.subviews.lazy.compactMap { scroll(in: $0) }.first
    }
}

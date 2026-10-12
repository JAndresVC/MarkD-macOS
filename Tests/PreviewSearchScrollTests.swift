import SwiftUI
import AppKit

@MainActor
final class SearchSelection: ObservableObject {
    @Published var activeID: Int? = nil
}

private struct SearchFixture: View {
    @ObservedObject var selection: SearchSelection
    let text: String
    let matches: [PreviewSearchMatch]
    let horizontal: Bool

    var body: some View {
        ScrollView(.vertical) {
            if horizontal {
                ScrollView(.horizontal) { content.fixedSize() }
            } else {
                content.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var content: some View {
        PreviewSearchText(text: AttributedString(text), matches: matches,
                          activeMatchID: selection.activeID)
            .font(.system(size: 14, design: .monospaced))
            .textSelection(.enabled)
    }
}

@main
@MainActor
enum PreviewSearchScrollTests {
    static func main() {
        _ = NSApplication.shared
        verify(text: (0..<200).map { "line \($0)" + ([1, 80, 160].contains($0) ? " TARGET" : " filler") }.joined(separator: "\n"),
               horizontal: false, axis: "vertical")
        verify(text: "TARGET " + String(repeating: "wide ", count: 300) + " TARGET " + String(repeating: "wide ", count: 300) + " TARGET",
               horizontal: true, axis: "horizontal")
        verify(text: "TARGET " + String(repeating: "wrapped paragraph café 👩🏽‍💻 ", count: 200) + " TARGET " + String(repeating: "wrapped ", count: 200) + " TARGET",
               horizontal: false, axis: "wrapped")
        verify(text: "👩🏽 " + String(repeating: "wrapped café ", count: 200) + " 👩🏽 " + String(repeating: "wrapped ", count: 200) + " 👩🏽",
               horizontal: false, axis: "partial emoji", query: "👩")
        print("PreviewSearchScrollTests: 4 passed")
    }

    private static func verify(text: String, horizontal: Bool, axis: String, query: String = "TARGET") {
        let blocks = [MarkdownBlock(lineNumber: 0, content: .paragraph(AttributedString(text)))]
        let matches = previewSearchMatches(in: blocks, query: query)
        let selection = SearchSelection()
        let host = NSHostingView(rootView: SearchFixture(selection: selection, text: text, matches: matches, horizontal: horizontal))
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 420, height: 240),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        settle(host)
        var positions: [CGFloat] = []
        for id in [0, 1, 2, 0] {
            selection.activeID = id
            settle(host)
            let scrolls = descendants(in: host).compactMap { $0 as? NSScrollView }
            positions.append(scrolls.map { horizontal ? $0.contentView.bounds.minX : $0.contentView.bounds.minY }.max() ?? 0)
        }
        guard positions[1] > positions[0] + 100,
              positions[2] > positions[1] + 100,
              positions[3] < 50 else {
            fputs("FAIL: \(axis) matches did not scroll independently and wrap: \(positions)\n", stderr)
            exit(1)
        }
    }

    private static func settle(_ host: NSView) {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.25))
        host.layoutSubtreeIfNeeded()
    }

    private static func descendants(in view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap { descendants(in: $0) }
    }
}

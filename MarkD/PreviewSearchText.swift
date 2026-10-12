import SwiftUI
import AppKit

private struct ActivePreviewMatch: TextAttribute {}

/// Retains SwiftUI Text selection, links, accessibility and shaping. Only the
/// active range carries a layout attribute; no estimate from character counts
/// or a second text layout engine is needed to locate wrapped/Unicode text.
struct PreviewSearchText: View {
    let text: AttributedString
    let matches: [PreviewSearchMatch]
    let activeMatchID: Int?

    var body: some View {
        if let match = matches.first(where: { $0.id == activeMatchID }),
           let range = attributedRange(match.characterRange, in: text) {
            let before = Text(AttributedString(text[text.startIndex..<range.lowerBound]))
            let active = Text(AttributedString(text[range])).customAttribute(ActivePreviewMatch())
            let after = Text(AttributedString(text[range.upperBound..<text.endIndex]))
            Text("\(before)\(active)\(after)")
                .backgroundPreferenceValue(Text.LayoutKey.self) { layouts in
                    GeometryReader { geometry in
                        if let target = activeBounds(in: layouts, geometry: geometry) {
                            PreviewMatchScrollAnchor(match: match, rect: target)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                }
        } else {
            Text(text)
        }
    }

    private func attributedRange(_ offsets: Range<Int>, in source: AttributedString) -> Range<AttributedString.Index>? {
        let characters = source.characters
        guard offsets.lowerBound >= 0, !offsets.isEmpty,
              let start = characters.index(characters.startIndex, offsetBy: offsets.lowerBound,
                                           limitedBy: characters.endIndex),
              let end = characters.index(characters.startIndex, offsetBy: offsets.upperBound,
                                         limitedBy: characters.endIndex) else { return nil }
        return start..<end
    }

    private func activeBounds(in layouts: [Text.LayoutKey.AnchoredLayout], geometry: GeometryProxy) -> CGRect? {
        for anchored in layouts {
            for line in anchored.layout {
                for run in line where run[ActivePreviewMatch.self] != nil {
                    // Reveal the beginning even when a multi-line query is
                    // itself larger than the viewport.
                    let origin = geometry[anchored.origin]
                    return run.typographicBounds.rect.offsetBy(dx: origin.x, dy: origin.y)
                }
            }
        }
        return nil
    }
}

private struct PreviewMatchScrollAnchor: NSViewRepresentable {
    let match: PreviewSearchMatch
    let rect: CGRect

    func makeNSView(context: Context) -> PreviewMatchTrackingView {
        PreviewMatchTrackingView()
    }

    func updateNSView(_ view: PreviewMatchTrackingView, context: Context) {
        view.target = PreviewMatchTrackingView.Target(match: match, rect: rect)
    }
}

private final class PreviewMatchTrackingView: NSView {
    struct Target: Equatable {
        let match: PreviewSearchMatch
        let rect: CGRect
    }

    var target: Target? {
        didSet {
            guard target != oldValue else { return }
            scheduleReveal()
        }
    }
    private var revealedTarget: Target?
    override var isFlipped: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        scheduleReveal()
    }

    override func layout() {
        super.layout()
        scheduleReveal()
    }

    private func scheduleReveal() {
        guard target != revealedTarget else { return }
        DispatchQueue.main.async { [weak self] in self?.revealIfNeeded() }
    }

    private func revealIfNeeded() {
        guard window != nil, let target, target != revealedTarget,
              bounds.width > 0, bounds.height > 0,
              enclosingScrollView != nil else { return }
        revealedTarget = target
        // Walk from inner to outer: code has a horizontal scroller inside the
        // document's vertical scroller. Convert again after each scroll.
        var ancestor = superview
        while let view = ancestor {
            if let scroll = view as? NSScrollView, let document = scroll.documentView {
                var rect = document.convert(target.rect, from: self)
                rect.size.width = min(rect.width, max(1, scroll.contentView.bounds.width - 24))
                rect.size.height = min(rect.height, max(1, scroll.contentView.bounds.height - 24))
                document.scrollToVisible(rect.insetBy(dx: -12, dy: -12))
            }
            ancestor = view.superview
        }
    }
}

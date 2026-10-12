import Foundation

/// Swift String equality normalizes Unicode; source offsets require exact bytes.
struct MarkdownSource: Equatable, Sendable {
    let text: String
    init(_ text: String) { self.text = text }
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text.utf8.elementsEqual(rhs.text.utf8)
    }
}

/// SwiftUI owns cancellation and publication; parsing never occupies its actor.
func backgroundMarkdownAnalysis<Value: Sendable>(
    _ compute: @escaping @Sendable () -> Value
) async -> Value? {
    let worker = Task.detached(priority: .userInitiated, operation: compute)
    let result = await withTaskCancellationHandler {
        await worker.value
    } onCancel: {
        worker.cancel()
    }
    return Task.isCancelled ? nil : result
}

/// A bounded, view-owned memoization helper. The source of truth remains the
/// view's inputs; reading this cache never publishes a SwiftUI state change.
/// Keep it on the UI thread and include every derivation input in the key.
final class DerivedValueCache<Key: Equatable, Value> {
    private var entry: (key: Key, value: Value)?

    func value(for key: Key, compute: () -> Value) -> Value {
        if let entry, entry.key == key { return entry.value }
        let value = compute()
        entry = (key, value)
        return value
    }
}

struct PreviewAnalysis {
    let blocks: [MarkdownBlock]
    let matches: [PreviewSearchMatch]
    let matchesByBlock: [Int: [PreviewSearchMatch]]
}

final class PreviewAnalysisCache {
    private struct SearchKey: Equatable {
        let markdown: MarkdownSource
        let query: String
        let locale: Locale
    }
    private let blocks = DerivedValueCache<MarkdownSource, [MarkdownBlock]>()
    private let results = DerivedValueCache<SearchKey, PreviewAnalysis>()
    private let parse: (String) -> [MarkdownBlock]
    private let search: ([MarkdownBlock], String, Locale) -> [PreviewSearchMatch]

    init(parse: @escaping (String) -> [MarkdownBlock] = { parseBlocks(from: $0) },
         search: @escaping ([MarkdownBlock], String, Locale) -> [PreviewSearchMatch] = {
             previewSearchMatches(in: $0, query: $1, locale: $2)
         }) {
        self.parse = parse
        self.search = search
    }

    func value(markdown: String, query: String, locale: Locale = .current,
               preparedBlocks: [MarkdownBlock]? = nil) -> PreviewAnalysis {
        let source = MarkdownSource(markdown)
        let key = SearchKey(markdown: source, query: query, locale: locale)
        return results.value(for: key) {
            let parsed = blocks.value(for: source) { preparedBlocks ?? parse(markdown) }
            let matches = search(parsed, query, locale)
            return PreviewAnalysis(blocks: parsed, matches: matches,
                                   matchesByBlock: Dictionary(grouping: matches, by: \.blockLine))
        }
    }
}

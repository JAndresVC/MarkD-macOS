import Foundation

@main
enum PreviewSearchTests {
    static func main() {
        testSearchUsesRenderedTextAndEveryBlockType()
        testSearchIsCaseAndDiacriticInsensitive()
        testSearchUsesNonOverlappingMatches()
        testSelectionNavigationWraps()
        testPartialGraphemesHaveVisibleRanges()
        testAnalysisCacheInvalidation()
        testDerivedCacheIsBoundedAndIndependent()
        testExactSourceAndPreparedBlocks()
        print("PreviewSearchTests: 8 passed")
    }

    private static func testSearchUsesRenderedTextAndEveryBlockType() {
        let blocks = parseBlocks(from: """
        # Alpha

        **Alpha** and alpha.

        > Alpha quote

        - Alpha item
        - second Alpha

        ```swift
        let alpha = "Alpha"
        ```
        """)
        let matches = previewSearchMatches(in: blocks, query: "alpha")

        guard matches.count == 8 else {
            fail("expected 8 rendered matches, got \(matches.count)")
        }
        guard Set(matches.map(\.blockLine)).count == 5 else {
            fail("search did not cover headings, paragraphs, quotes, lists, and code")
        }
        guard matches.filter({ $0.blockLine == 6 }).map(\.segmentIndex) == [0, 1] else {
            fail("list matches did not preserve their item index")
        }
        guard previewSearchMatches(in: blocks, query: "**").isEmpty else {
            fail("Markdown formatting markers should not be searchable in Preview")
        }
    }

    private static func testSearchIsCaseAndDiacriticInsensitive() {
        let blocks = parseBlocks(from: "# Café\n\nCAFÉ cafe")
        let matches = previewSearchMatches(in: blocks, query: "cafe")
        guard matches.count == 3 else {
            fail("case/diacritic-insensitive search returned \(matches.count) matches")
        }
    }

    private static func testSearchUsesNonOverlappingMatches() {
        let blocks = parseBlocks(from: "aaaa")
        let matches = previewSearchMatches(in: blocks, query: "aa")
        guard matches.map(\.characterRange) == [0..<2, 2..<4] else {
            fail("expected two non-overlapping ranges, got \(matches.map(\.characterRange))")
        }
        guard previewSearchMatches(in: blocks, query: "").isEmpty else {
            fail("an empty query should not return matches")
        }
    }

    private static func testSelectionNavigationWraps() {
        guard previewSearchIndex(after: 2, total: 3, direction: .next) == 0,
              previewSearchIndex(after: 0, total: 3, direction: .previous) == 2,
              previewSearchIndex(after: 0, total: 0, direction: .next) == nil else {
            fail("match navigation did not wrap safely")
        }
    }

    private static func testPartialGraphemesHaveVisibleRanges() {
        let cases: [(String, String, [Range<Int>])] = [
            ("👨‍👩‍👧‍👦👨‍👩‍👧‍👦", "👩", [0..<1, 1..<2]),
            ("👩🏽👩🏽", "👩", [0..<1, 1..<2]),
            ("🇨🇷🇨🇷", "🇨", [0..<1, 1..<2]),
            ("ｶﾞｶﾞｶﾞ", "ｶ", [0..<1, 1..<2, 2..<3]),
            ("👩‍👩‍👧‍👧", "👩", [0..<1]),
            ("x👩🏽a👩🏽a", "👩🏽a", [1..<3, 3..<5]),
            ("e\u{301} é", "e", [0..<1, 2..<3]),
            ("Straße STRASSE", "strasse", [0..<6, 7..<14])
        ]
        for (text, query, expected) in cases {
            let actual = previewSearchMatches(in: parseBlocks(from: text), query: query)
                .map(\.characterRange)
            guard actual == expected else {
                fail("\(text) / \(query): expected \(expected), got \(actual)")
            }
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }

    private static func testAnalysisCacheInvalidation() {
        var parses = 0
        var searches = 0
        let cache = PreviewAnalysisCache(parse: {
            parses += 1
            return parseBlocks(from: $0)
        }, search: {
            searches += 1
            return previewSearchMatches(in: $0, query: $1, locale: $2)
        })
        let english = Locale(identifier: "en_US")
        for _ in 0..<10 {
            let result = cache.value(markdown: "# alpha", query: "alpha", locale: english)
            guard result.matchesByBlock[0]?.count == 1 else { fail("cached grouping lost matches") }
        }
        guard parses == 1, searches == 1 else { fail("unchanged analysis was recomputed") }
        let changed = cache.value(markdown: "# xx alpha", query: "alpha", locale: english)
        guard parses == 2, searches == 2, changed.matches.first?.characterRange == 3..<8 else {
            fail("text changed with same match count but cache did not invalidate")
        }
        let closed = cache.value(markdown: "# xx alpha", query: "", locale: english)
        guard parses == 2, searches == 3, closed.matches.isEmpty else { fail("query invalidation failed") }
        _ = cache.value(markdown: "# xx alpha", query: "", locale: Locale(identifier: "tr_TR"))
        guard parses == 2, searches == 4 else { fail("locale invalidation failed") }
        let other = PreviewAnalysisCache().value(markdown: "# beta", query: "alpha")
        guard other.matches.isEmpty else { fail("analysis leaked between documents") }
    }

    private static func testDerivedCacheIsBoundedAndIndependent() {
        let cache = DerivedValueCache<String, [MarkdownHeading]>()
        var parses = 0
        func outline(_ source: String) -> [MarkdownHeading] {
            cache.value(for: source) { parses += 1; return parseHeadings(from: source) }
        }
        _ = outline("# one")
        _ = outline("# one")
        guard parses == 1 else { fail("outline was recomputed for unchanged source") }
        guard outline("# two").first?.title == "two", parses == 2 else { fail("stale outline") }
        _ = outline("# one")
        guard parses == 3 else { fail("cache retained historical entries instead of one snapshot") }
    }

    private static func testExactSourceAndPreparedBlocks() {
        let composed = "caf\u{e9} word"
        let decomposed = "cafe\u{301} word"
        guard composed == decomposed,
              MarkdownSource(composed) != MarkdownSource(decomposed) else {
            fail("source identity did not distinguish exact Unicode bytes")
        }
        var parses = 0
        let cache = PreviewAnalysisCache(parse: { parses += 1; return parseBlocks(from: $0) })
        let first = cache.value(markdown: composed, query: "word")
        let second = cache.value(markdown: decomposed, query: "word")
        guard parses == 2, first.matches.count == 1, second.matches.count == 1 else {
            fail("canonical-equivalent source replacement reused stale blocks")
        }
        let source = "# Already prepared"
        let prepared = parseBlocks(from: source)
        let third = cache.value(markdown: source, query: "prepared", preparedBlocks: prepared)
        guard parses == 2, third.matches.count == 1 else {
            fail("prepared background blocks were parsed again on the UI thread")
        }
    }
}

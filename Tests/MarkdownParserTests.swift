import Foundation

@main
struct MarkdownParserTests {
    static func main() {
        testRepeatedOrderedMarkersAdvanceSequentially()
        testParenthesizedOrderedMarkersAreRecognized()
        testIndentedContinuationStaysInsideListItem()
        testClosingHashesAreNotPartOfHeadingText()
        testEmptyBulletMarkerRemainsAListItem()
        testEmptyOrderedMarkerRemainsAListItem()
        testNestedOrderedListsKeepIndependentCounters()
        testMixedDocumentsKeepUniqueBlockIdentifiers()
        testWindowsLineEndingsParseLikeNativeLineEndings()
        testEmptyATXHeadingsArePreserved()
        testOversizedOrderedMarkersRemainText()
        testLargestAcceptedOrderedMarkerAdvances()
        testOutlineMatchesPreviewAroundListContinuations()
        testInitialBOMDoesNotHideMarkdownSyntax()
        testInteriorBOMRemainsContent()
        print("MarkdownParserTests: 15 passed")
    }

    private static func testInitialBOMDoesNotHideMarkdownSyntax() {
        var failures = [String]()
        for separator in ["\n", "\r\n", "\r"] {
            let headingSource = "\u{feff}# First\(separator)\(separator)## Second"
            let originalBytes = Data(headingSource.utf8)
            let blocks = parseBlocks(from: headingSource)
            let headings = parseHeadings(from: headingSource)
            if blocks.count != 2 || blocks.first.map({
                if case .heading(level: 1, let text) = $0.content {
                    return $0.lineNumber == 0 && String(text.characters) == "First"
                }
                return false
            }) != true || headings.map(\.title) != ["First", "Second"]
                || headings.map(\.lineNumber) != [0, 2] {
                failures.append("initial BOM hides ATX heading for \(separator.debugDescription)")
            }

            let fencedSource = "\u{feff}```swift\(separator)# Code only\(separator)```\(separator)# Visible"
            let fencedBlocks = parseBlocks(from: fencedSource)
            if fencedBlocks.count != 2 || fencedBlocks.first.map({
                if case .code(let code, language: let language) = $0.content {
                    return $0.lineNumber == 0 && code == "# Code only" && language == "swift"
                }
                return false
            }) != true || parseHeadings(from: fencedSource).map(\.title) != ["Visible"]
                || parseHeadings(from: fencedSource).map(\.lineNumber) != [3] {
                failures.append("initial BOM hides opening fence for \(separator.debugDescription)")
            }
            if Data(headingSource.utf8) != originalBytes {
                failures.append("parser changed original source bytes")
            }
        }
        if !failures.isEmpty { fail(failures.joined(separator: "; ")) }
    }

    private static func testInteriorBOMRemainsContent() {
        let source = "\u{feff}literal\u{feff}middle\n\n# Tit\u{feff}le\n\n```text\n\u{feff}# code\n```"
        let blocks = parseBlocks(from: source)
        guard blocks.count == 3,
              case .paragraph(let paragraph) = blocks[0].content,
              String(paragraph.characters) == "literal\u{feff}middle",
              case .heading(_, let heading) = blocks[1].content,
              String(heading.characters) == "Tit\u{feff}le",
              case .code(let code, language: _) = blocks[2].content,
              code == "\u{feff}# code",
              parseHeadings(from: source).map(\.title) == ["Tit\u{feff}le"] else {
            fail("only the first document BOM may be ignored; interior U+FEFF is content")
        }
        // The inline system renderer can omit a leading U+FEFF, but a second
        // BOM must still prevent block syntax from being interpreted as Markdown.
        let doubledSource = "\u{feff}\u{feff}# Literal"
        guard let first = parseBlocks(from: doubledSource).first,
              case .paragraph = first.content,
              parseHeadings(from: doubledSource).isEmpty else {
            fail("parser ignored more than one leading BOM")
        }
    }

    private static func testOversizedOrderedMarkersRemainText() {
        for marker in ["1000000000", String(Int.max), String(repeating: "9", count: 100)] {
            let source = "\(marker). first"
            let blocks = parseBlocks(from: source)
            guard blocks.count == 1, case .paragraph(let text) = blocks[0].content,
                  String(text.characters) == source else {
                fail("oversized ordered marker should remain literal text: \(marker)")
            }
            // The original crash occurred when a second item incremented Int.max.
            _ = parseBlocks(from: source + "\n1. second\n1. third")
        }
    }

    private static func testLargestAcceptedOrderedMarkerAdvances() {
        let blocks = parseBlocks(from: "999999999. first\n1. second\n1. third")
        guard blocks.count == 1, case .orderedList(let items) = blocks[0].content,
              items.compactMap(\.displayNumber) == [999999999, 1000000000, 1000000001] else {
            fail("a nine-digit starting marker must keep consecutive numbering")
        }
    }

    private static func testOutlineMatchesPreviewAroundListContinuations() {
        let fragments = [
            "- item\n  continuation\n---",
            "1. item\n   continuation\n===",
            "- parent\n  - child\n    continued\n---",
            "- item\n  continued\n\nReal heading\n---",
            "- item\n  continued\n# Real heading",
            "- item\n  continued\n~~~\n# code\n~~~\nReal heading\n===",
            "- item\n  continued\n> quote\nReal heading\n---",
            "- item\nUnindented heading\n---",
            "First line\nSecond line\n---"
        ]
        for separator in ["\n", "\r\n", "\r"] {
            for fragment in fragments {
                let source = fragment.replacingOccurrences(of: "\n", with: separator)
                let rendered = parseBlocks(from: source).compactMap { block -> String? in
                    guard case .heading(let level, let text) = block.content else { return nil }
                    return "\(block.lineNumber):\(level):\(String(text.characters))"
                }
                let outline = parseHeadings(from: source).map {
                    "\($0.lineNumber):\($0.level):\($0.title)"
                }
                guard outline == rendered else {
                    fail("outline disagrees with preview for \(fragment.debugDescription): \(outline) vs \(rendered)")
                }
            }
        }
    }

    private static func testParenthesizedOrderedMarkersAreRecognized() {
        let blocks = parseBlocks(from: """
        3) Third
        4) Fourth
        """)

        guard blocks.count == 1,
              case .orderedList(let items) = blocks[0].content else {
            fail("ordered markers ending in ')' should form an ordered list")
        }

        guard items.compactMap(\.displayNumber) == [3, 4] else {
            fail("parenthesized ordered markers lost their starting number")
        }
    }

    private static func testIndentedContinuationStaysInsideListItem() {
        let blocks = parseBlocks(from: """
        - First line
          continuation with **formatting**
        - Second item
        """)

        guard blocks.count == 1,
              case .bulletList(let items) = blocks[0].content,
              items.count == 2 else {
            fail("an indented continuation should remain in its list item")
        }

        let firstItem = String(items[0].text.characters)
        guard firstItem.contains("First line"),
              firstItem.contains("continuation with formatting") else {
            fail("list continuation text or formatting was lost: \(firstItem)")
        }
    }

    private static func testClosingHashesAreNotPartOfHeadingText() {
        let blocks = parseBlocks(from: "## Release notes ###")

        guard blocks.count == 1,
              case .heading(_, let heading) = blocks[0].content else {
            fail("expected one ATX heading")
        }

        guard String(heading.characters) == "Release notes" else {
            fail("closing hashes leaked into heading text: \(heading)")
        }
    }

    private static func testEmptyBulletMarkerRemainsAListItem() {
        let blocks = parseBlocks(from: """
        -
        - Second item
        """)

        guard blocks.count == 1,
              case .bulletList(let items) = blocks[0].content,
              items.count == 2 else {
            fail("an empty bullet marker should remain part of its list")
        }

        guard String(items[0].text.characters).isEmpty else {
            fail("empty bullet item unexpectedly gained content")
        }
    }

    private static func testEmptyOrderedMarkerRemainsAListItem() {
        let blocks = parseBlocks(from: """
        3.
        1. Next item
        """)

        guard blocks.count == 1,
              case .orderedList(let items) = blocks[0].content,
              items.count == 2 else {
            fail("an empty ordered marker should remain part of its list")
        }

        guard items.compactMap(\.displayNumber) == [3, 4] else {
            fail("empty ordered item broke sequential numbering")
        }
    }

    private static func testNestedOrderedListsKeepIndependentCounters() {
        let blocks = parseBlocks(from: """
        3. Outer
          8. Nested
          1. Nested second
        1. Outer second
        """)

        guard blocks.count == 1,
              case .orderedList(let items) = blocks[0].content else {
            fail("expected one nested ordered list")
        }

        guard items.compactMap(\.displayNumber) == [3, 8, 9, 4] else {
            fail("nested ordered counters interfered with one another")
        }
    }

    private static func testMixedDocumentsKeepUniqueBlockIdentifiers() {
        let fragments = [
            "# Heading",
            "paragraph\ncontinuation",
            "- item\n  continuation",
            "1. first\n1. second",
            "> quote\n> continued",
            "```swift\n# code\n```",
            "Setext\n------",
            "***"
        ]

        for rotation in fragments.indices {
            let document = Array(fragments[rotation...] + fragments[..<rotation])
                .joined(separator: "\n\n")
            let blocks = parseBlocks(from: document)
            let identifiers = blocks.map(\.id)
            guard Set(identifiers).count == identifiers.count else {
                fail("mixed document produced duplicate block IDs: \(identifiers)")
            }
        }
    }

    private static func testRepeatedOrderedMarkersAdvanceSequentially() {
        let blocks = parseBlocks(from: """
        1. Alpha
        1. Beta
        1. Gamma
        """)

        guard blocks.count == 1,
              case .orderedList(let items) = blocks[0].content else {
            fail("expected one ordered-list block")
        }

        let actual = items.compactMap(\.displayNumber)
        guard actual == [1, 2, 3] else {
            fail("repeated source markers should render as [1, 2, 3], got \(actual)")
        }
    }

    private static func testWindowsLineEndingsParseLikeNativeLineEndings() {
        let markdown = "# Main\r\n\r\nSecondary\r\n---\r\n\r\n```swift\r\nlet value = 42\r\n```\r\n\r\n- item\r\n"
        let blocks = parseBlocks(from: markdown)

        guard blocks.count == 4 else {
            fail("CRLF document should produce four blocks, got \(blocks.count)")
        }
        guard case .heading(level: 1, let main) = blocks[0].content,
              String(main.characters) == "Main" else {
            fail("CRLF leaked into the ATX heading")
        }
        guard case .heading(level: 2, let secondary) = blocks[1].content,
              String(secondary.characters) == "Secondary" else {
            fail("CRLF prevented a Setext heading from parsing")
        }
        guard case .code(let code, language: let language) = blocks[2].content,
              language == "swift", code == "let value = 42" else {
            fail("CRLF prevented the fenced code block from closing")
        }
        guard case .bulletList(let items) = blocks[3].content,
              items.count == 1,
              String(items[0].text.characters) == "item" else {
            fail("CRLF leaked into a list item")
        }

        let headings = parseHeadings(from: markdown)
        guard headings.map(\.title) == ["Main", "Secondary"] else {
            fail("CRLF outline headings diverged from preview headings")
        }
    }

    private static func testEmptyATXHeadingsArePreserved() {
        let markdown = "##\n#\n### ###"
        let blocks = parseBlocks(from: markdown)

        guard blocks.count == 3 else {
            fail("empty ATX headings should produce three blocks, got \(blocks.count)")
        }

        let parsed = blocks.compactMap { block -> (Int, String)? in
            guard case .heading(let level, let text) = block.content else { return nil }
            return (level, String(text.characters))
        }
        guard parsed.map(\.0) == [2, 1, 3], parsed.allSatisfy({ $0.1.isEmpty }) else {
            fail("empty ATX heading levels/content were parsed incorrectly: \(parsed)")
        }

        let outline = parseHeadings(from: markdown)
        guard outline.map(\.level) == [2, 1, 3],
              outline.allSatisfy({ $0.title.isEmpty }) else {
            fail("outline discarded empty ATX headings")
        }
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
        exit(1)
    }
}

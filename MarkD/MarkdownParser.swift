import Foundation

// MARK: - Parsed Markdown Model

struct MarkdownBlock: Identifiable, Sendable {
    // A block's first source line is stable enough to keep SwiftUI identity
    // predictable while the document is edited.
    var id: Int { lineNumber }
    let lineNumber: Int
    let content: BlockContent
}

struct ListItem: Sendable {
    let indent: Int
    let text: AttributedString
    let displayNumber: Int?
}

enum BlockContent: Sendable {
    case heading(level: Int, text: AttributedString)
    case paragraph(AttributedString)
    case code(String, language: String)
    case blockquote(AttributedString)
    case bulletList([ListItem])
    case orderedList([ListItem])
    case divider
}

struct MarkdownHeading: Sendable {
    let lineNumber: Int
    let level: Int
    let title: String
}

// MARK: - Block Parser

private enum ListKind { case bullet, ordered }

private struct FenceDescriptor {
    let marker: Character
    let length: Int
    let info: String
}

func parseBlocks(from markdown: String) -> [MarkdownBlock] {
    var blocks = [MarkdownBlock]()
    let lines = markdownLines(from: markdown)

    var activeFence: FenceDescriptor?
    var codeLines = [String]()
    var codeBlockStart = 0

    var listKind: ListKind?
    var listItems = [ListItem]()
    var listBlockStart = 0

    var quoteLines = [String]()
    var quoteBlockStart = 0

    var paragraphLines = [String]()
    var paragraphBlockStart = 0

    func flushParagraph() {
        guard !paragraphLines.isEmpty else { return }
        blocks.append(MarkdownBlock(
            lineNumber: paragraphBlockStart,
            content: .paragraph(inlineAttributed(paragraphLines.joined(separator: "\n")))
        ))
        paragraphLines.removeAll()
    }

    func flushList() {
        guard let kind = listKind, !listItems.isEmpty else { return }
        let renderedItems = kind == .ordered
            ? numberedListItems(from: listItems)
            : listItems
        blocks.append(MarkdownBlock(
            lineNumber: listBlockStart,
            content: kind == .bullet ? .bulletList(renderedItems) : .orderedList(renderedItems)
        ))
        listItems.removeAll()
        listKind = nil
    }

    func flushQuote() {
        guard !quoteLines.isEmpty else { return }
        blocks.append(MarkdownBlock(
            lineNumber: quoteBlockStart,
            content: .blockquote(inlineAttributed(quoteLines.joined(separator: "\n")))
        ))
        quoteLines.removeAll()
    }

    for (lineIndex, line) in lines.enumerated() {
        if Task.isCancelled { return [] }
        if let fence = fenceDescriptor(for: line) {
            if let openingFence = activeFence {
                let closesFence = fence.marker == openingFence.marker
                    && fence.length >= openingFence.length
                    && fence.info.isEmpty

                if closesFence {
                    blocks.append(MarkdownBlock(
                        lineNumber: codeBlockStart,
                        content: .code(codeLines.joined(separator: "\n"), language: openingFence.info)
                    ))
                    codeLines.removeAll()
                    activeFence = nil
                } else {
                    codeLines.append(line)
                }
            } else {
                flushParagraph()
                flushList()
                flushQuote()
                activeFence = fence
                codeBlockStart = lineIndex
            }
            continue
        }

        if activeFence != nil {
            codeLines.append(line)
            continue
        }

        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if let heading = atxHeading(from: line) {
            flushParagraph()
            flushList()
            flushQuote()
            blocks.append(MarkdownBlock(
                lineNumber: lineIndex,
                content: .heading(level: heading.level, text: inlineAttributed(heading.title))
            ))
            continue
        }

        // A line of === or --- directly below text is a Setext heading.
        if let level = setextHeadingLevel(for: trimmed), !paragraphLines.isEmpty {
            let title = paragraphLines.joined(separator: "\n")
            let start = paragraphBlockStart
            paragraphLines.removeAll()
            blocks.append(MarkdownBlock(
                lineNumber: start,
                content: .heading(level: level, text: inlineAttributed(title))
            ))
            continue
        }

        if isThematicBreak(trimmed) {
            flushParagraph()
            flushList()
            flushQuote()
            blocks.append(MarkdownBlock(lineNumber: lineIndex, content: .divider))
            continue
        }

        if trimmed.hasPrefix(">") {
            flushParagraph()
            flushList()
            if quoteLines.isEmpty { quoteBlockStart = lineIndex }
            let content = trimmed.dropFirst().drop(while: { $0 == " " })
            quoteLines.append(String(content))
            continue
        }

        if isBulletListItem(trimmed) {
            flushParagraph()
            flushQuote()
            if listKind == .ordered { flushList() }
            if listKind == nil { listBlockStart = lineIndex }
            listKind = .bullet
            listItems.append(ListItem(
                indent: indentLevel(of: line),
                text: inlineAttributed(trimmed.count == 1 ? "" : String(trimmed.dropFirst(2))),
                displayNumber: nil
            ))
            continue
        }

        if let orderedItem = orderedListItem(from: trimmed) {
            flushParagraph()
            flushQuote()
            if listKind == .bullet { flushList() }
            if listKind == nil { listBlockStart = lineIndex }
            listKind = .ordered
            listItems.append(ListItem(
                indent: indentLevel(of: line),
                text: inlineAttributed(orderedItem.text),
                displayNumber: orderedItem.number
            ))
            continue
        }

        if trimmed.isEmpty {
            flushParagraph()
            flushList()
            flushQuote()
            continue
        }

        if listKind != nil,
           let lastItem = listItems.last,
           indentLevel(of: line) > lastItem.indent {
            var continuedText = lastItem.text
            continuedText += AttributedString("\n")
            continuedText += inlineAttributed(trimmed)
            listItems[listItems.count - 1] = ListItem(
                indent: lastItem.indent,
                text: continuedText,
                displayNumber: lastItem.displayNumber
            )
            continue
        }

        flushList()
        flushQuote()
        if paragraphLines.isEmpty { paragraphBlockStart = lineIndex }
        paragraphLines.append(line)
    }

    if let openingFence = activeFence {
        blocks.append(MarkdownBlock(
            lineNumber: codeBlockStart,
            content: .code(codeLines.joined(separator: "\n"), language: openingFence.info)
        ))
    }
    flushParagraph()
    flushList()
    flushQuote()

    return blocks
}

// Lightweight outline parsing avoids rebuilding every attributed paragraph on
// each editor keystroke while keeping heading rules aligned with the preview.
func parseHeadings(from markdown: String) -> [MarkdownHeading] {
    let lines = markdownLines(from: markdown)
    var headings = [MarkdownHeading]()
    var activeFence: FenceDescriptor?
    var paragraphLines = [String]()
    var paragraphStart = 0
    var listItemIndent: Int?

    func clearParagraph() {
        paragraphLines.removeAll()
        listItemIndent = nil
    }

    for (lineIndex, line) in lines.enumerated() {
        if Task.isCancelled { return [] }
        if let fence = fenceDescriptor(for: line) {
            if let openingFence = activeFence {
                if fence.marker == openingFence.marker,
                   fence.length >= openingFence.length,
                   fence.info.isEmpty {
                    activeFence = nil
                }
            } else {
                activeFence = fence
                clearParagraph()
            }
            continue
        }

        guard activeFence == nil else { continue }
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        if let heading = atxHeading(from: line) {
            clearParagraph()
            headings.append(MarkdownHeading(
                lineNumber: lineIndex,
                level: heading.level,
                title: plainText(from: heading.title)
            ))
            continue
        }

        if let level = setextHeadingLevel(for: trimmed), !paragraphLines.isEmpty {
            headings.append(MarkdownHeading(
                lineNumber: paragraphStart,
                level: level,
                title: plainText(from: paragraphLines.joined(separator: "\n"))
            ))
            clearParagraph()
            continue
        }

        if trimmed.isEmpty || isThematicBreak(trimmed) || trimmed.hasPrefix(">") {
            clearParagraph()
            continue
        }

        if isBulletListItem(trimmed) || orderedListItem(from: trimmed) != nil {
            clearParagraph()
            listItemIndent = indentLevel(of: line)
            continue
        }

        // Match parseBlocks: an indented continuation belongs to its list
        // item, and cannot become a Setext heading when followed by ---/===.
        if let listItemIndent, indentLevel(of: line) > listItemIndent {
            continue
        }
        listItemIndent = nil
        if paragraphLines.isEmpty { paragraphStart = lineIndex }
        paragraphLines.append(line)
    }

    return headings
}

func inlineAttributed(_ text: String) -> AttributedString {
    var options = AttributedString.MarkdownParsingOptions()
    options.allowsExtendedAttributes = true
    options.interpretedSyntax = .inlineOnlyPreservingWhitespace
    return (try? AttributedString(markdown: text, options: options))
        ?? AttributedString(text)
}

// MARK: - Parsing Helpers

/// Markdown accepts LF, CRLF, and legacy CR line endings. Normalizing only the
/// parser input keeps source line numbers stable without rewriting the document.
private func markdownLines(from markdown: String) -> [String] {
    // A document's leading UTF-8 BOM is metadata; interior U+FEFF stays content.
    let source = markdown.first == "\u{feff}" ? String(markdown.dropFirst()) : markdown
    return source
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .components(separatedBy: "\n")
}

private func numberedListItems(from items: [ListItem]) -> [ListItem] {
    var counters = [Int: Int]()

    return items.map { item in
        counters = counters.filter { $0.key <= item.indent }
        let number = counters[item.indent].map { $0 + 1 }
            ?? item.displayNumber
            ?? 1
        counters[item.indent] = number

        return ListItem(
            indent: item.indent,
            text: item.text,
            displayNumber: number
        )
    }
}

private func plainText(from markdown: String) -> String {
    String(inlineAttributed(markdown).characters)
}

private func atxHeading(from line: String) -> (level: Int, title: String)? {
    let candidate = line.drop(while: { $0 == " " || $0 == "\t" })
    let hashes = candidate.prefix(while: { $0 == "#" })
    guard (1...6).contains(hashes.count) else { return nil }

    let rest = candidate.dropFirst(hashes.count)
    guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }
    var title = rest.isEmpty
        ? ""
        : rest.dropFirst().trimmingCharacters(in: .whitespaces)
    let closingHashCount = title.reversed().prefix(while: { $0 == "#" }).count
    if closingHashCount > 0 {
        let beforeClosingHashes = title.dropLast(closingHashCount)
        if beforeClosingHashes.isEmpty || beforeClosingHashes.last?.isWhitespace == true {
            title = beforeClosingHashes.trimmingCharacters(in: .whitespaces)
        }
    }
    return (hashes.count, title)
}

private func setextHeadingLevel(for trimmedLine: String) -> Int? {
    guard !trimmedLine.isEmpty else { return nil }
    if trimmedLine.allSatisfy({ $0 == "=" }) { return 1 }
    if trimmedLine.allSatisfy({ $0 == "-" }) { return 2 }
    return nil
}

private func fenceDescriptor(for line: String) -> FenceDescriptor? {
    let candidate = line.drop(while: { $0 == " " || $0 == "\t" })
    guard let marker = candidate.first, marker == "`" || marker == "~" else { return nil }
    let run = candidate.prefix(while: { $0 == marker })
    guard run.count >= 3 else { return nil }
    let info = candidate.dropFirst(run.count).trimmingCharacters(in: .whitespaces)
    return FenceDescriptor(marker: marker, length: run.count, info: info)
}

private func isThematicBreak(_ trimmedLine: String) -> Bool {
    let compact = trimmedLine.filter { $0 != " " && $0 != "\t" }
    guard compact.count >= 3, let marker = compact.first,
          marker == "-" || marker == "*" || marker == "_" else { return false }
    return compact.allSatisfy { $0 == marker }
}

private func isBulletListItem(_ trimmedLine: String) -> Bool {
    ["-", "*", "+"].contains(trimmedLine)
        || trimmedLine.hasPrefix("- ")
        || trimmedLine.hasPrefix("* ")
        || trimmedLine.hasPrefix("+ ")
}

private func orderedListItem(from trimmedLine: String) -> (number: Int, text: String)? {
    let digits = trimmedLine.prefix(while: { $0.isASCII && $0.isNumber })
    // Bound authored markers before conversion. Larger numbers are literal
    // text, so an Int.max marker can never enter the sequential list counter.
    guard (1...9).contains(digits.count), let number = Int(digits) else { return nil }
    let remainder = trimmedLine.dropFirst(digits.count)
    if remainder == "." || remainder == ")" {
        return (number, "")
    }
    guard remainder.hasPrefix(". ") || remainder.hasPrefix(") ") else { return nil }
    return (number, String(remainder.dropFirst(2)))
}

// Two spaces or one tab represent one visual nesting level.
private func indentLevel(of line: String) -> Int {
    var width = 0
    for character in line {
        if character == " " { width += 1 }
        else if character == "\t" { width += 4 }
        else { break }
    }
    return min(width / 2, 5)
}

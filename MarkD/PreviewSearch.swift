import SwiftUI

struct PreviewSearchMatch: Identifiable, Equatable {
    let id: Int
    let blockLine: Int
    let segmentIndex: Int
    let characterRange: Range<Int>
}

enum PreviewSearchDirection {
    case next
    case previous
}

struct PreviewFindActions {
    let show: () -> Void
    let next: () -> Void
    let previous: () -> Void
    let canNavigate: Bool
}

private struct PreviewFindActionsKey: FocusedValueKey {
    typealias Value = PreviewFindActions
}

extension FocusedValues {
    var previewFindActions: PreviewFindActions? {
        get { self[PreviewFindActionsKey.self] }
        set { self[PreviewFindActionsKey.self] = newValue }
    }
}

func previewSearchMatches(in blocks: [MarkdownBlock], query: String, locale: Locale = .current) -> [PreviewSearchMatch] {
    guard !query.isEmpty else { return [] }

    var matches: [PreviewSearchMatch] = []
    for block in blocks {
        for (segmentIndex, text) in previewSearchSegments(for: block).enumerated() {
            for range in previewSearchRanges(in: text, query: query, locale: locale) {
                matches.append(PreviewSearchMatch(
                    id: matches.count,
                    blockLine: block.lineNumber,
                    segmentIndex: segmentIndex,
                    characterRange: range
                ))
            }
        }
    }
    return matches
}

func previewSearchIndex(
    after currentIndex: Int,
    total: Int,
    direction: PreviewSearchDirection
) -> Int? {
    guard total > 0 else { return nil }
    let safeIndex = min(max(currentIndex, 0), total - 1)
    switch direction {
    case .next:
        return (safeIndex + 1) % total
    case .previous:
        return (safeIndex - 1 + total) % total
    }
}

func applyingPreviewSearchHighlights(
    to source: AttributedString,
    matches: [PreviewSearchMatch],
    activeMatchID: Int?,
    colors: ThemeColors
) -> AttributedString {
    guard !matches.isEmpty else { return source }

    var result = source
    for match in matches {
        let characters = result.characters
        guard let lowerBound = characters.index(
            characters.startIndex,
            offsetBy: match.characterRange.lowerBound,
            limitedBy: characters.endIndex
        ), let upperBound = characters.index(
            characters.startIndex,
            offsetBy: match.characterRange.upperBound,
            limitedBy: characters.endIndex
        ), lowerBound < upperBound else { continue }

        if match.id == activeMatchID {
            result[lowerBound..<upperBound].backgroundColor = colors.selectionBackground
            result[lowerBound..<upperBound].foregroundColor = colors.selectionText
        } else {
            result[lowerBound..<upperBound].backgroundColor = colors.selectionBackground.opacity(0.35)
        }
    }
    return result
}

private func previewSearchSegments(for block: MarkdownBlock) -> [String] {
    switch block.content {
    case .heading(_, let text), .paragraph(let text), .blockquote(let text):
        return [String(text.characters)]
    case .code(let code, _):
        return [code]
    case .bulletList(let items), .orderedList(let items):
        return items.map { String($0.text.characters) }
    case .divider:
        return []
    }
}

private func previewSearchRanges(in text: String, query: String, locale: Locale) -> [Range<Int>] {
    var ranges: [Range<Int>] = []
    var searchStart = text.startIndex
    var characterCursor = text.startIndex
    var characterOffset = 0
    let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]

    while searchStart < text.endIndex,
          let match = text.range(
              of: query,
              options: options,
              range: searchStart..<text.endIndex,
              locale: locale
          ) {
        // Foundation can match only a scalar within an emoji/combined character.
        // Walk grapheme boundaries monotonically, covering the whole visible
        // character instead of producing an empty Character-offset range.
        guard !match.isEmpty else { break }
        while characterCursor < text.endIndex {
            let next = text.index(after: characterCursor)
            guard next <= match.lowerBound else { break }
            characterCursor = next
            characterOffset += 1
        }
        let lowerBound = characterOffset
        while characterCursor < match.upperBound {
            characterCursor = text.index(after: characterCursor)
            characterOffset += 1
        }
        ranges.append(lowerBound..<characterOffset)
        // Skip the covered grapheme: two matching scalars within one displayed
        // character are one navigable result, not duplicate highlights.
        searchStart = characterCursor
    }
    return ranges
}

import SwiftUI

// MARK: - Main View

struct MarkdownPreviewView: View {
    let markdown: String
    @Binding var scrollToLine: Int?
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var activeMatchIndex = 0
    @State private var analysisCache = PreviewAnalysisCache()
    @State private var prepared: (source: MarkdownSource, blocks: [MarkdownBlock])?
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize
    @Environment(\.l10n) private var strings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let source = MarkdownSource(markdown)
        let isReady = prepared?.source == source
        let effectiveQuery = isSearchPresented ? searchText : ""
        let result = isReady
            ? analysisCache.value(markdown: markdown, query: effectiveQuery,
                                  preparedBlocks: prepared?.blocks)
            : PreviewAnalysis(blocks: [], matches: [], matchesByBlock: [:])
        let blocks = result.blocks
        let searchMatches = result.matches
        let searchMatchesByBlock = result.matchesByBlock
        let activeMatch = searchMatches.indices.contains(activeMatchIndex)
            ? searchMatches[activeMatchIndex]
            : nil
        let activeMatchID = activeMatch?.id

        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(blocks) { block in
                        MarkdownBlockView(
                            block: block,
                            searchMatches: searchMatchesByBlock[block.lineNumber, default: []],
                            activeMatchID: activeMatchID
                        )
                            .id(block.lineNumber)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 24)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: isReady ? scrollToLine : nil) { _, newVal in
                guard let line = newVal else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    proxy.scrollTo(line, anchor: .top)
                }
                DispatchQueue.main.async { scrollToLine = nil }
            }
            .onChange(of: activeMatch) { _, match in
                guard let match else { return }
                // Materialize a distant lazy block before its Text geometry
                // reveals the precise match (including horizontal code scroll).
                proxy.scrollTo(match.blockLine, anchor: .top)
                DispatchQueue.main.async {
                    guard isSearchPresented, activeMatchIndex == match.id,
                          searchText == effectiveQuery, prepared?.source == source else { return }
                    proxy.scrollTo(PreviewListRowID(blockLine: match.blockLine,
                                                   segmentIndex: match.segmentIndex), anchor: .top)
                }
            }
        }
        .background(theme.colors.background)
        .overlay {
            if !isReady { ProgressView(strings.loadingDocument) }
        }
        .task(id: source) {
            guard let blocks = await backgroundMarkdownAnalysis({ parseBlocks(from: source.text) }) else { return }
            prepared = (source, blocks)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if isSearchPresented {
                searchBar(matchCount: searchMatches.count)
            }
        }
        .onChange(of: searchText) { _, _ in
            activeMatchIndex = 0
        }
        .onChange(of: searchMatches.count) { _, count in
            if count == 0 {
                activeMatchIndex = 0
            } else if activeMatchIndex >= count {
                activeMatchIndex = count - 1
            }
        }
        .focusedSceneValue(\.previewFindActions, PreviewFindActions(
            show: { showSearch() },
            next: {
                if isSearchPresented {
                    selectMatch(.next, total: searchMatches.count)
                } else {
                    showSearch()
                }
            },
            previous: {
                if isSearchPresented {
                    selectMatch(.previous, total: searchMatches.count)
                } else {
                    showSearch()
                }
            },
            canNavigate: !searchMatches.isEmpty
        ))
    }

    private func selectMatch(_ direction: PreviewSearchDirection, total: Int) {
        guard let newIndex = previewSearchIndex(
            after: activeMatchIndex,
            total: total,
            direction: direction
        ) else { return }
        activeMatchIndex = newIndex
    }

    private func showSearch() {
        isSearchPresented = true
        DispatchQueue.main.async {
            isSearchFieldFocused = true
        }
    }

    private func closeSearch() {
        isSearchFieldFocused = false
        isSearchPresented = false
    }

    private func searchBar(matchCount: Int) -> some View {
        HStack(spacing: 6) {
            Spacer(minLength: 20)

            TextField(strings.findInPreview, text: $searchText)
                .textFieldStyle(.roundedBorder)
                .focused($isSearchFieldFocused)
                .frame(minWidth: 140, idealWidth: 220, maxWidth: 280)
                .onSubmit {
                    selectMatch(.next, total: matchCount)
                }

            Text(matchCount == 0
                 ? (searchText.isEmpty ? "0/0" : strings.noMatches)
                 : "\(activeMatchIndex + 1)/\(matchCount)")
                .foregroundStyle(theme.colors.secondaryText)
                .monospacedDigit()
                .frame(minWidth: 34)

            Button {
                selectMatch(.previous, total: matchCount)
            } label: {
                Image(systemName: "chevron.up")
            }
            .disabled(matchCount == 0)
            .help(strings.findPrevious)
            .accessibilityLabel(strings.findPrevious)

            Button {
                selectMatch(.next, total: matchCount)
            } label: {
                Image(systemName: "chevron.down")
            }
            .disabled(matchCount == 0)
            .help(strings.findNext)
            .accessibilityLabel(strings.findNext)

            Button {
                closeSearch()
            } label: {
                Image(systemName: "xmark")
            }
            .help(strings.closeSearch)
            .accessibilityLabel(strings.closeSearch)
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.colors.divider)
                .frame(height: 1)
        }
        .onExitCommand {
            closeSearch()
        }
    }
}

// MARK: - Block Renderers

private struct MarkdownBlockView: View {
    let block: MarkdownBlock
    let searchMatches: [PreviewSearchMatch]
    let activeMatchID: Int?
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    var body: some View {
        switch block.content {
        case .heading(let level, let text):
            HeadingView(
                level: level,
                text: text,
                searchMatches: searchMatches,
                activeMatchID: activeMatchID
            )
        case .paragraph(let attr):
            PreviewSearchText(text: highlighted(attr, segmentIndex: 0),
                              matches: searchMatches, activeMatchID: activeMatchID)
                .font(.system(size: fontSize))
                .foregroundStyle(theme.colors.text)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)
        case .code(let code, let language):
            CodeBlockView(
                code: code,
                language: language,
                searchMatches: searchMatches,
                activeMatchID: activeMatchID
            )
        case .blockquote(let attr):
            BlockquoteView(
                attributed: attr,
                searchMatches: searchMatches,
                activeMatchID: activeMatchID
            )
        case .bulletList(let items):
            ListBlockView(
                blockLine: block.lineNumber,
                items: items,
                ordered: false,
                searchMatches: searchMatches,
                activeMatchID: activeMatchID
            )
        case .orderedList(let items):
            ListBlockView(
                blockLine: block.lineNumber,
                items: items,
                ordered: true,
                searchMatches: searchMatches,
                activeMatchID: activeMatchID
            )
        case .divider:
            Rectangle()
                .fill(theme.colors.divider)
                .frame(height: 1)
                .padding(.vertical, 12)
        }
    }

    private func highlighted(_ text: AttributedString, segmentIndex: Int) -> AttributedString {
        applyingPreviewSearchHighlights(
            to: text.applyingMarkdownTheme(theme.colors),
            matches: searchMatches.filter { $0.segmentIndex == segmentIndex },
            activeMatchID: activeMatchID,
            colors: theme.colors
        )
    }
}

private struct HeadingView: View {
    let level: Int
    let text: AttributedString
    let searchMatches: [PreviewSearchMatch]
    let activeMatchID: Int?
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PreviewSearchText(text: accessibleThemedText,
                              matches: searchMatches, activeMatchID: activeMatchID)
                // On macOS the header trait exposes AXHeading, while the
                // attributed-string value preserves the exact H1...H6 level.
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(swiftUIHeadingLevel(for: level))
                .font(headingFont)
                .foregroundStyle(theme.colors.heading)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            if level == 2 {
                Rectangle()
                    .fill(theme.colors.divider)
                    .frame(height: 1)
            }
        }
        .padding(.top, level <= 2 ? 20 : 12)
        .padding(.bottom, 6)
    }

    private var headingFont: Font {
        // Scale proportionally relative to base font size (default 14pt)
        let base = fontSize
        switch level {
        case 1: return .system(size: base * 2.0,    weight: .bold)
        case 2: return .system(size: base * 1.571,  weight: .semibold)
        case 3: return .system(size: base * 1.286,  weight: .semibold)
        case 4: return .system(size: base * 1.143,  weight: .semibold)
        case 5: return .system(size: base * 1.0,    weight: .semibold)
        default: return .system(size: base * 0.929, weight: .semibold)
        }
    }

    private var accessibleThemedText: AttributedString {
        textMarkingMarkdownHeading(
            applyingPreviewSearchHighlights(
                to: text.applyingMarkdownTheme(theme.colors),
                matches: searchMatches,
                activeMatchID: activeMatchID,
                colors: theme.colors
            ),
            level: level
        )
    }
}

private struct CodeBlockView: View {
    let code: String
    let language: String
    let searchMatches: [PreviewSearchMatch]
    let activeMatchID: Int?
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            PreviewSearchText(text: applyingPreviewSearchHighlights(
                to: SyntaxHighlighter.highlight(code, language: language, colors: theme.colors),
                matches: searchMatches,
                activeMatchID: activeMatchID,
                colors: theme.colors
            ), matches: searchMatches, activeMatchID: activeMatchID)
                .font(.system(size: max(fontSize - 1, 10), design: .monospaced))
                .foregroundStyle(theme.colors.text)
                .textSelection(.enabled)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.colors.codeBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.colors.codeBorder, lineWidth: 1)
                )
        )
        .padding(.bottom, 12)
    }
}

private struct BlockquoteView: View {
    let attributed: AttributedString
    let searchMatches: [PreviewSearchMatch]
    let activeMatchID: Int?
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.colors.blockquoteBorder)
                .frame(width: 3)
                .padding(.trailing, 12)
            PreviewSearchText(text: applyingPreviewSearchHighlights(
                to: attributed.applyingMarkdownTheme(theme.colors),
                matches: searchMatches,
                activeMatchID: activeMatchID,
                colors: theme.colors
            ), matches: searchMatches, activeMatchID: activeMatchID)
                .font(.system(size: fontSize))
                .foregroundStyle(theme.colors.secondaryText)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 12)
    }
}

struct PreviewListRowID: Hashable {
    let blockLine: Int
    let segmentIndex: Int
}

struct ListBlockView: View {
    let blockLine: Int
    let items: [ListItem]
    let ordered: Bool
    let searchMatches: [PreviewSearchMatch]
    let activeMatchID: Int?
    @Environment(\.appTheme) private var theme
    @Environment(\.editorFontSize) private var fontSize

    private var markers: [String] {
        guard ordered else {
            return items.map { bulletSymbol(for: $0.indent) }
        }
        // The parser resolves sequential numbering per nesting level while
        // preserving an explicitly authored starting number.
        return items.map { "\($0.displayNumber ?? 1)." }
    }

    private func bulletSymbol(for indent: Int) -> String {
        switch indent % 3 {
        case 0:  return "•"
        case 1:  return "◦"
        default: return "▪"
        }
    }

    var body: some View {
        let markers = self.markers
        LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(markers[index])
                        .font(.system(size: fontSize))
                        .foregroundStyle(theme.colors.secondaryText)
                        .monospacedDigit()
                        .frame(minWidth: ordered ? 20 : 10, alignment: .trailing)
                    PreviewSearchText(text: applyingPreviewSearchHighlights(
                        to: item.text.applyingMarkdownTheme(theme.colors),
                        matches: searchMatches.filter { $0.segmentIndex == index },
                        activeMatchID: activeMatchID,
                        colors: theme.colors
                    ), matches: searchMatches.filter { $0.segmentIndex == index },
                                      activeMatchID: activeMatchID)
                        .font(.system(size: fontSize))
                        .foregroundStyle(theme.colors.text)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.leading, CGFloat(item.indent) * 20)
                .id(PreviewListRowID(blockLine: blockLine, segmentIndex: index))
            }
        }
        .padding(.bottom, 12)
    }
}

// MARK: - Preview

#Preview {
    MarkdownPreviewView(markdown: """
    # Hello, MarkD!

    This is **bold**, *italic*, and `inline code`.

    ## A Section

    > A blockquote with *emphasis* and **strong** text.

    - Bullet one
    - Bullet **two**
    - Bullet three

    1. First item
    2. Second item
    3. Third item

    ```swift
    let greeting = "Hello, World!"
    print(greeting)
    ```

    ---

    A [link](https://apple.com) and ~~strikethrough~~ text.
    """, scrollToLine: .constant(nil))
    .frame(width: 600, height: 500)
}

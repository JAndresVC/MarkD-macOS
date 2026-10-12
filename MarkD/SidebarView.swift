import SwiftUI

struct OutlineItem: Identifiable, Sendable {
    let id: Int  // line index in document
    let level: Int
    let title: String
}

private struct OutlineRow: View {
    let item: OutlineItem
    @Environment(\.appTheme) private var theme

    var body: some View {
        let isTop = item.level == 1
        Label {
            Text(item.title)
                .foregroundStyle(isTop ? theme.colors.text : theme.colors.secondaryText)
        } icon: {
            Image(systemName: isTop ? "doc.text" : "list.bullet.indent")
                .foregroundStyle(theme.colors.accent)
        }
            .font(isTop ? .headline : .subheadline)
            .padding(.leading, CGFloat(max(0, item.level - 1) * 10))
            .lineLimit(1)
    }
}

struct SidebarView: View {
    let text: String
    let onHeadingSelected: (OutlineItem) -> Void
    @Environment(\.appTheme) private var theme
    @Environment(\.l10n) private var strings
    @State private var selectedID: OutlineItem.ID?
    @State private var prepared: (source: MarkdownSource, outline: [OutlineItem])?

    var body: some View {
        let source = MarkdownSource(text)
        let isReady = prepared?.source == source
        let outline = prepared?.outline ?? []
        List(outline, selection: $selectedID) { item in
            Button {
                if selectedID == item.id {
                    // List does not emit a selection change when the active
                    // row is clicked again, so re-run navigation explicitly.
                    onHeadingSelected(item)
                } else {
                    // A new row is handled once by onChange below. Calling the
                    // callback here as well would scroll/animate twice.
                    selectedID = item.id
                }
            } label: {
                OutlineRow(item: item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .tag(item.id)
        }
        .listStyle(.sidebar)
        .disabled(!isReady)
        .scrollContentBackground(.hidden)
        .background {
            // Semi-transparent tint over the macOS 26 Liquid Glass sidebar material.
            // Opacity per theme: low = more glass, high = theme color dominant.
            theme.colors.background
                .opacity(theme.sidebarTintOpacity)
        }
        .overlay {
            if !isReady {
                ProgressView(strings.loadingDocument)
            } else if outline.isEmpty {
                ContentUnavailableView(
                    strings.noHeadings,
                    systemImage: "list.bullet.indent",
                    description: Text(strings.noHeadingsHint)
                )
            }
        }
        .navigationTitle(strings.outline)
        .task(id: source) {
            guard let outline = await backgroundMarkdownAnalysis({
                parseHeadings(from: source.text).map { heading in
                    OutlineItem(id: heading.lineNumber, level: heading.level, title: heading.title)
                }
            }) else { return }
            prepared = (source, outline)
        }
        .onChange(of: selectedID) { _, newSelection in
            guard isReady, let newSelection,
                  let item = outline.first(where: { $0.id == newSelection }) else { return }
            onHeadingSelected(item)
        }
        .onChange(of: outline.map(\.id)) { _, validIDs in
            if let selectedID, !validIDs.contains(selectedID) {
                self.selectedID = nil
            }
        }
    }
}

#Preview {
    SidebarView(text: "# Title\n\n## Section\n\n### Subsection\n\nSome text.") { _ in }
        .frame(width: 200, height: 400)
}

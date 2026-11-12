import SwiftUI
import AppKit

/// The system owns the recent-file list and document lifetimes. This scene
/// only supplies entry points; it never reads, saves, or restores file contents.
struct WelcomeView: View {
    @Environment(\.newDocument) private var newDocument
    @Environment(\.openDocument) private var openDocument
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.controlActiveState) private var activeState
    @AppStorage("appLanguage") private var storedLanguage = AppLanguage.system.rawValue
    @State private var recentURLs: [URL] = []
    @State private var openingURL: URL?
    @State private var openError: String?

    private var strings: L10n { AppLanguage.from(stored: storedLanguage).strings }

    var body: some View {
        WelcomeContent(
            strings: strings.welcome,
            recentURLs: recentURLs,
            newDocument: { createDocument(text: "") },
            openFile: { NSDocumentController.shared.openDocument(nil) },
            openGuide: { createDocument(text: strings.welcomeDoc) },
            openRecent: { url in Task { await openFile(at: url) } }
        )
        .disabled(openingURL != nil)
        .alert(strings.welcome.openError, isPresented: Binding(
            get: { openError != nil },
            set: { if !$0 { openError = nil } }
        )) {
            Button(strings.welcome.dismiss, role: .cancel) { openError = nil }
        } message: {
            Text(openError ?? "")
        }
        .onAppear(perform: refreshRecents)
        .onChange(of: activeState) { _, state in
            if state == .key { refreshRecents() }
        }
    }

    private func refreshRecents() {
        recentURLs = NSDocumentController.shared.recentDocumentURLs
    }

    private func createDocument(text: String) {
        newDocument(MarkDocument(text: text))
        dismissWindow(id: AppIdentity.welcomeWindowID)
    }

    private func openFile(at url: URL) async {
        guard openingURL == nil else { return }
        openingURL = url
        let scopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if scopedAccess { url.stopAccessingSecurityScopedResource() }
            openingURL = nil
        }
        do {
            try await openDocument(at: url)
            dismissWindow(id: AppIdentity.welcomeWindowID)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        let cocoaError = error as NSError
        guard !(cocoaError.domain == NSCocoaErrorDomain && cocoaError.code == NSUserCancelledError) else { return }
        openError = error.localizedDescription
    }
}

/// Separate content keeps the layout independent of file access and makes
/// empty/populated states available to previews and integration tests.
struct WelcomeContent: View {
    let strings: WelcomeStrings
    let recentURLs: [URL]
    let newDocument: () -> Void
    let openFile: () -> Void
    let openGuide: () -> Void
    let openRecent: (URL) -> Void
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 0) {
            introduction
                .frame(minWidth: 390, maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.colors.background)
            Rectangle()
                .fill(theme.colors.divider.opacity(0.5))
                .frame(width: 1)
            recentDocuments
                .frame(minWidth: 300, idealWidth: 340, maxWidth: 400, maxHeight: .infinity)
                .background(theme.colors.codeBackground.opacity(0.5))
        }
        .foregroundStyle(theme.colors.text)
        .frame(minWidth: 760, minHeight: 500)
        .background(theme.colors.background.ignoresSafeArea())
        .containerBackground(theme.colors.background, for: .window)
    }

    private var introduction: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 28)
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 120, height: 120)
                .accessibilityHidden(true)
            Text("MarkD")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .padding(.top, 12)
                .accessibilityAddTraits(.isHeader)
            Text(strings.tagline)
                .font(.system(size: 15))
                .foregroundStyle(theme.colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.top, 6)
            Text(AppIdentity.versionDescription)
                .font(.system(size: 12))
                .foregroundStyle(theme.colors.secondaryText)
                .padding(.top, 8)

            VStack(spacing: 10) {
                welcomeButton(strings.newDocument, icon: "square.and.pencil", shortcut: "⌘N", action: newDocument)
                welcomeButton(strings.openDocument, icon: "folder", shortcut: "⌘O", action: openFile)
                welcomeButton(strings.markdownGuide, icon: "book", action: openGuide)
            }
            .padding(.top, 30)
            .frame(maxWidth: 360)
            Spacer(minLength: 28)
        }
        .padding(.horizontal, 32)
    }

    private func welcomeButton(_ title: String, icon: String, shortcut: String? = nil,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(theme.colors.accent)
                    .frame(width: 26)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.welcomeActionText)
                Spacer(minLength: 6)
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.welcomeActionText)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(WelcomeActionStyle())
    }

    private var recentDocuments: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.recentDocuments)
                .font(.system(size: 17, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
                .padding(.horizontal, 24)
                .padding(.top, 36)
            if recentURLs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(theme.colors.secondaryText)
                        .accessibilityHidden(true)
                    Text(strings.noRecentDocuments)
                        .font(.system(size: 15, weight: .medium))
                    Text(strings.recentsHint)
                        .font(.system(size: 13))
                        .foregroundStyle(theme.colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(recentURLs, id: \.self) { url in
                            recentDocument(url)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private func recentDocument(_ url: URL) -> some View {
        Button { openRecent(url) } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(theme.colors.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(url.lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(url.deletingLastPathComponent().path(percentEncoded: false))
                        .font(.system(size: 11))
                        .foregroundStyle(theme.colors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(WelcomeActionStyle(isRecent: true))
        .help(url.path(percentEncoded: false))
        .accessibilityLabel(url.lastPathComponent)
        .accessibilityHint(url.deletingLastPathComponent().path(percentEncoded: false))
    }
}

private struct WelcomeActionStyle: ButtonStyle {
    var isRecent = false
    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: isRecent ? 10 : 12)
                    .fill(configuration.isPressed
                          ? theme.colors.accent.opacity(0.16)
                          : (isRecent ? Color.clear : theme.colors.codeBackground))
            }
    }
}

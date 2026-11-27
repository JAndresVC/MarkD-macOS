import AppKit
import Combine
import Sparkle
import SwiftUI

final class AppUpdater: ObservableObject {
    private let controller: SPUStandardUpdaterController?
    @Published private(set) var canCheckForUpdates = true

    init() {
        let bundle = Bundle.main
        guard let feed = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              let url = URL(string: feed),
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil,
              url.scheme == "https" || (url.scheme == "http" && host == "localhost"),
              let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              Data(base64Encoded: publicKey)?.count == 32 else {
            controller = nil
            return
        }

        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.controller = controller
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates(strings: L10n) {
        if let controller {
            controller.checkForUpdates(nil)
        } else {
            let alert = NSAlert()
            alert.messageText = strings.updatesUnavailable
            alert.informativeText = strings.updatesUnavailableDetail
            alert.runModal()
        }
    }
}

struct UpdateCommands: Commands {
    @ObservedObject var updater: AppUpdater
    @AppStorage("appLanguage") private var storedLanguage = AppLanguage.system.rawValue

    var body: some Commands {
        let strings = AppLanguage.from(stored: storedLanguage).strings
        CommandGroup(after: .appInfo) {
            Button(strings.checkForUpdates) { updater.checkForUpdates(strings: strings) }
                .disabled(!updater.canCheckForUpdates)
        }
    }
}

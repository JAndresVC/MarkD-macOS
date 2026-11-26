import Foundation

enum AppIdentity {
    static let welcomeWindowID = "welcome"

    static var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.2.0"
        let channel = Bundle.main.object(forInfoDictionaryKey: "MarkDReleaseChannel") as? String ?? "Beta 14"
        return "\(version) \(channel)"
    }
}

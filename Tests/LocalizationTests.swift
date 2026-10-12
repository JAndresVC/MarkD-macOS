import Foundation

@main
enum LocalizationTests {
    private static let formerNamePattern = try! NSRegularExpression(
        pattern: #"(?<![A-Za-z0-9_])"# + "Mar" + "k" + #"(?![A-Za-z0-9_])"#
    )

    static func main() {
        let localizations: [(language: String, strings: L10n)] = [
            ("English", .en),
            ("Español", .es),
            ("Català", .ca),
            ("日本語", .ja)
        ]
        var failures: [String] = []

        for localization in localizations {
            if localization.strings.loadingDocument.isEmpty {
                failures.append("\(localization.language) has no loading label")
            }
            let document = localization.strings.welcomeDoc
            if !document.contains("MarkD") {
                failures.append("\(localization.language) welcome document does not use MarkD")
            }

            let fullRange = NSRange(document.startIndex..<document.endIndex, in: document)
            if formerNamePattern.firstMatch(in: document, range: fullRange) != nil {
                failures.append("\(localization.language) welcome document still uses the former product name")
            }
        }

        if failures.isEmpty {
            print("LocalizationTests: 4 localizations passed")
        } else {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
    }
}

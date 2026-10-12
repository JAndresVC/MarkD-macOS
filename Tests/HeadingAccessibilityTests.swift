import Accessibility
import AppKit
import Foundation
import SwiftUI

@main
enum HeadingAccessibilityTests {
    static func main() throws {
        var failures: [String] = []

        for level in 1...6 {
            let marked = textMarkingMarkdownHeading(
                AttributedString("Heading \(level)"),
                level: level
            )
            let bridged = try NSAttributedString(marked, including: \.accessibility)
            let value = bridged.attribute(
                NSAttributedString.Key(NSAccessibility.Attribute.headingLevelAttribute.rawValue),
                at: 0,
                effectiveRange: nil
            ) as? NSNumber

            if value?.intValue != level {
                failures.append("H\(level) bridged as \(value?.intValue.description ?? "nil")")
            }
            if swiftUIHeadingLevel(for: level).rawValue != UInt(level) {
                failures.append("SwiftUI mapping for H\(level) is incorrect")
            }
        }

        let plain = textMarkingMarkdownHeading(AttributedString("Plain"), level: 99)
        let bridgedPlain = try NSAttributedString(plain, including: \.accessibility)
        let plainValue = bridgedPlain.attribute(
            NSAttributedString.Key(NSAccessibility.Attribute.headingLevelAttribute.rawValue),
            at: 0,
            effectiveRange: nil
        ) as? NSNumber
        if plainValue?.intValue != 0 {
            failures.append("an invalid Markdown level was not mapped to unspecified")
        }

        if failures.isEmpty {
            print("HeadingAccessibilityTests: passed")
        } else {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
    }
}

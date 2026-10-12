import Accessibility
import Foundation
import SwiftUI

func swiftUIHeadingLevel(for markdownLevel: Int) -> AccessibilityHeadingLevel {
    switch markdownLevel {
    case 1: return .h1
    case 2: return .h2
    case 3: return .h3
    case 4: return .h4
    case 5: return .h5
    case 6: return .h6
    default: return .unspecified
    }
}

func textMarkingMarkdownHeading(_ text: AttributedString, level: Int) -> AttributedString {
    var result = text
    result.accessibilityHeadingLevel = attributedHeadingLevel(for: level)
    return result
}

private func attributedHeadingLevel(for markdownLevel: Int) ->
    AttributeScopes.AccessibilityAttributes.HeadingLevelAttribute.HeadingLevel {
    switch markdownLevel {
    case 1: return .h1
    case 2: return .h2
    case 3: return .h3
    case 4: return .h4
    case 5: return .h5
    case 6: return .h6
    default: return .unspecified
    }
}

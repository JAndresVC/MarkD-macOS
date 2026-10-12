import AppKit

@main
@MainActor
enum WindowAppearanceTests {
    static func main() {
        var failures: [String] = []

        let trackingView = WindowAppearanceTrackingView(appearanceName: .darkAqua)
        let firstWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )

        // The requested appearance exists before the view has a window. It
        // must be applied when AppKit later attaches it.
        firstWindow.contentView = trackingView
        if firstWindow.appearance?.name != .darkAqua {
            failures.append("appearance requested before attachment was not applied")
        }
        trackingView.appearanceName = .aqua
        if firstWindow.appearance?.name != .aqua {
            failures.append("appearance change was not applied to the attached window")
        }

        // SwiftUI may move/recreate representables between backing windows.
        let secondWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        secondWindow.contentView = trackingView
        if secondWindow.appearance?.name != .aqua {
            failures.append("appearance was not reapplied after moving to another window")
        }

        trackingView.usesUnifiedDocumentToolbar = true
        if !secondWindow.titlebarAppearsTransparent {
            failures.append("document title bar was not made transparent")
        }
        if secondWindow.titlebarSeparatorStyle != .line {
            failures.append("document title bar separator was not made consistent")
        }

        trackingView.usesUnifiedDocumentToolbar = false
        if secondWindow.titlebarAppearsTransparent {
            failures.append("non-document title bar was left transparent")
        }
        if secondWindow.titlebarSeparatorStyle != .automatic {
            failures.append("non-document title bar did not restore automatic separation")
        }

        if failures.isEmpty {
            print("WindowAppearanceTests: passed")
        } else {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
    }

}

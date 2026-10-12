import Foundation
import UniformTypeIdentifiers

@main
enum DocumentIOTests {
    private static var failures: [String] = []
    private static var passed = 0

    static func main() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("markd-document-io-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        check("document types and new document") {
            expect(MarkDocument.readableContentTypes == [.markdownText, .plainText], "readable types changed")
            expect(MarkDocument.writableContentTypes == [.markdownText, .plainText], "writable types changed")
            expect(MarkDocument().fileWrapper().regularFileContents == Data(), "new document is not empty")
        }
        check("UTF-8 exact round trips") {
            let fixtures = ["", "# LF\nline\n", "# CRLF\r\nline\r\n", "# CR\rline\r", "LF\nCRLF\r\nCR\r",
                            "é e\u{0301} 👩🏽‍💻 日本語\n", "embedded\u{0000}NUL\n", "no trailing newline"]
            for (index, text) in fixtures.enumerated() {
                try roundTrip(Data(text.utf8), name: "valid-\(index)", directory: directory)
            }
        }
        check("UTF-8 BOM exact round trips") {
            for (index, text) in ["", "# BOM\r\né e\u{0301} 👩🏽‍💻 日本語\r\n"].enumerated() {
                try roundTrip(Data([0xef, 0xbb, 0xbf]) + Data(text.utf8), name: "bom-\(index)", directory: directory)
            }
        }
        check("edits preserve Unicode and line endings") {
            let original = "\u{feff}# First\r\né 👩🏽‍💻\r\n"
            var document = try MarkDocument(data: Data(original.utf8))
            document.text.append("e\u{0301} 日本語\r\n")
            expect(document.fileWrapper().regularFileContents == Data((original + "e\u{0301} 日本語\r\n").utf8),
                   "serialization normalized the source or dropped the BOM")
            document.text = "cafe\u{0301}\r"
            expect(document.fileWrapper().regularFileContents == Data("cafe\u{0301}\r".utf8),
                   "serialization changed an explicitly replaced document")
        }
        check("malformed UTF-8 rejected without changing originals") {
            let invalid: [[UInt8]] = [[0x80], [0xc3], [0xc3, 0x28], [0xc0, 0xaf], [0xed, 0xa0, 0x80],
                                     [0xf4, 0x90, 0x80, 0x80], [0xf0, 0x9f, 0x91], [0x23, 0x20, 0xff]]
            for (index, bytes) in invalid.enumerated() {
                try rejects(Data(bytes), name: "invalid-\(index)", directory: directory)
            }
        }
        check("non-UTF-8 fixtures rejected without changing originals") {
            // Encoding detection is deliberately absent: ASCII bytes are valid UTF-8 regardless of their origin.
            let fixtures: [[UInt8]] = [[0x63, 0x61, 0x66, 0xe9], [0x93, 0x74, 0x65, 0x78, 0x74, 0x94],
                                      [0xff, 0xfe, 0x23, 0x00], [0xfe, 0xff, 0x00, 0x23],
                                      [0xff, 0xfe, 0x00, 0x00, 0x23, 0x00, 0x00, 0x00]]
            for (index, bytes) in fixtures.enumerated() {
                try rejects(Data(bytes), name: "legacy-\(index)", directory: directory)
            }
        }

        if !failures.isEmpty {
            for failure in failures { fputs("FAIL: \(failure)\n", stderr) }
            exit(1)
        }
        print("DocumentIOTests: \(passed) passed")
    }

    private static func roundTrip(_ bytes: Data, name: String, directory: URL) throws {
        let source = directory.appendingPathComponent("\(name).md")
        let destination = directory.appendingPathComponent("\(name)-saved.md")
        try bytes.write(to: source)
        let document = try MarkDocument(data: Data(contentsOf: source))
        let wrapper = document.fileWrapper()
        expect(wrapper.isRegularFile, "\(name): writer did not produce a regular file")
        expect(wrapper.regularFileContents == bytes, "\(name): round trip changed UTF-8 bytes")
        try wrapper.write(to: destination, options: .atomic, originalContentsURL: nil)
        expect(try Data(contentsOf: destination) == bytes, "\(name): saved file changed UTF-8 bytes")
        expect(try Data(contentsOf: source) == bytes, "\(name): source file changed")
    }

    private static func rejects(_ bytes: Data, name: String, directory: URL) throws {
        let source = directory.appendingPathComponent("\(name).md")
        try bytes.write(to: source)
        do {
            _ = try MarkDocument(data: Data(contentsOf: source))
            expect(false, "\(name): malformed UTF-8 was accepted")
        } catch let error as CocoaError {
            expect(error.code == .fileReadCorruptFile, "\(name): unexpected error \(error.code)")
        }
        expect(try Data(contentsOf: source) == bytes, "\(name): rejected source file changed")
    }

    private static func check(_ name: String, _ body: () throws -> Void) {
        let before = failures.count
        do { try body() }
        catch { failures.append("\(name): \(error)") }
        if failures.count == before { passed += 1 }
    }

    private static func expect(_ result: Bool, _ message: String) {
        if !result { failures.append(message) }
    }
}

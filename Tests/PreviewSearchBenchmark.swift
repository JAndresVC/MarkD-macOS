import Foundation

/// Isolates matching from parsing/rendering. Timings are observations, not a
/// pass/fail threshold: run an optimized build on an otherwise idle machine.
@main
enum PreviewSearchBenchmark {
    static func main() {
        for count in [1000, 2000, 4000, 8000] {
            let text = String(repeating: "word café 日本語 🚀 ", count: count)
            let blocks = [MarkdownBlock(lineNumber: 0, content: .code(text, language: ""))]
            var samples: [Double] = []
            for _ in 0..<5 {
                let start = ContinuousClock.now
                let matches = previewSearchMatches(in: blocks, query: "word")
                let elapsed = start.duration(to: .now).components
                precondition(matches.count == count)
                precondition(matches.last?.characterRange == ((count - 1) * 16)..<((count - 1) * 16 + 4))
                samples.append(Double(elapsed.seconds) * 1000 + Double(elapsed.attoseconds) / 1e15)
            }
            print("\(count) matches, \(text.count) characters: median \(String(format: "%.3f", samples.sorted()[2])) ms (5 samples)")
        }
    }
}

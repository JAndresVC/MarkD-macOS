import SwiftUI

// Lightweight regex-based highlighter for fenced code blocks.
// Not a full lexer — covers comments, strings, numbers, and keywords,
// which is enough for readable previews.
enum SyntaxHighlighter {

    static func highlight(_ code: String, language: String, colors: ThemeColors) -> AttributedString {
        let lang = language.lowercased()
        let keywords = keywordSet(for: lang)
        guard let regex = try? NSRegularExpression(
            pattern: pattern(for: lang),
            options: [.dotMatchesLineSeparators]
        ) else { return AttributedString(code) }

        var result = AttributedString()
        let nsCode = code as NSString
        var lastEnd = 0

        regex.enumerateMatches(in: code, range: NSRange(location: 0, length: nsCode.length)) { match, _, _ in
            guard let match else { return }
            let range = match.range
            if range.location > lastEnd {
                result += AttributedString(nsCode.substring(with:
                    NSRange(location: lastEnd, length: range.location - lastEnd)))
            }
            let token = nsCode.substring(with: range)
            var styled = AttributedString(token)

            if match.range(at: 1).location != NSNotFound {
                styled.foregroundColor = colors.syntaxComment
            } else if match.range(at: 2).location != NSNotFound {
                styled.foregroundColor = colors.syntaxString
            } else if match.range(at: 3).location != NSNotFound {
                styled.foregroundColor = colors.syntaxNumber
            } else if keywords.contains(token) {
                styled.foregroundColor = colors.syntaxKeyword
            }
            result += styled
            lastEnd = range.location + range.length
        }

        if lastEnd < nsCode.length {
            result += AttributedString(nsCode.substring(from: lastEnd))
        }
        return result
    }

    // Capture groups: 1 = comment, 2 = string, 3 = number, 4 = identifier.
    private static func pattern(for lang: String) -> String {
        let comment: String
        switch lang {
        case "python", "py", "ruby", "rb", "sh", "bash", "zsh", "shell", "yaml", "yml", "toml", "r":
            comment = "#[^\\n]*"
        case "html", "xml":
            comment = #"<!--.*?-->"#
        default:
            comment = #"//[^\n]*|/\*.*?\*/"#
        }
        let string = #""(?:[^"\\\n]|\\.)*"|'(?:[^'\\\n]|\\.)*'|`(?:[^`\\\n]|\\.)*`"#
        let number = #"\b\d+(?:\.\d+)?\b"#
        let word = #"\b[A-Za-z_][A-Za-z0-9_]*\b"#
        return "(\(comment))|(\(string))|(\(number))|(\(word))"
    }

    private static func keywordSet(for lang: String) -> Set<String> {
        switch lang {
        case "swift":
            return ["func", "var", "let", "if", "else", "guard", "return", "class", "struct",
                    "enum", "protocol", "extension", "import", "for", "while", "in", "switch",
                    "case", "default", "break", "continue", "init", "deinit", "self", "super",
                    "nil", "true", "false", "throws", "throw", "try", "catch", "async", "await",
                    "private", "public", "internal", "static", "final", "some", "any", "where"]
        case "python", "py":
            return ["def", "class", "if", "elif", "else", "for", "while", "return", "import",
                    "from", "as", "with", "try", "except", "finally", "raise", "pass", "break",
                    "continue", "lambda", "yield", "global", "nonlocal", "in", "is", "not",
                    "and", "or", "None", "True", "False", "self", "async", "await"]
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            return ["function", "var", "let", "const", "if", "else", "for", "while", "return",
                    "class", "extends", "import", "export", "from", "default", "switch", "case",
                    "break", "continue", "new", "this", "null", "undefined", "true", "false",
                    "async", "await", "try", "catch", "finally", "throw", "typeof", "instanceof",
                    "interface", "type", "enum", "implements", "public", "private", "static"]
        case "c", "cpp", "c++", "h", "hpp", "objc", "objective-c":
            return ["int", "char", "float", "double", "void", "long", "short", "unsigned",
                    "signed", "struct", "union", "enum", "typedef", "const", "static", "extern",
                    "if", "else", "for", "while", "do", "switch", "case", "default", "break",
                    "continue", "return", "goto", "sizeof", "class", "public", "private",
                    "protected", "virtual", "template", "namespace", "using", "new", "delete",
                    "nullptr", "true", "false", "auto"]
        case "go":
            return ["func", "var", "const", "type", "struct", "interface", "map", "chan", "if",
                    "else", "for", "range", "switch", "case", "default", "break", "continue",
                    "return", "go", "defer", "select", "package", "import", "nil", "true",
                    "false", "make", "new", "len", "cap"]
        case "rust", "rs":
            return ["fn", "let", "mut", "const", "if", "else", "for", "while", "loop", "match",
                    "return", "struct", "enum", "trait", "impl", "mod", "use", "pub", "crate",
                    "self", "Self", "super", "where", "async", "await", "move", "ref", "true",
                    "false", "Some", "None", "Ok", "Err"]
        case "ruby", "rb":
            return ["def", "end", "class", "module", "if", "elsif", "else", "unless", "case",
                    "when", "while", "until", "for", "in", "do", "return", "yield", "begin",
                    "rescue", "ensure", "raise", "require", "attr_accessor", "nil", "true",
                    "false", "self", "puts", "new"]
        case "sh", "bash", "zsh", "shell":
            return ["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case",
                    "esac", "function", "return", "exit", "echo", "export", "local", "readonly"]
        case "java", "kotlin", "kt":
            return ["public", "private", "protected", "class", "interface", "extends",
                    "implements", "static", "final", "void", "int", "long", "double", "float",
                    "boolean", "char", "new", "return", "if", "else", "for", "while", "switch",
                    "case", "default", "break", "continue", "try", "catch", "finally", "throw",
                    "throws", "import", "package", "this", "super", "null", "true", "false",
                    "fun", "val", "var", "when", "object", "companion", "data", "suspend"]
        default:
            return []
        }
    }
}

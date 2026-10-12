import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case spanish = "es"
    case catalan = "ca"
    case japanese = "ja"

    var id: String { rawValue }

    // Endonyms, so every language is recognizable no matter the current setting.
    var displayName: String {
        switch self {
        case .system:   return AppLanguage.resolvedSystem.strings.systemLanguage
        case .english:  return "English"
        case .spanish:  return "Español"
        case .catalan:  return "Català"
        case .japanese: return "日本語"
        }
    }

    var strings: L10n {
        switch self {
        case .system:   return AppLanguage.resolvedSystem.strings
        case .english:  return .en
        case .spanish:  return .es
        case .catalan:  return .ca
        case .japanese: return .ja
        }
    }

    static func from(stored: String) -> AppLanguage {
        AppLanguage(rawValue: stored) ?? .system
    }

    private static var resolvedSystem: AppLanguage {
        for lang in Locale.preferredLanguages {
            if lang.hasPrefix("es") { return .spanish }
            if lang.hasPrefix("ca") { return .catalan }
            if lang.hasPrefix("ja") { return .japanese }
            if lang.hasPrefix("en") { return .english }
        }
        return .english
    }
}

// MARK: - Localized Strings

struct WelcomeStrings {
    let windowTitle: String
    let tagline: String
    let newDocument: String
    let openDocument: String
    let markdownGuide: String
    let recentDocuments: String
    let noRecentDocuments: String
    let recentsHint: String
    let openError: String
    let dismiss: String
}

struct L10n {
    // View modes
    let edit: String
    let preview: String
    let raw: String
    let mode: String

    // Sidebar
    let outline: String
    let noHeadings: String
    let noHeadingsHint: String
    let loadingDocument: String

    // Menus
    let theme: String
    let fontSize: String
    let increase: String
    let decrease: String
    let resetToDefault: String
    let find: String
    let findEllipsis: String
    let findInPreview: String
    let findNext: String
    let findPrevious: String
    let noMatches: String
    let closeSearch: String

    // Settings
    let general: String
    let appearance: String
    let editor: String
    let language: String
    let systemLanguage: String
    let fontSizeLabel: String
    let themeLabel: String
    let languageLabel: String

    // Theme names
    let themeLight: String
    let themeDark: String
    let themeSepia: String
    let themeSolarizedLight: String
    let themeSolarizedDark: String
    let themeDracula: String

    let welcome: WelcomeStrings

    // Optional sample document, opened from the welcome window.
    let welcomeDoc: String

    func themeName(_ theme: AppTheme) -> String {
        switch theme {
        case .light:          return themeLight
        case .dark:           return themeDark
        case .sepia:          return themeSepia
        case .solarizedLight: return themeSolarizedLight
        case .solarizedDark:  return themeSolarizedDark
        case .dracula:        return themeDracula
        }
    }

    static let en = L10n(
        edit: "Edit",
        preview: "Preview",
        raw: "RAW",
        mode: "View mode",
        outline: "Outline",
        noHeadings: "No Headings",
        noHeadingsHint: "Add headings with # to see the outline.",
        loadingDocument: "Preparing document…",
        theme: "Theme",
        fontSize: "Font Size",
        increase: "Increase",
        decrease: "Decrease",
        resetToDefault: "Reset to Default",
        find: "Find",
        findEllipsis: "Find…",
        findInPreview: "Find in Preview",
        findNext: "Find Next",
        findPrevious: "Find Previous",
        noMatches: "No Matches",
        closeSearch: "Close Search",
        general: "General",
        appearance: "Appearance",
        editor: "Editor",
        language: "Language",
        systemLanguage: "System",
        fontSizeLabel: "Font size:",
        themeLabel: "Theme:",
        languageLabel: "Language:",
        themeLight: "Light",
        themeDark: "Dark",
        themeSepia: "Sepia",
        themeSolarizedLight: "Solarized Light",
        themeSolarizedDark: "Solarized Dark",
        themeDracula: "Dracula",
        welcome: WelcomeStrings(
            windowTitle: "Welcome to MarkD",
            tagline: "A space for your words.",
            newDocument: "Create a new document",
            openDocument: "Open a document…",
            markdownGuide: "Explore Markdown",
            recentDocuments: "Recent documents",
            noRecentDocuments: "Your next idea starts here",
            recentsHint: "The documents you open will appear here.",
            openError: "Couldn’t open the document",
            dismiss: "OK"
        ),
        welcomeDoc: """
        # Welcome to MarkD

        Start writing your Markdown here.

        ## Features

        - **Edit mode** — raw Markdown input
        - **Preview mode** — rendered output
        - Clean, minimal design

        ## Code Example

        ```swift
        let greeting = "Hello, MarkD!"
        print(greeting)
        ```

        > Use the toolbar above to switch between modes.
        """
    )

    static let es = L10n(
        edit: "Editar",
        preview: "Vista previa",
        raw: "RAW",
        mode: "Modo de vista",
        outline: "Esquema",
        noHeadings: "Sin encabezados",
        noHeadingsHint: "Añade encabezados con # para ver el esquema.",
        loadingDocument: "Preparando documento…",
        theme: "Tema",
        fontSize: "Tamaño de letra",
        increase: "Aumentar",
        decrease: "Reducir",
        resetToDefault: "Restablecer",
        find: "Buscar",
        findEllipsis: "Buscar…",
        findInPreview: "Buscar en Vista previa",
        findNext: "Buscar siguiente",
        findPrevious: "Buscar anterior",
        noMatches: "Sin coincidencias",
        closeSearch: "Cerrar búsqueda",
        general: "General",
        appearance: "Apariencia",
        editor: "Editor",
        language: "Idioma",
        systemLanguage: "Sistema",
        fontSizeLabel: "Tamaño de letra:",
        themeLabel: "Tema:",
        languageLabel: "Idioma:",
        themeLight: "Claro",
        themeDark: "Oscuro",
        themeSepia: "Sepia",
        themeSolarizedLight: "Solarized claro",
        themeSolarizedDark: "Solarized oscuro",
        themeDracula: "Drácula",
        welcome: WelcomeStrings(
            windowTitle: "Bienvenido a MarkD",
            tagline: "Un espacio para tus palabras.",
            newDocument: "Crear un documento nuevo",
            openDocument: "Abrir un documento…",
            markdownGuide: "Explorar Markdown",
            recentDocuments: "Documentos recientes",
            noRecentDocuments: "Tu próxima idea empieza aquí",
            recentsHint: "Aquí aparecerán los documentos que abras.",
            openError: "No se pudo abrir el documento",
            dismiss: "Aceptar"
        ),
        welcomeDoc: """
        # Bienvenido a MarkD

        Empieza a escribir tu Markdown aquí.

        ## Funciones

        - **Modo Editar** — entrada Markdown sin procesar
        - **Modo Vista previa** — resultado renderizado
        - Diseño limpio y minimalista

        ## Ejemplo de código

        ```swift
        let saludo = "¡Hola, MarkD!"
        print(saludo)
        ```

        > Usa la barra superior para cambiar de modo.
        """
    )

    static let ca = L10n(
        edit: "Edita",
        preview: "Previsualització",
        raw: "RAW",
        mode: "Mode de visualització",
        outline: "Esquema",
        noHeadings: "Sense encapçalaments",
        noHeadingsHint: "Afegeix encapçalaments amb # per veure l'esquema.",
        loadingDocument: "Preparant el document…",
        theme: "Tema",
        fontSize: "Mida de la lletra",
        increase: "Augmenta",
        decrease: "Redueix",
        resetToDefault: "Restableix",
        find: "Cerca",
        findEllipsis: "Cerca…",
        findInPreview: "Cerca a la previsualització",
        findNext: "Cerca la següent",
        findPrevious: "Cerca l'anterior",
        noMatches: "Sense coincidències",
        closeSearch: "Tanca la cerca",
        general: "General",
        appearance: "Aparença",
        editor: "Editor",
        language: "Idioma",
        systemLanguage: "Sistema",
        fontSizeLabel: "Mida de la lletra:",
        themeLabel: "Tema:",
        languageLabel: "Idioma:",
        themeLight: "Clar",
        themeDark: "Fosc",
        themeSepia: "Sèpia",
        themeSolarizedLight: "Solarized clar",
        themeSolarizedDark: "Solarized fosc",
        themeDracula: "Dracula",
        welcome: WelcomeStrings(
            windowTitle: "Benvingut a MarkD",
            tagline: "Un espai per a les teves paraules.",
            newDocument: "Crea un document nou",
            openDocument: "Obre un document…",
            markdownGuide: "Explora Markdown",
            recentDocuments: "Documents recents",
            noRecentDocuments: "La teva pròxima idea comença aquí",
            recentsHint: "Aquí apareixeran els documents que obris.",
            openError: "No s’ha pogut obrir el document",
            dismiss: "D’acord"
        ),
        welcomeDoc: """
        # Benvingut a MarkD

        Comença a escriure el teu Markdown aquí.

        ## Funcions

        - **Mode Edita** — entrada Markdown sense processar
        - **Mode Previsualització** — resultat renderitzat
        - Disseny net i minimalista

        ## Exemple de codi

        ```swift
        let salutacio = "Hola, MarkD!"
        print(salutacio)
        ```

        > Fes servir la barra superior per canviar de mode.
        """
    )

    static let ja = L10n(
        edit: "編集",
        preview: "プレビュー",
        raw: "RAW",
        mode: "表示モード",
        outline: "アウトライン",
        noHeadings: "見出しがありません",
        noHeadingsHint: "# で見出しを追加するとアウトラインが表示されます。",
        loadingDocument: "書類を準備中…",
        theme: "テーマ",
        fontSize: "文字サイズ",
        increase: "拡大",
        decrease: "縮小",
        resetToDefault: "デフォルトに戻す",
        find: "検索",
        findEllipsis: "検索…",
        findInPreview: "プレビュー内を検索",
        findNext: "次を検索",
        findPrevious: "前を検索",
        noMatches: "一致なし",
        closeSearch: "検索を閉じる",
        general: "一般",
        appearance: "外観",
        editor: "エディタ",
        language: "言語",
        systemLanguage: "システム",
        fontSizeLabel: "文字サイズ:",
        themeLabel: "テーマ:",
        languageLabel: "言語:",
        themeLight: "ライト",
        themeDark: "ダーク",
        themeSepia: "セピア",
        themeSolarizedLight: "Solarized ライト",
        themeSolarizedDark: "Solarized ダーク",
        themeDracula: "ドラキュラ",
        welcome: WelcomeStrings(
            windowTitle: "MarkD へようこそ",
            tagline: "あなたの言葉のための場所。",
            newDocument: "新しい書類を作成",
            openDocument: "書類を開く…",
            markdownGuide: "Markdown を試す",
            recentDocuments: "最近使った書類",
            noRecentDocuments: "次のアイデアはここから",
            recentsHint: "開いた書類がここに表示されます。",
            openError: "書類を開けませんでした",
            dismiss: "OK"
        ),
        welcomeDoc: """
        # MarkD へようこそ

        ここに Markdown を書き始めましょう。

        ## 機能

        - **編集モード** — Markdown をそのまま入力
        - **プレビューモード** — レンダリング結果を表示
        - すっきりしたミニマルデザイン

        ## コード例

        ```swift
        let greeting = "こんにちは、MarkD!"
        print(greeting)
        ```

        > 上のツールバーでモードを切り替えられます。
        """
    )
}

// MARK: - Environment

private struct L10nKey: EnvironmentKey {
    static let defaultValue: L10n = .en
}

extension EnvironmentValues {
    var l10n: L10n {
        get { self[L10nKey.self] }
        set { self[L10nKey.self] = newValue }
    }
}

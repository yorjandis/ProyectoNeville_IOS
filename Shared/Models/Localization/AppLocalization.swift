//
//  AppLocalization.swift
//  Neville_iOS
//
//  Punto único para resolver el idioma de interfaz y los recursos localizados.
//

import Foundation

nonisolated enum AppLanguage: String, CaseIterable, Codable, Sendable {
    case spanish = "es"
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    static let fallback: AppLanguage = .spanish
    static let overrideDefaultsKey = "app.language.override"

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var fallbackChain: [AppLanguage] {
        self == .spanish ? [.spanish] : [self, .spanish]
    }

    var aiResponseInstruction: String {
        switch self {
        case .spanish:
            "Responde en español natural y claro."
        case .english:
            "Respond in clear, natural English."
        case .simplifiedChinese:
            "请使用自然、清晰的简体中文回答，并保持原意和语气。"
        }
    }

    static var current: AppLanguage {
        if let stored = UserDefaults.standard.string(forKey: overrideDefaultsKey),
           let language = AppLanguage(rawValue: stored) {
            return language
        }

        let preferred = Bundle.main.preferredLocalizations.first
            ?? Locale.preferredLanguages.first
            ?? fallback.rawValue
        return resolve(preferred)
    }

    static func resolve(_ identifier: String) -> AppLanguage {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        if normalized.hasPrefix("zh") {
            return .simplifiedChinese
        }
        if normalized.hasPrefix("en") {
            return .english
        }
        return .spanish
    }

    /// Permite incorporar un selector interno más adelante sin cambiar el resto de la app.
    /// `nil` devuelve el control del idioma a los ajustes del sistema.
    static func setOverride(_ language: AppLanguage?) {
        if let language {
            UserDefaults.standard.set(language.rawValue, forKey: overrideDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: overrideDefaultsKey)
        }
    }

    func localizedBundle(in bundle: Bundle = .main) -> Bundle? {
        guard let path = bundle.path(forResource: rawValue, ofType: "lproj") else {
            return nil
        }
        return Bundle(path: path)
    }

    func exactLocalizedTextResource(
        named resourceName: String,
        bundle: Bundle = .main
    ) -> String? {
        guard let localizedBundle = localizedBundle(in: bundle),
              let url = localizedBundle.url(forResource: resourceName, withExtension: "txt"),
              let value = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
}

nonisolated enum L10n {
    /// Lee un recurso editorial localizado y conserva el fichero español original
    /// como último recurso. Solo debe usarse con contenidos cuya traducción esté
    /// expresamente autorizada.
    static func textResource(
        named resourceName: String,
        language: AppLanguage = .current,
        bundle: Bundle = .main
    ) -> String {
        for candidate in language.fallbackChain {
            if let value = candidate.exactLocalizedTextResource(
                named: resourceName,
                bundle: bundle
            ) {
                return value
            }
        }
        guard let url = bundle.url(forResource: resourceName.lowercased(), withExtension: "txt"),
              let value = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return value
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }

    static func string(
        _ key: String,
        fallback: String,
        table: String = "Localizable",
        language: AppLanguage = .current,
        bundle: Bundle = .main
    ) -> String {
        for candidate in language.fallbackChain {
            guard let localizedBundle = candidate.localizedBundle(in: bundle) else { continue }
            let value = localizedBundle.localizedString(forKey: key, value: nil, table: table)
            if value != key {
                return value
            }
        }
        return fallback
    }

    /// Resuelve un literal español usado directamente como clave del catálogo.
    /// Es útil cuando el texto debe viajar como `String` antes de llegar a SwiftUI.
    static func exact(
        _ spanish: String,
        language: AppLanguage = .current,
        bundle: Bundle = .main
    ) -> String {
        string(spanish, fallback: spanish, language: language, bundle: bundle)
    }

    /// Formatea textos dinámicos sin acoplar la traducción al orden de las palabras.
    /// Las traducciones usan marcadores estables `{0}`, `{1}`, etc.
    static func format(
        _ key: String,
        fallback: String,
        _ arguments: String...,
        language: AppLanguage = .current,
        bundle: Bundle = .main
    ) -> String {
        var result = string(key, fallback: fallback, language: language, bundle: bundle)
        for (index, argument) in arguments.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: argument)
        }
        return result
    }
}

nonisolated enum StableLocalizationID {
    static func context(canonicalName: String) -> String {
        let canonical = canonicalName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping
            .lowercased(with: Locale(identifier: "es"))
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        let encoded = canonical.addingPercentEncoding(withAllowedCharacters: allowed) ?? canonical
        return "context:\(encoded)"
    }
}

nonisolated func authorBiographyTitle(_ author: String) -> String {
    L10n.format("author.biography_title", fallback: "Biografía de {0}", author)
}

nonisolated func authorTeachingSummaryTitle(_ author: String) -> String {
    L10n.format(
        "author.teaching_summary_title",
        fallback: "Resumen de la enseñanza: {0}",
        author
    )
}

nonisolated func authorBookSummaryTitle(_ book: String) -> String {
    L10n.format("author.book_summary_title", fallback: "Resumen del libro: {0}", book)
}

nonisolated func authorBookPlanTitle(_ book: String) -> String {
    L10n.format("author.book_plan_title", fallback: "Plan del libro: {0}", book)
}

nonisolated func authorChapterTitle(_ number: Int) -> String {
    L10n.format("author.chapter_title", fallback: "Capítulo {0}", String(number))
}

nonisolated func authorSeriesChapterTitle(_ series: String, number: Int) -> String {
    L10n.format(
        "author.series_chapter_title",
        fallback: "{0}: Capítulo {1}",
        series,
        String(number)
    )
}

nonisolated func authorSeriesTitle(_ series: String) -> String {
    L10n.format("author.series_title", fallback: "Serie {0}", series)
}

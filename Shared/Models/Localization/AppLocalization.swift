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

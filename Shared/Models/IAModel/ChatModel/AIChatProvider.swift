//
//  AIChatProvider.swift
//  Neville_iOS
//
//  Tipos neutrales compartidos por los proveedores del chat.
//

import Foundation

enum AIChatProviderKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case apple
    case openRouter = "openrouter"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:
            return "Apple Intelligence"
        case .openRouter:
            return "OpenRouter"
        }
    }

    var shortDisplayName: String {
        switch self {
        case .apple:
            return "Apple"
        case .openRouter:
            return "OpenRouter"
        }
    }

    var systemImage: String {
        switch self {
        case .apple:
            return "apple.intelligence"
        case .openRouter:
            return "sparkles"
        }
    }

    var isOnline: Bool { self == .openRouter }
}

struct AIChatContextMessage: Equatable, Sendable {
    let role: ChatMessageRole
    let text: String
}

struct OpenRouterChatRequest: Sendable {
    let instructions: String
    let summary: String?
    let messages: [AIChatContextMessage]
    let prompt: String
    let modelIdentifier: String
}

struct OpenRouterModel: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let contextLength: Int?
    let description: String?

    var isAutomaticFreeSelection: Bool {
        id == OpenRouterConfiguration.automaticFreeModelIdentifier
    }

    var displayName: String {
        isAutomaticFreeSelection
            ? "Selección automática gratuita"
            : name
    }
}

struct OpenRouterModelCatalog: Sendable {
    let models: [OpenRouterModel]
    let dailyFreeRequestLimit: Int
}

enum OpenRouterConfiguration {
    static let automaticFreeModelIdentifier = "openrouter/free"
    static let defaultModelIdentifier = automaticFreeModelIdentifier
    static let standardDailyFreeRequestLimit = 50
    static let creditedDailyFreeRequestLimit = 1_000
    static let fallbackModels = [
        OpenRouterModel(
            id: automaticFreeModelIdentifier,
            name: "Selección automática gratuita",
            contextLength: nil,
            description: String(
                localized: "OpenRouter selecciona automáticamente un modelo gratuito disponible y puede evitar modelos temporalmente saturados."
            )
        )
    ]
    static let selectedModelDefaultsKey = "ai.openrouter.selected-free-model"
    static let dailyFreeRequestLimitDefaultsKey =
        "ai.openrouter.daily-free-request-limit"
    static let consentVersionDefaultsKey = "ai.openrouter.privacy-consent-version"
    static let currentConsentVersion = 1

    static func isFreeModelIdentifier(_ identifier: String) -> Bool {
        identifier == automaticFreeModelIdentifier || identifier.hasSuffix(":free")
    }

    static var selectedModelIdentifier: String {
        get {
            guard let stored = UserDefaults.standard.string(
                forKey: selectedModelDefaultsKey
            ), isFreeModelIdentifier(stored) else {
                return defaultModelIdentifier
            }
            return stored
        }
        set {
            guard isFreeModelIdentifier(newValue) else { return }
            UserDefaults.standard.set(newValue, forKey: selectedModelDefaultsKey)
        }
    }

    static var hasSelectedModelIdentifier: Bool {
        guard let stored = UserDefaults.standard.string(
            forKey: selectedModelDefaultsKey
        ) else {
            return false
        }
        return isFreeModelIdentifier(stored)
    }

    static var dailyFreeRequestLimit: Int {
        let stored = UserDefaults.standard.integer(
            forKey: dailyFreeRequestLimitDefaultsKey
        )
        return stored > 0 ? stored : standardDailyFreeRequestLimit
    }

    static func updateDailyFreeRequestLimit(_ limit: Int) {
        guard limit > 0 else { return }
        UserDefaults.standard.set(
            limit,
            forKey: dailyFreeRequestLimitDefaultsKey
        )
    }

    static func resetDailyFreeRequestLimit() {
        UserDefaults.standard.removeObject(
            forKey: dailyFreeRequestLimitDefaultsKey
        )
    }

    static var hasPrivacyConsent: Bool {
        UserDefaults.standard.integer(forKey: consentVersionDefaultsKey)
            >= currentConsentVersion
    }

    static func acceptPrivacyConsent() {
        UserDefaults.standard.set(
            currentConsentVersion,
            forKey: consentVersionDefaultsKey
        )
    }

    static func revokePrivacyConsent() {
        UserDefaults.standard.removeObject(forKey: consentVersionDefaultsKey)
    }

    static func removeLegacyGeminiPreferences() {
        UserDefaults.standard.removeObject(
            forKey: "ai.gemini.selected-model"
        )
        UserDefaults.standard.removeObject(
            forKey: "ai.gemini.privacy-consent-version"
        )
    }
}

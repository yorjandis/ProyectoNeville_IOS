//
//  OpenRouterCredentialStore.swift
//  Neville_iOS
//
//  Almacena exclusivamente la clave personal de OpenRouter del usuario.
//

import Foundation
import Security

struct OpenRouterCredentialStore: Sendable {
    static let shared = OpenRouterCredentialStore()

    private let service = "com.yorgandis.Neville.ai-credentials"
    private let account = "openrouter.api-key"
    private let legacyGeminiAccount = "gemini.api-key"

    func saveAPIKey(_ apiKey: String) throws {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty, let data = cleanKey.data(using: .utf8) else {
            throw OpenRouterCredentialError.emptyKey
        }

        var query = baseQuery
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecItemNotFound {
            query.merge(attributes) { _, new in new }
            query[kSecAttrSynchronizable as String] = kCFBooleanFalse
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw OpenRouterCredentialError.keychain(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            throw OpenRouterCredentialError.keychain(updateStatus)
        }
    }

    func readAPIKey() throws -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw OpenRouterCredentialError.keychain(status)
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OpenRouterCredentialError.keychain(status)
        }
    }

    func deleteLegacyGeminiAPIKey() throws {
        let status = SecItemDelete(
            query(account: legacyGeminiAccount) as CFDictionary
        )
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OpenRouterCredentialError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        query(account: account)
    }

    private func query(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kCFBooleanFalse as Any
        ]
    }
}

enum OpenRouterCredentialError: LocalizedError {
    case emptyKey
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "Introduce una clave de API de OpenRouter."
        case .keychain:
            return "No se pudo acceder de forma segura a la clave de OpenRouter."
        }
    }
}

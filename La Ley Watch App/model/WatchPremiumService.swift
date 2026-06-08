//
//  WatchPremiumService.swift
//  La Ley Watch App
//
//  Created by Codex on 8/6/26.
//

import AppIntents
import Foundation
import Security
import StoreKit

actor PremiumService {
    static let shared = PremiumService()

    private let premiumProductID = "com.ypg.nev.premium.anual"

    func hasPremiumAccess() async -> Bool {
        guard let result = await Transaction.latest(for: premiumProductID) else {
            return false
        }

        guard case .verified(let transaction) = result else {
            return false
        }

        return transaction.revocationDate == nil
    }
}

enum PremiumError: Error, CustomLocalizedStringResourceConvertible {
    case noSubscription

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noSubscription:
            return "Esta función solo esta presente en la versión extendida"
        }
    }
}

@MainActor
final class KeychainHelper {
    static let shared = KeychainHelper()

    private let account = "com.yorgandis.Neville"
    private let service = "com.yorgandis.Neville"

    private init() {}

    func getPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(decoding: data, as: UTF8.self)
    }
}

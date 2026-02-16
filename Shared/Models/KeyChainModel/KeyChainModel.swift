//
//  KeyChainModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

//Clase Helper para almacenar una contraseña para abrir el Diario o Desbloquear las Notas.

import Foundation
import Security

@MainActor
final class KeychainHelper {
   
    
    private let account = "com.yorgandis.Neville"
    private let service = "com.yorgandis.Neville"
    private let synchronizable = true
    
    static let shared = KeychainHelper()
    
    private init() {}
    
    // Guardar contraseña
    func savePassword(_ password: String) {
        guard let data = password.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        msg("Save status:", status)
    }

    func getPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue! : kCFBooleanFalse!,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        print("Read status:", status)

        guard status == errSecSuccess,
              let data = result as? Data else { return nil }

        return String(decoding: data, as: UTF8.self)
    }

    // Eliminar contraseña
    func deletePassword(account: String = "com.yorgandis.Neville", service: String = "com.yorgandis.Neville") {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]

        // También eliminar sincronizados
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny

        SecItemDelete(query as CFDictionary)
    }
}

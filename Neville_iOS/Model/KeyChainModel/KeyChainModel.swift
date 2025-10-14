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
    static let shared = KeychainHelper()
    private init() {}
    
    // Guardar contraseña
    func savePassword(_ password: String, account: String = "com.yorgandis.Neville", service: String = "com.yorgandis.Neville", syncWithiCloud: Bool = true) {
        guard let passwordData = password.data(using: .utf8) else { return }

        // Primero eliminamos cualquier valor previo
        deletePassword(account: account, service: service)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: passwordData
        ]

        // 🔹 Esto habilita la sincronización con iCloud Keychain
        if syncWithiCloud {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error al guardar en Keychain: \(status)")
        }
    }

    // Recuperar contraseña
    func getPassword(account: String = "com.yorgandis.Neville", service: String = "com.yorgandis.Neville") -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Intentar también buscar en iCloud Keychain
        query[kSecAttrSynchronizable as String] = kSecAttrSynchronizableAny

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            print("No se encontró la contraseña o error: \(status)")
            return nil
        }
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

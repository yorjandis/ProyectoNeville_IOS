import Foundation
import CryptoKit
import Security
#if canImport(CommonCrypto)
import CommonCrypto
#endif

final class MigrationCrypto {
    struct Parameters {
        let salt: Data
        let nonce: Data
    }

    func newParameters() throws -> Parameters {
        Parameters(
            salt: try randomData(count: MigrationFormat.saltBytes),
            nonce: try randomData(count: MigrationFormat.nonceBytes)
        )
    }

    func encryptionJson(parameters: Parameters) -> [String: Any] {
        [
            "cipher": MigrationFormat.cipher,
            "kdf": MigrationFormat.kdf,
            "kdfIterations": MigrationFormat.kdfIterations,
            "salt": MigrationFormat.encodeBase64(parameters.salt),
            "nonce": MigrationFormat.encodeBase64(parameters.nonce),
            "keyLengthBits": MigrationFormat.keyBits,
            "tagLengthBits": MigrationFormat.tagBits,
            "argon2idAvailable": false
        ]
    }

    func encrypt(plaintext: Data, password: String, parameters: Parameters) throws -> Data {
        let headerBytes = try headerJson(parameters: parameters)
        let key = try deriveKey(password: password, salt: parameters.salt)
        let nonce = try AES.GCM.Nonce(data: parameters.nonce)
        let sealed = try AES.GCM.seal(plaintext, using: key, nonce: nonce, authenticating: headerBytes)

        var output = Data()
        output.append(Data(MigrationFormat.magic.utf8))
        output.append(0x0a)
        output.append(headerBytes)
        output.append(0x0a)
        output.append(sealed.ciphertext)
        output.append(sealed.tag)
        return output
    }

    func decrypt(fileBytes: Data, password: String) throws -> MigrationFormat.PlainPackage {
        guard let firstBreak = fileBytes.firstIndex(of: 0x0a), firstBreak > fileBytes.startIndex else {
            throw MigrationError.validation("Cabecera de archivo inválida")
        }
        let magicBytes = fileBytes[fileBytes.startIndex..<firstBreak]
        guard String(data: Data(magicBytes), encoding: .utf8) == MigrationFormat.magic else {
            throw MigrationError.validation("Formato de archivo no reconocido")
        }

        let headerStart = fileBytes.index(after: firstBreak)
        guard let secondBreak = fileBytes[headerStart..<fileBytes.endIndex].firstIndex(of: 0x0a), secondBreak > headerStart else {
            throw MigrationError.validation("Cabecera de cifrado inválida")
        }
        let headerBytes = fileBytes[headerStart..<secondBreak]
        let headerObject = try JSONSerialization.jsonObject(with: Data(headerBytes))
        guard let header = headerObject as? [String: Any] else {
            throw MigrationError.validation("Cabecera de cifrado inválida")
        }
        try validateHeader(header)

        let salt = try MigrationFormat.decodeBase64(string(header, "salt"))
        let nonceData = try MigrationFormat.decodeBase64(string(header, "nonce"))
        let encrypted = fileBytes[fileBytes.index(after: secondBreak)..<fileBytes.endIndex]
        guard encrypted.count > MigrationFormat.tagBits / 8 else {
            throw MigrationError.crypto("Texto cifrado incompleto")
        }

        let tagStart = encrypted.index(encrypted.endIndex, offsetBy: -(MigrationFormat.tagBits / 8))
        let ciphertext = Data(encrypted[encrypted.startIndex..<tagStart])
        let tag = Data(encrypted[tagStart..<encrypted.endIndex])
        let key = try deriveKey(password: password, salt: salt)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealed = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let plaintext: Data
        do {
            plaintext = try AES.GCM.open(sealed, using: key, authenticating: Data(headerBytes))
        } catch {
            throw MigrationError.crypto("No se pudo descifrar el archivo. Revisa la contraseña o el archivo exportado.")
        }
        return try MigrationFormat.unpackPlaintext(plaintext)
    }

    private func headerJson(parameters: Parameters) throws -> Data {
        let header: [String: Any] = [
            "format": MigrationFormat.formatName,
            "formatVersion": MigrationFormat.formatVersion,
            "cipher": MigrationFormat.cipher,
            "kdf": MigrationFormat.kdf,
            "kdfIterations": MigrationFormat.kdfIterations,
            "salt": MigrationFormat.encodeBase64(parameters.salt),
            "nonce": MigrationFormat.encodeBase64(parameters.nonce),
            "keyLengthBits": MigrationFormat.keyBits,
            "tagLengthBits": MigrationFormat.tagBits
        ]
        return try JSONSerialization.data(withJSONObject: header, options: [])
    }

    private func validateHeader(_ header: [String: Any]) throws {
        guard string(header, "format") == MigrationFormat.formatName else { throw MigrationError.validation("Formato no soportado") }
        guard int(header, "formatVersion") == MigrationFormat.formatVersion else { throw MigrationError.validation("Versión no soportada") }
        guard string(header, "cipher") == MigrationFormat.cipher else { throw MigrationError.validation("Cifrado no soportado") }
        guard string(header, "kdf") == MigrationFormat.kdf else { throw MigrationError.validation("KDF no soportado") }
        guard int(header, "kdfIterations") == MigrationFormat.kdfIterations else { throw MigrationError.validation("Parámetros KDF no soportados") }
        guard int(header, "keyLengthBits") == MigrationFormat.keyBits else { throw MigrationError.validation("Longitud de clave no soportada") }
        guard int(header, "tagLengthBits") == MigrationFormat.tagBits else { throw MigrationError.validation("Etiqueta GCM no soportada") }
    }

    private func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        guard !password.isEmpty else {
            throw MigrationError.validation("La contraseña no puede estar vacía")
        }
        guard let passwordData = password.data(using: .utf8) else {
            throw MigrationError.validation("La contraseña no se pudo codificar")
        }
        var derived = Data(repeating: 0, count: MigrationFormat.keyBits / 8)
        let derivedCount = derived.count

        #if canImport(CommonCrypto)
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.bindMemory(to: Int8.self).baseAddress,
                        passwordData.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress,
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(MigrationFormat.kdfIterations),
                        derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                        derivedCount
                    )
                }
            }
        }
        guard status == kCCSuccess else {
            throw MigrationError.crypto("No se pudo derivar la clave")
        }
        return SymmetricKey(data: derived)
        #else
        throw MigrationError.crypto("PBKDF2-HMAC-SHA256 no está disponible en esta plataforma")
        #endif
    }

    private func randomData(count: Int) throws -> Data {
        var bytes = Data(repeating: 0, count: count)
        let result = bytes.withUnsafeMutableBytes { pointer in
            SecRandomCopyBytes(kSecRandomDefault, count, pointer.baseAddress!)
        }
        guard result == errSecSuccess else {
            throw MigrationError.crypto("No se pudieron generar bytes aleatorios seguros")
        }
        return bytes
    }

    private func string(_ object: [String: Any], _ key: String) -> String {
        object[key] as? String ?? ""
    }

    private func int(_ object: [String: Any], _ key: String) -> Int {
        if let value = object[key] as? Int { return value }
        if let value = object[key] as? NSNumber { return value.intValue }
        return 0
    }
}

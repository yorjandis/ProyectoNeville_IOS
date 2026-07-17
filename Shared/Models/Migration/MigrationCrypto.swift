import Foundation
import CryptoKit
import Security
import Sodium

nonisolated final class MigrationCrypto {
    struct Parameters: Sendable {
        let salt: Data
        let nonce: Data
    }

    private let sodium = Sodium()

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
            "kdfVersion": MigrationFormat.kdfVersion,
            "kdfMemoryKiB": MigrationFormat.kdfMemoryKiB,
            "kdfIterations": MigrationFormat.kdfIterations,
            "kdfParallelism": MigrationFormat.kdfParallelism,
            "passwordNormalization": MigrationFormat.passwordNormalization,
            "salt": MigrationFormat.encodeBase64(parameters.salt),
            "nonce": MigrationFormat.encodeBase64(parameters.nonce),
            "keyLengthBits": MigrationFormat.keyBits,
            "tagLengthBits": MigrationFormat.tagBits
        ]
    }

    func encrypt(plaintext: Data, password: String, parameters: Parameters) throws -> Data {
        guard plaintext.count <= MigrationFormat.maximumPlaintextBytes else {
            throw MigrationError.validation("La exportación supera el tamaño máximo permitido")
        }
        try validateParameters(parameters)

        let headerBytes = try headerJson(parameters: parameters)
        let authenticatedPrefix = filePrefix(headerBytes: headerBytes)
        var keyMaterial = try deriveKey(password: password, salt: parameters.salt)
        defer { sodium.utils.zero(&keyMaterial) }

        let key = SymmetricKey(data: keyMaterial)
        let nonce = try AES.GCM.Nonce(data: parameters.nonce)
        let sealed = try AES.GCM.seal(
            plaintext,
            using: key,
            nonce: nonce,
            authenticating: authenticatedPrefix
        )

        var output = authenticatedPrefix
        output.append(sealed.ciphertext)
        output.append(sealed.tag)
        guard output.count <= MigrationFormat.maximumFileBytes else {
            throw MigrationError.validation("La exportación supera el tamaño máximo permitido")
        }
        return output
    }

    func decrypt(fileBytes: Data, password: String) throws -> MigrationFormat.PlainPackage {
        guard fileBytes.count <= MigrationFormat.maximumFileBytes else {
            throw MigrationError.validation("El archivo supera el tamaño máximo permitido")
        }
        guard let firstBreak = fileBytes.firstIndex(of: 0x0a), firstBreak > fileBytes.startIndex else {
            throw MigrationError.validation("Cabecera de archivo inválida")
        }
        let magicBytes = fileBytes[fileBytes.startIndex..<firstBreak]
        guard String(data: Data(magicBytes), encoding: .utf8) == MigrationFormat.magic else {
            throw MigrationError.validation("Formato de archivo no reconocido; se requiere YPGEXP-2")
        }

        let headerStart = fileBytes.index(after: firstBreak)
        guard let secondBreak = fileBytes[headerStart..<fileBytes.endIndex].firstIndex(of: 0x0a),
              secondBreak > headerStart,
              fileBytes.distance(from: headerStart, to: secondBreak) <= MigrationFormat.maximumHeaderBytes else {
            throw MigrationError.validation("Cabecera de cifrado inválida")
        }
        let headerBytes = Data(fileBytes[headerStart..<secondBreak])
        let headerObject = try JSONSerialization.jsonObject(with: headerBytes)
        guard let header = headerObject as? [String: Any] else {
            throw MigrationError.validation("Cabecera de cifrado inválida")
        }
        try validateHeader(header)

        let salt = try MigrationFormat.decodeBase64(string(header, "salt"))
        let nonceData = try MigrationFormat.decodeBase64(string(header, "nonce"))
        guard salt.count == MigrationFormat.saltBytes,
              nonceData.count == MigrationFormat.nonceBytes,
              MigrationFormat.encodeBase64(salt) == string(header, "salt"),
              MigrationFormat.encodeBase64(nonceData) == string(header, "nonce") else {
            throw MigrationError.validation("Longitud de salt o nonce inválida")
        }

        let encryptedStart = fileBytes.index(after: secondBreak)
        let encrypted = Data(fileBytes[encryptedStart..<fileBytes.endIndex])
        guard encrypted.count > MigrationFormat.tagBits / 8 else {
            throw MigrationError.crypto("Texto cifrado incompleto")
        }
        let tagStart = encrypted.count - (MigrationFormat.tagBits / 8)
        let ciphertext = encrypted.subdata(in: 0..<tagStart)
        let tag = encrypted.subdata(in: tagStart..<encrypted.count)

        var keyMaterial = try deriveKey(password: password, salt: salt)
        defer { sodium.utils.zero(&keyMaterial) }
        let key = SymmetricKey(data: keyMaterial)
        let nonce = try AES.GCM.Nonce(data: nonceData)
        let sealed = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        let authenticatedPrefix = Data(fileBytes[fileBytes.startIndex..<encryptedStart])

        let plaintext: Data
        do {
            plaintext = try AES.GCM.open(sealed, using: key, authenticating: authenticatedPrefix)
        } catch {
            throw MigrationError.crypto("No se pudo autenticar el archivo. Revisa la contraseña o descarta un archivo manipulado.")
        }
        let package = try MigrationFormat.unpackPlaintext(plaintext)
        try validateManifestEncryption(package.manifest, matches: header)
        return package
    }

    private func headerJson(parameters: Parameters) throws -> Data {
        var header = encryptionJson(parameters: parameters)
        header["format"] = MigrationFormat.formatName
        header["formatVersion"] = MigrationFormat.formatVersion
        let data = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        guard data.count <= MigrationFormat.maximumHeaderBytes else {
            throw MigrationError.validation("La cabecera de cifrado supera el tamaño máximo permitido")
        }
        return data
    }

    private func filePrefix(headerBytes: Data) -> Data {
        var prefix = Data(MigrationFormat.magic.utf8)
        prefix.append(0x0a)
        prefix.append(headerBytes)
        prefix.append(0x0a)
        return prefix
    }

    private func validateHeader(_ header: [String: Any]) throws {
        let requiredKeys: Set<String> = [
            "format", "formatVersion", "cipher", "kdf", "kdfVersion", "kdfMemoryKiB",
            "kdfIterations", "kdfParallelism", "passwordNormalization", "salt", "nonce",
            "keyLengthBits", "tagLengthBits"
        ]
        guard Set(header.keys) == requiredKeys else { throw MigrationError.validation("Campos de cabecera no soportados") }
        guard string(header, "format") == MigrationFormat.formatName else { throw MigrationError.validation("Formato no soportado") }
        guard int(header, "formatVersion") == MigrationFormat.formatVersion else { throw MigrationError.validation("Versión no soportada") }
        guard string(header, "cipher") == MigrationFormat.cipher else { throw MigrationError.validation("Cifrado no soportado") }
        guard string(header, "kdf") == MigrationFormat.kdf else { throw MigrationError.validation("KDF no soportado") }
        guard int(header, "kdfVersion") == MigrationFormat.kdfVersion else { throw MigrationError.validation("Versión de Argon2id no soportada") }
        guard int(header, "kdfMemoryKiB") == MigrationFormat.kdfMemoryKiB else { throw MigrationError.validation("Memoria Argon2id no soportada") }
        guard int(header, "kdfIterations") == MigrationFormat.kdfIterations else { throw MigrationError.validation("Iteraciones Argon2id no soportadas") }
        guard int(header, "kdfParallelism") == MigrationFormat.kdfParallelism else { throw MigrationError.validation("Paralelismo Argon2id no soportado") }
        guard string(header, "passwordNormalization") == MigrationFormat.passwordNormalization else { throw MigrationError.validation("Normalización de contraseña no soportada") }
        guard int(header, "keyLengthBits") == MigrationFormat.keyBits else { throw MigrationError.validation("Longitud de clave no soportada") }
        guard int(header, "tagLengthBits") == MigrationFormat.tagBits else { throw MigrationError.validation("Etiqueta GCM no soportada") }
    }

    private func validateParameters(_ parameters: Parameters) throws {
        guard parameters.salt.count == MigrationFormat.saltBytes else {
            throw MigrationError.validation("Longitud de salt inválida")
        }
        guard parameters.nonce.count == MigrationFormat.nonceBytes else {
            throw MigrationError.validation("Longitud de nonce inválida")
        }
    }

    private func validateManifestEncryption(_ manifest: [String: Any], matches header: [String: Any]) throws {
        guard let encryption = manifest["encryption"] as? [String: Any] else {
            throw MigrationError.validation("Metadatos de cifrado ausentes")
        }
        let stringKeys = ["cipher", "kdf", "passwordNormalization", "salt", "nonce"]
        let integerKeys = [
            "kdfVersion", "kdfMemoryKiB", "kdfIterations", "kdfParallelism",
            "keyLengthBits", "tagLengthBits"
        ]
        guard stringKeys.allSatisfy({ string(encryption, $0) == string(header, $0) }),
              integerKeys.allSatisfy({ int(encryption, $0) == int(header, $0) }) else {
            throw MigrationError.validation("El manifiesto y la cabecera criptográfica no coinciden")
        }
    }

    private func deriveKey(password: String, salt: Data) throws -> [UInt8] {
        guard !password.isEmpty else {
            throw MigrationError.validation("La contraseña no puede estar vacía")
        }
        guard salt.count == MigrationFormat.saltBytes else {
            throw MigrationError.validation("Longitud de salt inválida")
        }

        let normalizedPassword = password.precomposedStringWithCanonicalMapping
        var passwordBytes = Array(normalizedPassword.utf8)
        defer { sodium.utils.zero(&passwordBytes) }
        guard passwordBytes.count <= MigrationFormat.maximumPasswordBytes else {
            throw MigrationError.validation("La contraseña es demasiado larga")
        }

        guard let derived = sodium.pwHash.hash(
            outputLength: MigrationFormat.keyBits / 8,
            passwd: passwordBytes,
            salt: Array(salt),
            opsLimit: MigrationFormat.kdfIterations,
            memLimit: MigrationFormat.kdfMemoryKiB * 1_024,
            alg: .Argon2ID13
        ) else {
            throw MigrationError.crypto("No se pudo derivar la clave con Argon2id")
        }
        return derived
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
        guard let value = object[key] as? NSNumber,
              CFGetTypeID(value) != CFBooleanGetTypeID() else {
            return 0
        }
        return Int(value.stringValue) ?? 0
    }
}

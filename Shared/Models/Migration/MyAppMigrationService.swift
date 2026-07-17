import Foundation

@MainActor
final class MyAppMigrationService {
    private let crypto: MigrationCrypto
    private let bridge: CoreDataCanonicalMigrationBridge

    init(
        crypto: MigrationCrypto = MigrationCrypto(),
        bridge: CoreDataCanonicalMigrationBridge = CoreDataCanonicalMigrationBridge()
    ) {
        self.crypto = crypto
        self.bridge = bridge
    }

    func export(password: String) throws -> ExportResult {
        let records = try bridge.exportRecords()
        return try export(records: records, password: password)
    }

    func exportAsync(password: String) async throws -> ExportResult {
        let records = try bridge.exportRecords()
        try validateExportPassword(password)
        let counts = Dictionary(grouping: records, by: \.type).mapValues(\.count)
        let sortedCounts = Dictionary(uniqueKeysWithValues: counts.sorted { $0.key < $1.key })
        let exportId = UUID().uuidString
        let parameters = try crypto.newParameters()
        let manifest = buildManifest(exportId: exportId, countsByType: sortedCounts, parameters: parameters)
        let ndjson = try records.map { try $0.jsonLine() }.joined(separator: "\n") + "\n"
        let plaintext = try MigrationFormat.packPlaintext(manifest: manifest, ndjson: ndjson)

        let encrypted = try await Task.detached(priority: .userInitiated) {
            try MigrationCrypto().encrypt(
                plaintext: plaintext,
                password: password,
                parameters: parameters
            )
        }.value
        return ExportResult(exportId: exportId, countsByType: sortedCounts, bytes: encrypted)
    }

    func export(records: [CanonicalMigrationRecord], password: String) throws -> ExportResult {
        try validateExportPassword(password)
        let counts = Dictionary(grouping: records, by: \.type).mapValues(\.count)
        let sortedCounts = Dictionary(uniqueKeysWithValues: counts.sorted { $0.key < $1.key })
        let exportId = UUID().uuidString
        let parameters = try crypto.newParameters()
        let manifest = buildManifest(exportId: exportId, countsByType: sortedCounts, parameters: parameters)
        let ndjson = try records.map { try $0.jsonLine() }.joined(separator: "\n") + "\n"
        let plaintext = try MigrationFormat.packPlaintext(manifest: manifest, ndjson: ndjson)
        let encrypted = try crypto.encrypt(plaintext: plaintext, password: password, parameters: parameters)
        return ExportResult(exportId: exportId, countsByType: sortedCounts, bytes: encrypted)
    }

    func preview(fileBytes: Data, password: String) throws -> ImportPreview {
        let plainPackage = try crypto.decrypt(fileBytes: fileBytes, password: password)
        try validateManifest(plainPackage.manifest)

        var records: [CanonicalMigrationRecord] = []
        var errors: [String] = []
        plainPackage.ndjson.enumerateLines { rawLine, _ in
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { return }
            do {
                records.append(try CanonicalMigrationRecord.fromJsonLine(line))
            } catch {
                errors.append("Línea \(records.count + errors.count + 1): \(error.localizedDescription)")
            }
        }

        let counts = Dictionary(grouping: records, by: \.type).mapValues(\.count)
        let sortedCounts = Dictionary(uniqueKeysWithValues: counts.sorted { $0.key < $1.key })
        try validateManifestCounts(manifest: plainPackage.manifest, countsByType: sortedCounts)
        let conflicts = try bridge.findConflicts(records: records)
        return ImportPreview(
            manifest: plainPackage.manifest,
            records: records,
            countsByType: sortedCounts,
            conflicts: conflicts,
            errors: errors
        )
    }

    func importPreview(_ preview: ImportPreview, policy: ImportPolicy = .skipExisting) throws -> MigrationSummary {
        guard preview.errors.isEmpty else {
            throw MigrationError.validation("Hay errores de validación pendientes")
        }
        return try bridge.importRecords(preview.records, policy: policy)
    }

    private func buildManifest(
        exportId: String,
        countsByType: [String: Int],
        parameters: MigrationCrypto.Parameters
    ) -> [String: Any] {
        [
            "format": MigrationFormat.formatName,
            "formatVersion": MigrationFormat.formatVersion,
            "createdAt": MigrationFormat.utcNow(),
            "sourcePlatform": "ios",
            "sourceAppVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "schemaVersion": MigrationFormat.schemaVersion,
            "contentSummary": countsByType,
            "encryption": crypto.encryptionJson(parameters: parameters),
            "exportId": exportId
        ]
    }

    private func validateManifest(_ manifest: [String: Any]) throws {
        guard MigrationJSON.string(manifest, "format") == MigrationFormat.formatName else {
            throw MigrationError.validation("Formato no soportado")
        }
        guard MigrationJSON.int(manifest, "formatVersion") == MigrationFormat.formatVersion else {
            throw MigrationError.validation("Versión de formato no soportada")
        }
        guard MigrationJSON.int(manifest, "schemaVersion") <= MigrationFormat.schemaVersion else {
            throw MigrationError.validation("Schema no soportado")
        }
        guard ["ios", "android"].contains(MigrationJSON.string(manifest, "sourcePlatform")) else {
            throw MigrationError.validation("Plataforma de origen inválida")
        }
        guard let encryption = manifest["encryption"] as? [String: Any] else {
            throw MigrationError.validation("Metadatos de cifrado ausentes")
        }
        guard MigrationJSON.string(encryption, "cipher") == MigrationFormat.cipher else {
            throw MigrationError.validation("Cifrado no soportado")
        }
        guard MigrationJSON.string(encryption, "kdf") == MigrationFormat.kdf else {
            throw MigrationError.validation("KDF no soportado")
        }
        guard MigrationJSON.int(encryption, "kdfVersion") == MigrationFormat.kdfVersion,
              MigrationJSON.int(encryption, "kdfMemoryKiB") == MigrationFormat.kdfMemoryKiB,
              MigrationJSON.int(encryption, "kdfIterations") == MigrationFormat.kdfIterations,
              MigrationJSON.int(encryption, "kdfParallelism") == MigrationFormat.kdfParallelism else {
            throw MigrationError.validation("Parámetros Argon2id no soportados")
        }
        guard MigrationJSON.string(encryption, "passwordNormalization") == MigrationFormat.passwordNormalization else {
            throw MigrationError.validation("Normalización de contraseña no soportada")
        }
        guard (manifest["contentSummary"] as? [String: Any]) != nil else {
            throw MigrationError.validation("Resumen inválido")
        }
        guard !MigrationJSON.string(manifest, "exportId").isEmpty else {
            throw MigrationError.validation("exportId vacío")
        }
    }

    private func validateExportPassword(_ password: String) throws {
        let normalizedPassword = password.precomposedStringWithCanonicalMapping
        guard normalizedPassword.unicodeScalars.count >= MigrationFormat.minimumPasswordCharacters else {
            throw MigrationError.validation(
                "La contraseña del archivo debe tener al menos \(MigrationFormat.minimumPasswordCharacters) caracteres."
            )
        }
        guard normalizedPassword.utf8.count <= MigrationFormat.maximumPasswordBytes else {
            throw MigrationError.validation("La contraseña del archivo es demasiado larga.")
        }
    }

    private func validateManifestCounts(manifest: [String: Any], countsByType: [String: Int]) throws {
        guard let summary = manifest["contentSummary"] as? [String: Any] else {
            throw MigrationError.validation("Resumen inválido")
        }
        for (type, count) in countsByType {
            guard MigrationJSON.int(summary, type, default: -1) == count else {
                throw MigrationError.validation("El manifiesto no coincide con data.ndjson para \(type)")
            }
        }
    }
}

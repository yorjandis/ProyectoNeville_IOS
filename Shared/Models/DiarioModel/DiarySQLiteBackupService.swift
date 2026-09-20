import CoreData
import CryptoKit
import Foundation
import Security
import SQLite3
import UniformTypeIdentifiers

#if canImport(CommonCrypto)
import CommonCrypto
#endif

enum DiaryBackupConflictPolicy: String, CaseIterable, Identifiable {
    case keepExisting
    case replaceEntries
    case replaceAttachments
    case replaceBoth

    var id: Self { self }

    var title: String {
        switch self {
        case .keepExisting: "Conservar existentes"
        case .replaceEntries: "Reemplazar entradas"
        case .replaceAttachments: "Reemplazar anexos"
        case .replaceBoth: "Reemplazar entradas y anexos"
        }
    }

    var explanation: String {
        switch self {
        case .keepExisting:
            "Conserva los elementos que ya existen e importa únicamente los nuevos."
        case .replaceEntries:
            "Actualiza todas las entradas coincidentes y conserva sus anexos existentes."
        case .replaceAttachments:
            "Conserva el texto local y sustituye en bloque los anexos de las entradas coincidentes."
        case .replaceBoth:
            "Sustituye en bloque las entradas coincidentes y todos sus anexos."
        }
    }

    var replacesEntries: Bool { self == .replaceEntries || self == .replaceBoth }
    var replacesAttachments: Bool { self == .replaceAttachments || self == .replaceBoth }
}

struct DiaryBackupPreview: Sendable {
    let entryCount: Int
    let attachmentCount: Int
    let conflictingEntries: Int
    let conflictingAttachments: Int
}

struct DiaryBackupRestoreSummary: Sendable {
    let insertedEntries: Int
    let replacedEntries: Int
    let insertedAttachments: Int
    let replacedAttachments: Int
    let skippedEntries: Int
    let skippedAttachments: Int
}

enum DiaryBackupError: LocalizedError {
    case invalidPassword
    case invalidDatabase
    case unsupportedVersion(Int)
    case sqlite(String)
    case missingIdentifier
    case emptyPassword

    var errorDescription: String? {
        switch self {
        case .invalidPassword: "La contraseña no es correcta o el archivo está dañado."
        case .invalidDatabase: "El archivo no es una copia SQLite válida del Diario."
        case .unsupportedVersion(let version): "La versión de esta copia (\(version)) no es compatible."
        case .sqlite(let message): "SQLite no pudo completar la operación: \(message)"
        case .missingIdentifier: "Una entrada o anexo no contiene un identificador válido."
        case .emptyPassword: "Introduce una contraseña para proteger la copia."
        }
    }
}

nonisolated struct DiaryBackupEntryRecord: Codable, Sendable {
    let id: UUID
    let title: String
    let content: String
    let emotion: String
    let chapter: String
    let mapAddress: String
    let favorite: Bool
    let createdAt: Date?
    let modifiedAt: Date?
}

nonisolated struct DiaryBackupAttachmentMetadata: Codable, Sendable {
    let fileName: String
    let encryptedFileName: String
    let fileSize: Int64
    let createdAt: Date?
    let sourceCryptoVersion: Int16
}

nonisolated struct DiaryBackupAttachmentRecord: Sendable {
    let id: UUID
    let entryID: UUID
    let uti: String
    let attachmentClass: String
    let metadata: DiaryBackupAttachmentMetadata
    let clearData: Data
}

nonisolated struct DiaryBackupArchive: Sendable {
    let entries: [DiaryBackupEntryRecord]
    let attachments: [DiaryBackupAttachmentRecord]
}

actor DiarySQLiteBackupCodec {
    static let shared = DiarySQLiteBackupCodec()

    private let formatVersion = 1
    private let iterations = 210_000
    private let verificationText = Data("NevilleDiarySQLiteBackup/v1".utf8)

    func write(_ archive: DiaryBackupArchive, to destination: URL, password: String) throws {
        guard !password.isEmpty else { throw DiaryBackupError.emptyPassword }
        try? FileManager.default.removeItem(at: destination)

        var database: OpaquePointer?
        guard sqlite3_open_v2(destination.path, &database, SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE, nil) == SQLITE_OK,
              let database else {
            throw DiaryBackupError.sqlite("No se pudo crear el archivo.")
        }
        defer { sqlite3_close(database) }

        let salt = randomData(count: 32)
        let key = try deriveKey(password: password, salt: salt, iterations: iterations)
        try execute(database, "PRAGMA journal_mode=DELETE;")
        try execute(database, "PRAGMA secure_delete=ON;")
        try execute(database, "PRAGMA foreign_keys=ON;")
        try execute(database, "CREATE TABLE metadata (key TEXT PRIMARY KEY NOT NULL, value BLOB NOT NULL);")
        try execute(database, "CREATE TABLE entries (id TEXT PRIMARY KEY NOT NULL, encrypted_record BLOB NOT NULL);")
        try execute(database, "CREATE TABLE attachments (id TEXT PRIMARY KEY NOT NULL, entry_id TEXT NOT NULL, uti TEXT NOT NULL, attachment_class TEXT NOT NULL, encrypted_metadata BLOB NOT NULL, encrypted_data BLOB NOT NULL, FOREIGN KEY(entry_id) REFERENCES entries(id) ON DELETE CASCADE);")
        try execute(database, "CREATE INDEX attachments_entry_idx ON attachments(entry_id);")
        try execute(database, "BEGIN IMMEDIATE TRANSACTION;")

        do {
            try insertMetadata(database, key: "format", value: Data("neville.diary.sqlite.backup".utf8))
            try insertMetadata(database, key: "version", value: Data(String(formatVersion).utf8))
            try insertMetadata(database, key: "kdf", value: Data("PBKDF2-HMAC-SHA256".utf8))
            try insertMetadata(database, key: "iterations", value: Data(String(iterations).utf8))
            try insertMetadata(database, key: "salt", value: salt)
            try insertMetadata(database, key: "created_at", value: Data(ISO8601DateFormatter().string(from: .now).utf8))
            try insertMetadata(database, key: "key_check", value: try seal(verificationText, using: key))

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            for entry in archive.entries {
                try insertEntry(database, id: entry.id, encryptedRecord: try seal(encoder.encode(entry), using: key))
            }
            for attachment in archive.attachments {
                try insertAttachment(
                    database,
                    record: attachment,
                    encryptedMetadata: try seal(encoder.encode(attachment.metadata), using: key),
                    encryptedData: try seal(attachment.clearData, using: key)
                )
            }
            try execute(database, "COMMIT;")
        } catch {
            try? execute(database, "ROLLBACK;")
            throw error
        }
    }

    func read(from source: URL, password: String) throws -> DiaryBackupArchive {
        guard !password.isEmpty else { throw DiaryBackupError.emptyPassword }
        var database: OpaquePointer?
        guard sqlite3_open_v2(source.path, &database, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
              let database else {
            throw DiaryBackupError.invalidDatabase
        }
        defer { sqlite3_close(database) }

        guard String(data: try metadata(database, key: "format"), encoding: .utf8) == "neville.diary.sqlite.backup",
              let version = Int(String(data: try metadata(database, key: "version"), encoding: .utf8) ?? "") else {
            throw DiaryBackupError.invalidDatabase
        }
        guard version == formatVersion else { throw DiaryBackupError.unsupportedVersion(version) }
        let salt = try metadata(database, key: "salt")
        let storedIterations = Int(String(data: try metadata(database, key: "iterations"), encoding: .utf8) ?? "") ?? iterations
        guard (10_000...1_000_000).contains(storedIterations) else {
            throw DiaryBackupError.invalidDatabase
        }
        let key = try deriveKey(password: password, salt: salt, iterations: storedIterations)
        do {
            guard try open(metadata(database, key: "key_check"), using: key) == verificationText else {
                throw DiaryBackupError.invalidPassword
            }
        } catch {
            throw DiaryBackupError.invalidPassword
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let entries = try readRows(database, sql: "SELECT encrypted_record FROM entries ORDER BY rowid;") { statement in
            try decoder.decode(DiaryBackupEntryRecord.self, from: open(columnData(statement, index: 0), using: key))
        }
        let attachments = try readRows(database, sql: "SELECT id, entry_id, uti, attachment_class, encrypted_metadata, encrypted_data FROM attachments ORDER BY rowid;") { statement in
            guard let id = UUID(uuidString: columnText(statement, index: 0)),
                  let entryID = UUID(uuidString: columnText(statement, index: 1)) else {
                throw DiaryBackupError.missingIdentifier
            }
            return DiaryBackupAttachmentRecord(
                id: id,
                entryID: entryID,
                uti: columnText(statement, index: 2),
                attachmentClass: columnText(statement, index: 3),
                metadata: try decoder.decode(DiaryBackupAttachmentMetadata.self, from: open(columnData(statement, index: 4), using: key)),
                clearData: try open(columnData(statement, index: 5), using: key)
            )
        }
        return DiaryBackupArchive(entries: entries, attachments: attachments)
    }

    private func deriveKey(password: String, salt: Data, iterations: Int) throws -> SymmetricKey {
#if canImport(CommonCrypto)
        let passwordBytes = Array(password.utf8)
        var derivedBytes = [UInt8](repeating: 0, count: 32)
        let status = passwordBytes.withUnsafeBytes { passwordBuffer in
            salt.withUnsafeBytes { saltBuffer in
                derivedBytes.withUnsafeMutableBytes { derivedBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordBuffer.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        saltBuffer.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        derivedBuffer.count
                    )
                }
            }
        }
        guard status == kCCSuccess else {
            throw DiaryBackupError.invalidDatabase
        }
        return SymmetricKey(data: derivedBytes)
#else
        let passwordKey = SymmetricKey(data: Data(password.utf8))
        var block = salt
        block.append(contentsOf: [0, 0, 0, 1])
        var previous = Data(HMAC<SHA256>.authenticationCode(for: block, using: passwordKey))
        var result = previous
        if iterations > 1 {
            for _ in 1..<iterations {
                previous = Data(HMAC<SHA256>.authenticationCode(for: previous, using: passwordKey))
                let byteCount = result.count
                result.withUnsafeMutableBytes { resultBuffer in
                    previous.withUnsafeBytes { previousBuffer in
                        guard let resultBase = resultBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                              let previousBase = previousBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                        for index in 0..<byteCount { resultBase[index] ^= previousBase[index] }
                    }
                }
            }
        }
        return SymmetricKey(data: result)
#endif
    }

    private func seal(_ data: Data, using key: SymmetricKey) throws -> Data {
        guard let combined = try AES.GCM.seal(data, using: key).combined else {
            throw DiaryBackupError.invalidDatabase
        }
        return combined
    }

    private func open(_ data: Data, using key: SymmetricKey) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key)
    }

    private func randomData(count: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: count)
        _ = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
        return Data(bytes)
    }

    private func execute(_ database: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw DiaryBackupError.sqlite(String(cString: sqlite3_errmsg(database)))
        }
    }

    private func insertMetadata(_ database: OpaquePointer, key: String, value: Data) throws {
        try withStatement(database, sql: "INSERT INTO metadata(key, value) VALUES(?, ?);") { statement in
            bindText(statement, index: 1, value: key)
            bindData(statement, index: 2, value: value)
            try stepDone(database, statement)
        }
    }

    private func metadata(_ database: OpaquePointer, key: String) throws -> Data {
        try withStatement(database, sql: "SELECT value FROM metadata WHERE key = ? LIMIT 1;") { statement in
            bindText(statement, index: 1, value: key)
            guard sqlite3_step(statement) == SQLITE_ROW else { throw DiaryBackupError.invalidDatabase }
            return columnData(statement, index: 0)
        }
    }

    private func insertEntry(_ database: OpaquePointer, id: UUID, encryptedRecord: Data) throws {
        try withStatement(database, sql: "INSERT INTO entries(id, encrypted_record) VALUES(?, ?);") { statement in
            bindText(statement, index: 1, value: id.uuidString.lowercased())
            bindData(statement, index: 2, value: encryptedRecord)
            try stepDone(database, statement)
        }
    }

    private func insertAttachment(_ database: OpaquePointer, record: DiaryBackupAttachmentRecord, encryptedMetadata: Data, encryptedData: Data) throws {
        try withStatement(database, sql: "INSERT INTO attachments(id, entry_id, uti, attachment_class, encrypted_metadata, encrypted_data) VALUES(?, ?, ?, ?, ?, ?);") { statement in
            bindText(statement, index: 1, value: record.id.uuidString.lowercased())
            bindText(statement, index: 2, value: record.entryID.uuidString.lowercased())
            bindText(statement, index: 3, value: record.uti)
            bindText(statement, index: 4, value: record.attachmentClass)
            bindData(statement, index: 5, value: encryptedMetadata)
            bindData(statement, index: 6, value: encryptedData)
            try stepDone(database, statement)
        }
    }

    private func withStatement<T>(_ database: OpaquePointer, sql: String, body: (OpaquePointer) throws -> T) throws -> T {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            throw DiaryBackupError.sqlite(String(cString: sqlite3_errmsg(database)))
        }
        defer { sqlite3_finalize(statement) }
        return try body(statement)
    }

    private func readRows<T>(_ database: OpaquePointer, sql: String, transform: (OpaquePointer) throws -> T) throws -> [T] {
        try withStatement(database, sql: sql) { statement in
            var rows: [T] = []
            while true {
                let result = sqlite3_step(statement)
                if result == SQLITE_DONE { break }
                guard result == SQLITE_ROW else { throw DiaryBackupError.sqlite(String(cString: sqlite3_errmsg(database))) }
                rows.append(try transform(statement))
            }
            return rows
        }
    }

    private func stepDone(_ database: OpaquePointer, _ statement: OpaquePointer) throws {
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DiaryBackupError.sqlite(String(cString: sqlite3_errmsg(database)))
        }
    }

    private func bindText(_ statement: OpaquePointer, index: Int32, value: String) {
        sqlite3_bind_text(statement, index, value, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
    }

    private func bindData(_ statement: OpaquePointer, index: Int32, value: Data) {
        _ = value.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(buffer.count), unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
    }

    private func columnText(_ statement: OpaquePointer, index: Int32) -> String {
        guard let text = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: text)
    }

    private func columnData(_ statement: OpaquePointer, index: Int32) -> Data {
        guard let bytes = sqlite3_column_blob(statement, index) else { return Data() }
        return Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, index)))
    }
}

@MainActor
final class DiarySQLiteBackupService {
    private let context = CoreDataController.shared.context

    func export(password: String) async throws -> URL {
        guard !password.isEmpty else { throw DiaryBackupError.emptyPassword }
        let request: NSFetchRequest<Diario> = Diario.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Diario.fecha, ascending: true)]
        let diaries = try context.fetch(request)
        var entries: [DiaryBackupEntryRecord] = []
        var attachments: [DiaryBackupAttachmentRecord] = []

        for diary in diaries {
            guard let entryID = diary.id else { throw DiaryBackupError.missingIdentifier }
            entries.append(entryRecord(from: diary, id: entryID))
            for attachment in try DiaryAttachmentStore.shared.attachments(for: diary) {
                guard let attachmentID = attachment.id else { throw DiaryBackupError.missingIdentifier }
                let uti = attachment.utiString ?? UTType.data.identifier
                attachments.append(
                    DiaryBackupAttachmentRecord(
                        id: attachmentID,
                        entryID: entryID,
                        uti: uti,
                        attachmentClass: attachmentClass(for: uti),
                        metadata: DiaryBackupAttachmentMetadata(
                            fileName: attachment.fileName ?? "Archivo",
                            encryptedFileName: attachment.fileNameEncrip ?? "\(attachmentID.uuidString).nevenc",
                            fileSize: attachment.fileSize,
                            createdAt: attachment.createdAt,
                            sourceCryptoVersion: attachment.cryptoVersion
                        ),
                        clearData: try await DiaryAttachmentStore.shared.decryptedData(for: attachment)
                    )
                )
            }
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("NevilleDiaryBackups", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let date = ISO8601DateFormatter().string(from: .now).prefix(10)
        let destination = directory.appendingPathComponent("Neville-Diario-\(date).sqlite")
        try await DiarySQLiteBackupCodec.shared.write(
            DiaryBackupArchive(entries: entries, attachments: attachments),
            to: destination,
            password: password
        )
        return destination
    }

    func loadArchive(from url: URL, password: String) async throws -> DiaryBackupArchive {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        return try await DiarySQLiteBackupCodec.shared.read(from: url, password: password)
    }

    func preview(_ archive: DiaryBackupArchive) throws -> DiaryBackupPreview {
        let entryIDs = Set(archive.entries.map(\.id))
        let attachmentIDs = Set(archive.attachments.map(\.id))
        let entryRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        entryRequest.predicate = NSPredicate(format: "id IN %@", Array(entryIDs))
        let attachmentRequest = NSFetchRequest<DiarioAttachment>(entityName: "DiarioAttachment")
        attachmentRequest.predicate = NSPredicate(format: "id IN %@", Array(attachmentIDs))
        return DiaryBackupPreview(
            entryCount: archive.entries.count,
            attachmentCount: archive.attachments.count,
            conflictingEntries: try context.count(for: entryRequest),
            conflictingAttachments: try context.count(for: attachmentRequest)
        )
    }

    func restore(_ archive: DiaryBackupArchive, policy: DiaryBackupConflictPolicy) async throws -> DiaryBackupRestoreSummary {
        let entryRequest: NSFetchRequest<Diario> = Diario.fetchRequest()
        let existingEntries = try context.fetch(entryRequest)
        var entriesByID = Dictionary(uniqueKeysWithValues: existingEntries.compactMap { entry in entry.id.map { ($0, entry) } })
        let attachmentRequest = NSFetchRequest<DiarioAttachment>(entityName: "DiarioAttachment")
        let existingAttachments = try context.fetch(attachmentRequest)
        var attachmentsByID = Dictionary(uniqueKeysWithValues: existingAttachments.compactMap { item in item.id.map { ($0, item) } })
        let conflictedEntryIDs = Set(archive.entries.map(\.id)).intersection(Set(entriesByID.keys))

        var insertedEntries = 0
        var replacedEntries = 0
        var skippedEntries = 0
        var insertedAttachments = 0
        var replacedAttachments = 0
        var skippedAttachments = 0

        if policy.replacesAttachments {
            for entryID in conflictedEntryIDs {
                guard let entry = entriesByID[entryID] else { continue }
                for attachment in try DiaryAttachmentStore.shared.attachments(for: entry) {
                    if let id = attachment.id { attachmentsByID.removeValue(forKey: id) }
                    context.delete(attachment)
                    replacedAttachments += 1
                }
            }
        }

        do {
            for record in archive.entries {
                if let existing = entriesByID[record.id] {
                    if policy.replacesEntries {
                        apply(record, to: existing)
                        replacedEntries += 1
                    } else {
                        skippedEntries += 1
                    }
                } else {
                    let entry = Diario(context: context)
                    apply(record, to: entry)
                    entriesByID[record.id] = entry
                    insertedEntries += 1
                }
            }

            for record in archive.attachments {
                guard let entry = entriesByID[record.entryID] else { throw DiaryBackupError.missingIdentifier }
                if let existing = attachmentsByID[record.id] {
                    if policy.replacesAttachments {
                        context.delete(existing)
                        attachmentsByID.removeValue(forKey: record.id)
                        replacedAttachments += 1
                    } else {
                        skippedAttachments += 1
                        continue
                    }
                }
                let payload = try await DiaryAttachmentCryptor.shared.encrypt(record.clearData, attachmentID: record.id)
                let attachment = DiarioAttachment(context: context)
                attachment.id = record.id
                attachment.fileName = record.metadata.fileName
                attachment.fileNameEncrip = "\(record.id.uuidString).nevenc"
                attachment.utiString = record.uti
                attachment.fileSize = Int64(record.clearData.count)
                attachment.createdAt = record.metadata.createdAt
                attachment.cryptoVersion = 1
                attachment.fileData = payload.encryptedData
                attachment.encapsulatedKey = payload.encapsulatedKey
                attachment.diario = entry
                attachmentsByID[record.id] = attachment
                insertedAttachments += 1
            }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        return DiaryBackupRestoreSummary(
            insertedEntries: insertedEntries,
            replacedEntries: replacedEntries,
            insertedAttachments: insertedAttachments,
            replacedAttachments: replacedAttachments,
            skippedEntries: skippedEntries,
            skippedAttachments: skippedAttachments
        )
    }

    private func entryRecord(from diary: Diario, id: UUID) -> DiaryBackupEntryRecord {
        DiaryBackupEntryRecord(
            id: id,
            title: diary.title ?? "",
            content: diary.content ?? "",
            emotion: diary.emotion ?? "",
            chapter: diary.capitulo ?? "",
            mapAddress: diary.direccionMapa ?? "",
            favorite: diary.isFav,
            createdAt: diary.fecha,
            modifiedAt: diary.fechaM
        )
    }

    private func apply(_ record: DiaryBackupEntryRecord, to diary: Diario) {
        diary.id = record.id
        diary.title = record.title
        diary.content = record.content
        diary.emotion = record.emotion
        diary.capitulo = record.chapter
        diary.direccionMapa = record.mapAddress
        diary.isFav = record.favorite
        diary.fecha = record.createdAt
        diary.fechaM = record.modifiedAt
    }

    private func attachmentClass(for identifier: String) -> String {
        guard let type = UTType(identifier) else { return "other" }
        if type.conforms(to: .image) { return "image" }
        if type.conforms(to: .pdf) { return "pdf" }
        if type.conforms(to: .content) && ["doc", "docx"].contains(type.preferredFilenameExtension ?? "") { return "word" }
        return "other"
    }
}

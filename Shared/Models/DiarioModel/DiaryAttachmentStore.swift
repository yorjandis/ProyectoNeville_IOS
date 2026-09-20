import CoreData
import CryptoKit
import Foundation
import ImageIO
import Security
import UniformTypeIdentifiers

enum DiaryAttachmentError: LocalizedError {
    case unsupportedSystem
    case missingData
    case invalidFile
    case keychain(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unsupportedSystem:
            return "Este dispositivo necesita una versión más reciente del sistema para proteger y abrir anexos."
        case .missingData:
            return "El archivo cifrado todavía no está disponible en este dispositivo."
        case .invalidFile:
            return "No se pudo leer o procesar el archivo."
        case .keychain:
            return "No se pudo acceder de forma segura a la clave de los anexos. Comprueba que iCloud esté disponible e inténtalo de nuevo."
        }
    }
}

struct DiaryAttachmentPayload: Sendable {
    let encryptedData: Data
    let encapsulatedKey: Data
}

actor DiaryAttachmentCryptor {
    static let shared = DiaryAttachmentCryptor()

    private let keychainService = "com.ypg.nev.diary-attachments"
    private let keychainAccount = "mlkem1024-master-seed-v1"

    func encrypt(_ clearData: Data, attachmentID: UUID) throws -> DiaryAttachmentPayload {
        guard #available(iOS 26.0, macOS 26.0, *) else {
            throw DiaryAttachmentError.unsupportedSystem
        }
        return try encryptQuantumSafe(clearData, attachmentID: attachmentID)
    }

    func decrypt(_ payload: DiaryAttachmentPayload, attachmentID: UUID) throws -> Data {
        guard #available(iOS 26.0, macOS 26.0, *) else {
            throw DiaryAttachmentError.unsupportedSystem
        }
        return try decryptQuantumSafe(payload, attachmentID: attachmentID)
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func encryptQuantumSafe(_ clearData: Data, attachmentID: UUID) throws -> DiaryAttachmentPayload {
        let privateKey = try persistentPrivateKey()
        let encapsulation = try privateKey.publicKey.encapsulate()
        let sealedBox = try AES.GCM.seal(
            clearData,
            using: encapsulation.sharedSecret,
            authenticating: Data(attachmentID.uuidString.utf8)
        )
        guard let combined = sealedBox.combined else {
            throw DiaryAttachmentError.invalidFile
        }
        return DiaryAttachmentPayload(
            encryptedData: combined,
            encapsulatedKey: encapsulation.encapsulated
        )
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func decryptQuantumSafe(_ payload: DiaryAttachmentPayload, attachmentID: UUID) throws -> Data {
        let privateKey = try persistentPrivateKey()
        let key = try privateKey.decapsulate(payload.encapsulatedKey)
        let sealedBox = try AES.GCM.SealedBox(combined: payload.encryptedData)
        return try AES.GCM.open(
            sealedBox,
            using: key,
            authenticating: Data(attachmentID.uuidString.utf8)
        )
    }

    @available(iOS 26.0, macOS 26.0, *)
    private func persistentPrivateKey() throws -> MLKEM1024.PrivateKey {
        if let seed = try readSeed() {
            return try MLKEM1024.PrivateKey(seedRepresentation: seed, publicKey: nil)
        }

        let key = try MLKEM1024.PrivateKey()
        try saveSeed(key.seedRepresentation)
        return key
    }

    private func readSeed() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw DiaryAttachmentError.keychain(status)
        }
        return data
    }

    private func saveSeed(_ seed: Data) throws {
        let item: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: seed
        ]
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw DiaryAttachmentError.keychain(status)
        }
    }
}

enum DiaryAttachmentImageProcessor {
    nonisolated static func compressedDataIfNeeded(
        _ data: Data,
        contentType: UTType,
        quality: Double
    ) -> Data {
        guard contentType.conforms(to: .image),
              contentType != .png,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return data
        }

        let output = NSMutableData()
        guard let finalDestination = CGImageDestinationCreateWithData(
            output,
            contentType.identifier as CFString,
            1,
            nil
        ) else {
            return data
        }
        CGImageDestinationAddImage(
            finalDestination,
            image,
            [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        )
        return CGImageDestinationFinalize(finalDestination) ? output as Data : data
    }
}

@MainActor
final class DiaryAttachmentStore {
    static let shared = DiaryAttachmentStore()

    private let container = CoreDataController.shared.persistentContainer

    func attachments(for diario: Diario) throws -> [DiarioAttachment] {
        let request = NSFetchRequest<DiarioAttachment>(entityName: "DiarioAttachment")
        request.predicate = NSPredicate(format: "diario == %@", diario)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \DiarioAttachment.createdAt, ascending: true)
        ]
        request.returnsObjectsAsFaults = false
        return try container.viewContext.fetch(request)
    }

    func importFile(
        from url: URL,
        into diario: Diario,
        imageQuality: Double
    ) async throws {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        let values = try url.resourceValues(forKeys: [.contentTypeKey, .nameKey])
        let contentType = values.contentType ?? UTType(filenameExtension: url.pathExtension) ?? .data
        let sourceData = try Data(contentsOf: url, options: .mappedIfSafe)
        let preparedData = await Task.detached(priority: .userInitiated) {
            DiaryAttachmentImageProcessor.compressedDataIfNeeded(
                sourceData,
                contentType: contentType,
                quality: imageQuality
            )
        }.value
        try await insert(
            data: preparedData,
            fileName: values.name ?? url.lastPathComponent,
            contentType: contentType,
            into: diario
        )
    }

    func importPhoto(
        data: Data,
        contentType: UTType,
        into diario: Diario,
        imageQuality: Double
    ) async throws {
        let preparedData = await Task.detached(priority: .userInitiated) {
            DiaryAttachmentImageProcessor.compressedDataIfNeeded(
                data,
                contentType: contentType,
                quality: imageQuality
            )
        }.value
        let fileExtension = contentType.preferredFilenameExtension ?? "img"
        try await insert(
            data: preparedData,
            fileName: "Foto-\(UUID().uuidString.prefix(8)).\(fileExtension)",
            contentType: contentType,
            into: diario
        )
    }

    func importData(
        _ data: Data,
        fileName: String,
        contentType: UTType,
        into diario: Diario,
        imageQuality: Double
    ) async throws {
        let preparedData = await Task.detached(priority: .userInitiated) {
            DiaryAttachmentImageProcessor.compressedDataIfNeeded(
                data,
                contentType: contentType,
                quality: imageQuality
            )
        }.value
        try await insert(
            data: preparedData,
            fileName: fileName,
            contentType: contentType,
            into: diario
        )
    }

    func decryptedData(for attachment: DiarioAttachment) async throws -> Data {
        guard let id = attachment.id,
              let fileData = attachment.fileData,
              let encapsulatedKey = attachment.encapsulatedKey else {
            throw DiaryAttachmentError.missingData
        }
        return try await DiaryAttachmentCryptor.shared.decrypt(
            DiaryAttachmentPayload(encryptedData: fileData, encapsulatedKey: encapsulatedKey),
            attachmentID: id
        )
    }

    func rename(_ attachment: DiarioAttachment, to proposedName: String) throws {
        let trimmed = proposedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DiaryAttachmentError.invalidFile }
        let existingExtension = (attachment.fileName ?? "").split(separator: ".").last.map(String.init) ?? ""
        attachment.fileName = trimmed.contains(".") || existingExtension.isEmpty
            ? trimmed
            : "\(trimmed).\(existingExtension)"
        attachment.diario?.fechaM = .now
        try saveViewContext()
    }

    func move(_ attachment: DiarioAttachment, to destination: Diario) throws {
        guard attachment.diario != destination else { return }
        attachment.diario = destination
        destination.fechaM = .now
        try saveViewContext()
    }

    func delete(_ attachment: DiarioAttachment) throws {
        container.viewContext.delete(attachment)
        try saveViewContext()
    }

    private func insert(
        data: Data,
        fileName: String,
        contentType: UTType,
        into diario: Diario
    ) async throws {
        let id = UUID()
        let payload = try await DiaryAttachmentCryptor.shared.encrypt(data, attachmentID: id)
        let context = container.viewContext
        let attachment = DiarioAttachment(context: context)
        attachment.id = id
        attachment.fileName = fileName
        attachment.fileNameEncrip = "\(id.uuidString).nevenc"
        attachment.utiString = contentType.identifier
        attachment.fileSize = Int64(data.count)
        attachment.createdAt = .now
        attachment.cryptoVersion = 1
        attachment.fileData = payload.encryptedData
        attachment.encapsulatedKey = payload.encapsulatedKey
        attachment.diario = diario
        diario.fechaM = .now
        try saveViewContext()
    }

    private func saveViewContext() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}

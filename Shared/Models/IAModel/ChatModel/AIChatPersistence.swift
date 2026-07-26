//
//  AIChatPersistence.swift
//  Neville_iOS
//
//  Persistencia local y privada del historial de conversaciones de IA.
//

import CoreData
import Foundation

struct StoredAIConversation: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var authorRawValue: String
    var createdAt: Date
    var updatedAt: Date
    var summary: String?
    var transcriptData: Data?
    var promptVersion: Int
    var usesPersonalVoice: Bool
    var languageRawValue: String
}

struct StoredAIMessage: Identifiable, Equatable, Sendable {
    let id: UUID
    let conversationID: UUID
    var roleRawValue: String
    var text: String
    var createdAt: Date
    var sequence: Int64
    var statusRawValue: String
    var errorDescription: String?
}

@objc(AIConversationRecord)
private final class AIConversationRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var authorRawValue: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var summary: String?
    @NSManaged var transcriptData: Data?
    @NSManaged var promptVersion: Int32
    @NSManaged var usesPersonalVoice: Bool
    @NSManaged var languageRawValue: String
    @NSManaged var messages: Set<AIMessageRecord>
}

@objc(AIMessageRecord)
private final class AIMessageRecord: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var conversationID: UUID
    @NSManaged var roleRawValue: String
    @NSManaged var text: String
    @NSManaged var createdAt: Date
    @NSManaged var sequence: Int64
    @NSManaged var statusRawValue: String
    @NSManaged var errorDescription: String?
    @NSManaged var conversation: AIConversationRecord
}

@MainActor
final class AIChatStore {
    static let shared = AIChatStore()

    private let container: NSPersistentContainer
    private var loadResult: Result<Void, Error>?
    private var loadWaiters: [CheckedContinuation<Void, Error>] = []

    private init() {
        container = NSPersistentContainer(
            name: "AIChatHistory",
            managedObjectModel: Self.makeManagedObjectModel()
        )

        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("AIChatHistory.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        #if os(iOS)
        description.setOption(
            FileProtectionType.completeUntilFirstUserAuthentication as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )
        #endif
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { [weak self] _, error in
            Task { @MainActor [weak self] in
                self?.finishLoading(error: error)
            }
        }
        container.viewContext.mergePolicy = NSMergePolicy(
            merge: .mergeByPropertyObjectTrumpMergePolicyType
        )
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func conversations() async throws -> [StoredAIConversation] {
        try await ensureLoaded()
        let request = NSFetchRequest<AIConversationRecord>(entityName: "AIConversationRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        return try container.viewContext.fetch(request).map(Self.makeConversation)
    }

    func conversation(id: UUID) async throws -> StoredAIConversation? {
        try await ensureLoaded()
        return try fetchConversation(id: id).map(Self.makeConversation)
    }

    func messages(conversationID: UUID) async throws -> [StoredAIMessage] {
        try await ensureLoaded()
        let request = NSFetchRequest<AIMessageRecord>(entityName: "AIMessageRecord")
        request.predicate = NSPredicate(format: "conversationID == %@", conversationID as CVarArg)
        request.sortDescriptors = [
            NSSortDescriptor(key: "sequence", ascending: true),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]
        return try container.viewContext.fetch(request).map(Self.makeMessage)
    }

    @discardableResult
    func createConversation(
        id: UUID = UUID(),
        title: String,
        authorRawValue: String,
        promptVersion: Int,
        usesPersonalVoice: Bool,
        languageRawValue: String
    ) async throws -> StoredAIConversation {
        try await ensureLoaded()
        let now = Date()
        let record = AIConversationRecord(
            entity: Self.conversationEntity(in: container.managedObjectModel),
            insertInto: container.viewContext
        )
        record.id = id
        record.title = title
        record.authorRawValue = authorRawValue
        record.createdAt = now
        record.updatedAt = now
        record.promptVersion = Int32(promptVersion)
        record.usesPersonalVoice = usesPersonalVoice
        record.languageRawValue = languageRawValue
        record.messages = []
        try save()
        return Self.makeConversation(record)
    }

    func appendMessage(_ message: StoredAIMessage) async throws {
        try await ensureLoaded()
        guard let conversation = try fetchConversation(id: message.conversationID) else {
            throw AIChatPersistenceError.conversationNotFound
        }

        let record = AIMessageRecord(
            entity: Self.messageEntity(in: container.managedObjectModel),
            insertInto: container.viewContext
        )
        record.id = message.id
        record.conversationID = message.conversationID
        record.roleRawValue = message.roleRawValue
        record.text = message.text
        record.createdAt = message.createdAt
        record.sequence = message.sequence
        record.statusRawValue = message.statusRawValue
        record.errorDescription = message.errorDescription
        record.conversation = conversation
        conversation.updatedAt = Date()
        try save()
    }

    func updateMessage(
        id: UUID,
        text: String,
        statusRawValue: String,
        errorDescription: String?
    ) async throws {
        try await ensureLoaded()
        let request = NSFetchRequest<AIMessageRecord>(entityName: "AIMessageRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        guard let record = try container.viewContext.fetch(request).first else {
            throw AIChatPersistenceError.messageNotFound
        }
        record.text = text
        record.statusRawValue = statusRawValue
        record.errorDescription = errorDescription
        record.conversation.updatedAt = Date()
        try save()
    }

    func updateConversationContext(
        id: UUID,
        summary: String?,
        transcriptData: Data?,
        promptVersion: Int
    ) async throws {
        try await ensureLoaded()
        guard let record = try fetchConversation(id: id) else {
            throw AIChatPersistenceError.conversationNotFound
        }
        record.summary = summary
        record.transcriptData = transcriptData
        record.promptVersion = Int32(promptVersion)
        record.updatedAt = Date()
        try save()
    }

    func renameConversation(id: UUID, title: String) async throws {
        try await ensureLoaded()
        guard let record = try fetchConversation(id: id) else {
            throw AIChatPersistenceError.conversationNotFound
        }
        record.title = title
        record.updatedAt = Date()
        try save()
    }

    func deleteConversation(id: UUID) async throws {
        try await ensureLoaded()
        guard let record = try fetchConversation(id: id) else { return }
        container.viewContext.delete(record)
        try save()
    }

    private func ensureLoaded() async throws {
        if let loadResult {
            return try loadResult.get()
        }
        try await withCheckedThrowingContinuation { continuation in
            loadWaiters.append(continuation)
        }
    }

    private func finishLoading(error: Error?) {
        let result: Result<Void, Error> = error.map(Result.failure) ?? .success(())
        loadResult = result
        let waiters = loadWaiters
        loadWaiters.removeAll()
        for waiter in waiters {
            waiter.resume(with: result)
        }
    }

    private func fetchConversation(id: UUID) throws -> AIConversationRecord? {
        let request = NSFetchRequest<AIConversationRecord>(entityName: "AIConversationRecord")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try container.viewContext.fetch(request).first
    }

    private func save() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func makeConversation(_ record: AIConversationRecord) -> StoredAIConversation {
        StoredAIConversation(
            id: record.id,
            title: record.title,
            authorRawValue: record.authorRawValue,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            summary: record.summary,
            transcriptData: record.transcriptData,
            promptVersion: Int(record.promptVersion),
            usesPersonalVoice: record.usesPersonalVoice,
            languageRawValue: record.languageRawValue
        )
    }

    private static func makeMessage(_ record: AIMessageRecord) -> StoredAIMessage {
        StoredAIMessage(
            id: record.id,
            conversationID: record.conversationID,
            roleRawValue: record.roleRawValue,
            text: record.text,
            createdAt: record.createdAt,
            sequence: record.sequence,
            statusRawValue: record.statusRawValue,
            errorDescription: record.errorDescription
        )
    }

    private static func makeManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let conversation = NSEntityDescription()
        conversation.name = "AIConversationRecord"
        conversation.managedObjectClassName = NSStringFromClass(AIConversationRecord.self)

        let message = NSEntityDescription()
        message.name = "AIMessageRecord"
        message.managedObjectClassName = NSStringFromClass(AIMessageRecord.self)

        conversation.properties = [
            attribute("id", type: .UUIDAttributeType, optional: false),
            attribute("title", type: .stringAttributeType, optional: false, defaultValue: ""),
            attribute("authorRawValue", type: .stringAttributeType, optional: false, defaultValue: "neville"),
            attribute("createdAt", type: .dateAttributeType, optional: false),
            attribute("updatedAt", type: .dateAttributeType, optional: false),
            attribute("summary", type: .stringAttributeType),
            attribute("transcriptData", type: .binaryDataAttributeType),
            attribute("promptVersion", type: .integer32AttributeType, optional: false, defaultValue: 1),
            attribute("usesPersonalVoice", type: .booleanAttributeType, optional: false, defaultValue: true),
            attribute("languageRawValue", type: .stringAttributeType, optional: false, defaultValue: "es")
        ]

        message.properties = [
            attribute("id", type: .UUIDAttributeType, optional: false),
            attribute("conversationID", type: .UUIDAttributeType, optional: false),
            attribute("roleRawValue", type: .stringAttributeType, optional: false, defaultValue: "user"),
            attribute("text", type: .stringAttributeType, optional: false, defaultValue: ""),
            attribute("createdAt", type: .dateAttributeType, optional: false),
            attribute("sequence", type: .integer64AttributeType, optional: false, defaultValue: 0),
            attribute("statusRawValue", type: .stringAttributeType, optional: false, defaultValue: "completed"),
            attribute("errorDescription", type: .stringAttributeType)
        ]

        let messagesRelationship = NSRelationshipDescription()
        messagesRelationship.name = "messages"
        messagesRelationship.destinationEntity = message
        messagesRelationship.minCount = 0
        messagesRelationship.maxCount = 0
        messagesRelationship.isOptional = true
        messagesRelationship.isOrdered = false
        messagesRelationship.deleteRule = .cascadeDeleteRule

        let conversationRelationship = NSRelationshipDescription()
        conversationRelationship.name = "conversation"
        conversationRelationship.destinationEntity = conversation
        conversationRelationship.minCount = 1
        conversationRelationship.maxCount = 1
        conversationRelationship.isOptional = false
        conversationRelationship.deleteRule = .nullifyDeleteRule

        messagesRelationship.inverseRelationship = conversationRelationship
        conversationRelationship.inverseRelationship = messagesRelationship
        conversation.properties.append(messagesRelationship)
        message.properties.append(conversationRelationship)
        conversation.uniquenessConstraints = [["id"]]
        message.uniquenessConstraints = [["id"]]

        model.entities = [conversation, message]
        return model
    }

    private static func attribute(
        _ name: String,
        type: NSAttributeType,
        optional: Bool = true,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }

    private static func conversationEntity(in model: NSManagedObjectModel) -> NSEntityDescription {
        model.entitiesByName["AIConversationRecord"]!
    }

    private static func messageEntity(in model: NSManagedObjectModel) -> NSEntityDescription {
        model.entitiesByName["AIMessageRecord"]!
    }
}

private enum AIChatPersistenceError: LocalizedError {
    case conversationNotFound
    case messageNotFound

    var errorDescription: String? {
        switch self {
        case .conversationNotFound:
            return "No se encontró la conversación."
        case .messageNotFound:
            return "No se encontró el mensaje."
        }
    }
}

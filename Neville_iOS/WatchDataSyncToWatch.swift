import Foundation
import CoreData
import WatchConnectivity
import Combine

@MainActor
final class WatchDataSyncToWatch: NSObject {
    static let shared = WatchDataSyncToWatch()

    private enum Keys {
        static let notesBatch = "ios_notes_batch_v1"
        static let noteDelete = "ios_note_delete_v1"
        static let diarioBatch = "ios_diario_batch_v1"
        static let diarioDelete = "ios_diario_delete_v1"
        static let agendaBatch = "ios_agenda_batch_v1"
        static let agendaDelete = "ios_agenda_delete_v1"
        static let presenceBatch = "ios_presence_batch_v1"
        static let presenceReset = "ios_presence_reset_v1"
        static let premiumState = "ios_premium_state_v1"
    }

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private let defaults = UserDefaults.standard
    private var observers = Set<AnyCancellable>()
    private var pendingSyncTask: Task<Void, Never>?

    private let notesCursorKey = "watchSync.notes.lastModified"
    private let diarioCursorKey = "watchSync.diario.lastModified"
    private let agendaCursorKey = "watchSync.agenda.lastModified"
    private let presenceCursorKey = "watchSync.presence.createdAt"

    private override init() {
        super.init()
        setupObservers()
    }

    func start() {
        scheduleSync(fullSyncIfNoCursor: true)
    }

    private func setupObservers() {
        let center = NotificationCenter.default

        center.publisher(for: .coreDataStoresDidLoad)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleSync(fullSyncIfNoCursor: true)
            }
            .store(in: &observers)

        center.publisher(
            for: .NSPersistentStoreRemoteChange,
            object: CoreDataController.shared.persistentContainer.persistentStoreCoordinator
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.scheduleSync(fullSyncIfNoCursor: false)
        }
        .store(in: &observers)

        center.publisher(for: .NSManagedObjectContextDidSave,
                         object: CoreDataController.shared.context)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.scheduleSync(fullSyncIfNoCursor: false)
            }
            .store(in: &observers)

        center.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.sendPremiumState()
            }
            .store(in: &observers)

        center.publisher(for: .noteDeletedForWatchSync)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let noteID = notification.userInfo?["id"] as? String else { return }
                self?.sendDeletedNote(id: noteID)
            }
            .store(in: &observers)

        center.publisher(for: .diarioDeletedForWatchSync)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let diarioID = notification.userInfo?["id"] as? String else { return }
                self?.sendDeletedDiario(id: diarioID)
            }
            .store(in: &observers)

        center.publisher(for: .agendaDeletedForWatchSync)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                guard let agendaID = notification.userInfo?["id"] as? String else { return }
                self?.sendDeletedAgenda(id: agendaID)
            }
            .store(in: &observers)
    }

    private func scheduleSync(fullSyncIfNoCursor: Bool) {
        pendingSyncTask?.cancel()
        pendingSyncTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await self?.syncNow(fullSyncIfNoCursor: fullSyncIfNoCursor)
        }
    }

    private func syncNow(fullSyncIfNoCursor: Bool) async {
        guard let session else { return }
        sendPremiumState()
        guard CoreDataController.shared.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty == false else { return }

        let context = CoreDataController.shared.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        let noteCursor = defaults.object(forKey: notesCursorKey) as? Date
        let diarioCursor = defaults.object(forKey: diarioCursorKey) as? Date
        let agendaCursor = defaults.object(forKey: agendaCursorKey) as? Date
        let presenceCursor = defaults.object(forKey: presenceCursorKey) as? Date

        let shouldSendAllNotes = fullSyncIfNoCursor && noteCursor == nil
        let shouldSendAllDiario = fullSyncIfNoCursor && diarioCursor == nil
        let shouldSendAllAgenda = fullSyncIfNoCursor && agendaCursor == nil
        let shouldSendAllPresence = fullSyncIfNoCursor && presenceCursor == nil

        let notePayloads = await fetchNotes(in: context, modifiedAfter: shouldSendAllNotes ? nil : noteCursor)
        let diarioPayloads = await fetchDiario(in: context, modifiedAfter: shouldSendAllDiario ? nil : diarioCursor)
        let agendaPayloads = await fetchAgenda(in: context, modifiedAfter: shouldSendAllAgenda ? nil : agendaCursor)
        let presencePayloads = await fetchPresence(in: context, createdAfter: shouldSendAllPresence ? nil : presenceCursor)

        if notePayloads.isEmpty && diarioPayloads.isEmpty && agendaPayloads.isEmpty && presencePayloads.isEmpty { return }

        if !notePayloads.isEmpty {
            for payload in notePayloads {
                session.transferUserInfo([Keys.notesBatch: payload.toDictionary()])
            }
            defaults.set(notePayloads.map(\.fechaModificacion).max(), forKey: notesCursorKey)
        }

        if !diarioPayloads.isEmpty {
            for payload in diarioPayloads {
                session.transferUserInfo([Keys.diarioBatch: payload.toDictionary()])
            }
            defaults.set(diarioPayloads.map(\.fechaM).max(), forKey: diarioCursorKey)
        }

        if !agendaPayloads.isEmpty {
            for payload in agendaPayloads {
                session.transferUserInfo([Keys.agendaBatch: payload.toDictionary()])
            }
            defaults.set(agendaPayloads.map(\.fechaModificacion).max(), forKey: agendaCursorKey)
        }

        if !presencePayloads.isEmpty {
            for payload in presencePayloads {
                session.transferUserInfo([Keys.presenceBatch: payload.toDictionary()])
            }
            defaults.set(presencePayloads.map(\.createdAt).max(), forKey: presenceCursorKey)
        }
    }

    private func sendPremiumState() {
        guard let session else { return }

        let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        let yorjPremium = defaults.bool(forKey: "yorjPremium") || (sharedDefaults?.bool(forKey: "yorjPremium") ?? false)
        let purchaseStatus = defaults.bool(forKey: "purchaseStatus") || (sharedDefaults?.bool(forKey: "purchaseStatus") ?? false) || yorjPremium
        let payload: [String: Any] = [
            "yorjPremium": yorjPremium,
            "purchaseStatus": purchaseStatus
        ]
        let message = [Keys.premiumState: payload]

        try? session.updateApplicationContext(message)
        session.transferUserInfo(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func sendDeletedNote(id: String) {
        guard let session else { return }

        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }

        let message = [Keys.noteDelete: ["id": trimmedID]]
        session.transferUserInfo(message)

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func sendDeletedDiario(id: String) {
        sendDeletedEntity(id: id, key: Keys.diarioDelete)
    }

    private func sendDeletedAgenda(id: String) {
        sendDeletedEntity(id: id, key: Keys.agendaDelete)
    }

    func sendPresenceReset() {
        guard let session else { return }

        defaults.removeObject(forKey: presenceCursorKey)
        let message = [Keys.presenceReset: ["resetAt": Date().timeIntervalSince1970]]
        try? session.updateApplicationContext(message)
        session.transferUserInfo(message)

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func sendDeletedEntity(id: String, key: String) {
        guard let session else { return }

        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }

        let message = [key: ["id": trimmedID]]
        session.transferUserInfo(message)

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }

    private func fetchNotes(in context: NSManagedObjectContext, modifiedAfter date: Date?) async -> [WatchNoteTransferPayload] {
        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "fechaModificacion", ascending: true)]

            if let date {
                request.predicate = NSPredicate(format: "fechaModificacion > %@", date as NSDate)
            }

            do {
                return try context.fetch(request).compactMap { note in
                    let id = (note.id ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !id.isEmpty else { return nil }

                    let title = note.title ?? ""
                    let nota = note.nota ?? ""
                    let categoria = (note.value(forKey: "categoria") as? String) ?? ""
                    let direccionMapa = (note.value(forKey: "direccionMapa") as? String) ?? ""
                    let fechaCreacion = (note.value(forKey: "fechaCreacion") as? Date) ?? Date()
                    let fechaModificacion = (note.value(forKey: "fechaModificacion") as? Date) ?? Date()

                    return WatchNoteTransferPayload(
                        id: id,
                        title: title,
                        nota: nota,
                        categoria: categoria,
                        direccionMapa: direccionMapa,
                        isfav: note.isfav,
                        fechaCreacion: fechaCreacion,
                        fechaModificacion: fechaModificacion
                    )
                }
            } catch {
                msg("❌ Error preparando notas para watchOS: \(error.localizedDescription)")
                return []
            }
        }
    }

    private func fetchDiario(in context: NSManagedObjectContext, modifiedAfter date: Date?) async -> [WatchDiarioTransferPayload] {
        await context.perform {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "fechaM", ascending: true)]

            if let date {
                request.predicate = NSPredicate(format: "fechaM > %@", date as NSDate)
            }

            do {
                return try context.fetch(request).compactMap { diario in
                    let id = diario.id?.uuidString ?? ""
                    guard !id.isEmpty else { return nil }

                    let title = diario.title ?? ""
                    let content = diario.content ?? ""
                    let emotion = diario.emotion ?? "neutral"
                    let direccionMapa = (diario.value(forKey: "direccionMapa") as? String) ?? ""
                    let fecha = diario.fecha ?? Date()
                    let fechaM = diario.fechaM ?? Date()

                    return WatchDiarioTransferPayload(
                        id: id,
                        title: title,
                        content: content,
                        emotion: emotion,
                        isFav: diario.isFav,
                        direccionMapa: direccionMapa,
                        fecha: fecha,
                        fechaM: fechaM
                    )
                }
            } catch {
                msg("❌ Error preparando diario para watchOS: \(error.localizedDescription)")
                return []
            }
        }
    }

    private func fetchAgenda(in context: NSManagedObjectContext, modifiedAfter date: Date?) async -> [WatchAgendaTransferPayload] {
        await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "fechaModificacion", ascending: true)]

            if let date {
                request.predicate = NSPredicate(format: "fechaModificacion > %@", date as NSDate)
            }

            do {
                return try context.fetch(request).compactMap { row in
                    guard let id = (row.value(forKey: "id") as? UUID)?.uuidString else { return nil }

                    let titulo = (row.value(forKey: "titulo") as? String) ?? ""
                    let fechaCreacion = (row.value(forKey: "fechaCreacion") as? Date) ?? Date()
                    let fechaModificacion = (row.value(forKey: "fechaModificacion") as? Date) ?? Date()
                    let nota = (row.value(forKey: "nota") as? String) ?? ""
                    let fechaActividad = (row.value(forKey: "fechaActividad") as? Date) ?? Date()
                    let hora = (row.value(forKey: "hora") as? Date) ?? Date()
                    let lugar = (row.value(forKey: "lugar") as? String) ?? ""
                    let contenido = (row.value(forKey: "contenido") as? String) ?? ""
                    let prioridad = (row.value(forKey: "prioridad") as? String) ?? AgendaPriority.neutral.rawValue
                    let colorHex = (row.value(forKey: "colorHex") as? String) ?? "#A9D7A4"
                    let completada = row.value(forKey: "completada") as? Bool
                    let recordatorioActivo = (row.value(forKey: "recordatorioActivo") as? Bool) ?? false
                    let reminderID = row.value(forKey: "reminderID") as? String
                    let seriesID = (row.value(forKey: "seriesID") as? UUID)?.uuidString

                    return WatchAgendaTransferPayload(
                        id: id,
                        titulo: titulo,
                        fechaCreacion: fechaCreacion,
                        fechaModificacion: fechaModificacion,
                        nota: nota,
                        fechaActividad: fechaActividad,
                        hora: hora,
                        lugar: lugar,
                        contenido: contenido,
                        prioridad: prioridad,
                        colorHex: colorHex,
                        completada: completada,
                        recordatorioActivo: recordatorioActivo,
                        reminderID: reminderID,
                        seriesID: seriesID
                    )
                }
            } catch {
                msg("❌ Error preparando agenda para watchOS: \(error.localizedDescription)")
                return []
            }
        }
    }

    private func fetchPresence(in context: NSManagedObjectContext, createdAfter date: Date?) async -> [WatchPresenceTransferPayload] {
        await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]

            if let date {
                request.predicate = NSPredicate(format: "createdAt > %@", date as NSDate)
            }

            do {
                return try context.fetch(request).compactMap { row in
                    guard
                        let id = (row.value(forKey: "id") as? UUID)?.uuidString,
                        let createdAt = row.value(forKey: "createdAt") as? Date,
                        let dayStart = row.value(forKey: "dayStart") as? Date,
                        let eventType = row.value(forKey: "eventType") as? String
                    else {
                        return nil
                    }

                    return WatchPresenceTransferPayload(
                        id: id,
                        createdAt: createdAt,
                        dayStart: dayStart,
                        eventType: eventType,
                        mood: row.value(forKey: "mood") as? String,
                        note: row.value(forKey: "note") as? String ?? "",
                        source: row.value(forKey: "source") as? String ?? "iOS"
                    )
                }
            } catch {
                msg("❌ Error preparando presencia para watchOS: \(error.localizedDescription)")
                return []
            }
        }
    }

}

private extension WatchNoteTransferPayload {
    func toDictionary() -> [String: Any] {
        [
            "id": id,
            "title": title,
            "nota": nota,
            "direccionMapa": direccionMapa,
            "isfav": isfav,
            "fechaCreacion": fechaCreacion.timeIntervalSince1970,
            "fechaModificacion": fechaModificacion.timeIntervalSince1970
        ]
    }
}

private extension WatchDiarioTransferPayload {
    func toDictionary() -> [String: Any] {
        [
            "id": id,
            "title": title,
            "content": content,
            "emotion": emotion,
            "isFav": isFav,
            "direccionMapa": direccionMapa,
            "fecha": fecha.timeIntervalSince1970,
            "fechaM": fechaM.timeIntervalSince1970
        ]
    }
}

private extension WatchAgendaTransferPayload {
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "id": id,
            "titulo": titulo,
            "fechaCreacion": fechaCreacion.timeIntervalSince1970,
            "fechaModificacion": fechaModificacion.timeIntervalSince1970,
            "nota": nota,
            "fechaActividad": fechaActividad.timeIntervalSince1970,
            "hora": hora.timeIntervalSince1970,
            "lugar": lugar,
            "contenido": contenido,
            "prioridad": prioridad,
            "colorHex": colorHex,
            "recordatorioActivo": recordatorioActivo
        ]

        if let completada {
            dictionary["completada"] = completada
        }
        if let reminderID {
            dictionary["reminderID"] = reminderID
        }
        if let seriesID {
            dictionary["seriesID"] = seriesID
        }

        return dictionary
    }
}

private extension WatchPresenceTransferPayload {
    func toDictionary() -> [String: Any] {
        var dictionary: [String: Any] = [
            "id": id,
            "createdAt": createdAt.timeIntervalSince1970,
            "dayStart": dayStart.timeIntervalSince1970,
            "eventType": eventType,
            "note": note,
            "source": source
        ]

        if let mood {
            dictionary["mood"] = mood
        }

        return dictionary
    }
}

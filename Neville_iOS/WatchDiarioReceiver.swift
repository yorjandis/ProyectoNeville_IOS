import Foundation
import CoreData
#if canImport(WatchConnectivity)
import WatchConnectivity

struct WatchNoteTransferPayload {
    static let userInfoKey = "watch_note_payload_v1"

    let id: String
    let title: String
    let nota: String
    let categoria: String
    let direccionMapa: String
    let isfav: Bool
    let fechaCreacion: Date
    let fechaModificacion: Date

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchNoteTransferPayload? {
        guard
            let id = dictionary["id"] as? String,
            let title = dictionary["title"] as? String,
            let nota = dictionary["nota"] as? String,
            let direccionMapa = dictionary["direccionMapa"] as? String,
            let isfav = dictionary["isfav"] as? Bool,
            let fechaCreacionInterval = dictionary["fechaCreacion"] as? TimeInterval,
            let fechaModificacionInterval = dictionary["fechaModificacion"] as? TimeInterval
        else {
            return nil
        }

        return WatchNoteTransferPayload(
            id: id,
            title: title,
            nota: nota,
            categoria: dictionary["categoria"] as? String ?? "",
            direccionMapa: direccionMapa,
            isfav: isfav,
            fechaCreacion: Date(timeIntervalSince1970: fechaCreacionInterval),
            fechaModificacion: Date(timeIntervalSince1970: fechaModificacionInterval)
        )
    }
}

struct WatchDiarioTransferPayload {
    static let userInfoKey = "watch_diario_payload_v1"

    let id: String
    let title: String
    let content: String
    let emotion: String
    let isFav: Bool
    let direccionMapa: String
    let capitulo: String
    let fecha: Date
    let fechaM: Date

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchDiarioTransferPayload? {
        guard
            let id = dictionary["id"] as? String,
            let title = dictionary["title"] as? String,
            let content = dictionary["content"] as? String,
            let emotion = dictionary["emotion"] as? String,
            let isFav = dictionary["isFav"] as? Bool,
            let direccionMapa = dictionary["direccionMapa"] as? String,
            let fechaInterval = dictionary["fecha"] as? TimeInterval,
            let fechaMInterval = dictionary["fechaM"] as? TimeInterval
        else {
            return nil
        }

        return WatchDiarioTransferPayload(
            id: id,
            title: title,
            content: content,
            emotion: emotion,
            isFav: isFav,
            direccionMapa: direccionMapa,
            capitulo: dictionary["capitulo"] as? String ?? "",
            fecha: Date(timeIntervalSince1970: fechaInterval),
            fechaM: Date(timeIntervalSince1970: fechaMInterval)
        )
    }
}

struct WatchDiarioDeleteTransferPayload {
    static let userInfoKey = "watch_diario_delete_payload_v1"

    let id: String

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchDiarioDeleteTransferPayload? {
        guard let id = dictionary["id"] as? String else { return nil }
        return WatchDiarioDeleteTransferPayload(id: id)
    }
}

struct WatchAgendaTransferPayload {
    static let userInfoKey = "watch_agenda_payload_v1"

    let id: String
    let titulo: String
    let fechaCreacion: Date
    let fechaModificacion: Date
    let nota: String
    let fechaActividad: Date
    let hora: Date
    let lugar: String
    let contenido: String
    let prioridad: String
    let colorHex: String
    let completada: Bool?
    let recordatorioActivo: Bool
    let reminderID: String?
    let seriesID: String?

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchAgendaTransferPayload? {
        guard
            let id = dictionary["id"] as? String,
            let titulo = dictionary["titulo"] as? String,
            let fechaCreacionInterval = dictionary["fechaCreacion"] as? TimeInterval,
            let fechaModificacionInterval = dictionary["fechaModificacion"] as? TimeInterval,
            let nota = dictionary["nota"] as? String,
            let fechaActividadInterval = dictionary["fechaActividad"] as? TimeInterval,
            let horaInterval = dictionary["hora"] as? TimeInterval,
            let lugar = dictionary["lugar"] as? String,
            let contenido = dictionary["contenido"] as? String,
            let prioridad = dictionary["prioridad"] as? String,
            let colorHex = dictionary["colorHex"] as? String,
            let recordatorioActivo = dictionary["recordatorioActivo"] as? Bool
        else {
            return nil
        }

        return WatchAgendaTransferPayload(
            id: id,
            titulo: titulo,
            fechaCreacion: Date(timeIntervalSince1970: fechaCreacionInterval),
            fechaModificacion: Date(timeIntervalSince1970: fechaModificacionInterval),
            nota: nota,
            fechaActividad: Date(timeIntervalSince1970: fechaActividadInterval),
            hora: Date(timeIntervalSince1970: horaInterval),
            lugar: lugar,
            contenido: contenido,
            prioridad: prioridad,
            colorHex: colorHex,
            completada: dictionary["completada"] as? Bool,
            recordatorioActivo: recordatorioActivo,
            reminderID: dictionary["reminderID"] as? String,
            seriesID: dictionary["seriesID"] as? String
        )
    }
}

struct WatchAgendaDeleteTransferPayload {
    static let userInfoKey = "watch_agenda_delete_payload_v1"

    let id: String

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchAgendaDeleteTransferPayload? {
        guard let id = dictionary["id"] as? String else { return nil }
        return WatchAgendaDeleteTransferPayload(id: id)
    }
}

struct WatchPresenceTransferPayload {
    static let userInfoKey = "watch_presence_payload_v1"

    let id: String
    let createdAt: Date
    let dayStart: Date
    let eventType: String
    let mood: String?
    let note: String
    let source: String

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchPresenceTransferPayload? {
        guard
            let id = dictionary["id"] as? String,
            let createdAtInterval = dictionary["createdAt"] as? TimeInterval,
            let dayStartInterval = dictionary["dayStart"] as? TimeInterval,
            let eventType = dictionary["eventType"] as? String,
            let source = dictionary["source"] as? String
        else {
            return nil
        }

        return WatchPresenceTransferPayload(
            id: id,
            createdAt: Date(timeIntervalSince1970: createdAtInterval),
            dayStart: Date(timeIntervalSince1970: dayStartInterval),
            eventType: eventType,
            mood: dictionary["mood"] as? String,
            note: dictionary["note"] as? String ?? "",
            source: source
        )
    }
}

struct WatchNoteDeleteTransferPayload {
    static let userInfoKey = "watch_note_delete_payload_v1"

    let id: String

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchNoteDeleteTransferPayload? {
        guard let id = dictionary["id"] as? String else { return nil }
        return WatchNoteDeleteTransferPayload(id: id)
    }
}

@MainActor
final class WatchDiarioReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchDiarioReceiver()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var importingNoteIDs = Set<String>()
    private var importingPresenceIDs = Set<String>()

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {}

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncoming(userInfo)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncoming(message)
    }

    private nonisolated func handleIncoming(_ payload: [String: Any]) {
        if let raw = payload[WatchNoteDeleteTransferPayload.userInfoKey] as? [String: Any],
           let deletePayload = WatchNoteDeleteTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.deleteNote(id: deletePayload.id)
            }
            return
        }

        if let raw = payload[WatchNoteTransferPayload.userInfoKey] as? [String: Any],
           let notePayload = WatchNoteTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.upsertNoteIfNeeded(payload: notePayload)
            }
            return
        }

        if let raw = payload[WatchDiarioTransferPayload.userInfoKey] as? [String: Any],
           let diarioPayload = WatchDiarioTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.upsert(payload: diarioPayload)
            }
            return
        }

        if let raw = payload[WatchDiarioDeleteTransferPayload.userInfoKey] as? [String: Any],
           let deletePayload = WatchDiarioDeleteTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.deleteDiario(id: deletePayload.id)
            }
            return
        }

        if let raw = payload[WatchAgendaTransferPayload.userInfoKey] as? [String: Any],
           let agendaPayload = WatchAgendaTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.upsertAgenda(payload: agendaPayload)
            }
            return
        }

        if let raw = payload[WatchAgendaDeleteTransferPayload.userInfoKey] as? [String: Any],
           let deletePayload = WatchAgendaDeleteTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.deleteAgenda(id: deletePayload.id)
            }
            return
        }

        if let raw = payload[WatchPresenceTransferPayload.userInfoKey] as? [String: Any],
           let presencePayload = WatchPresenceTransferPayload.fromDictionary(raw) {
            Task { @MainActor in
                await self.upsertPresenceIfNeeded(payload: presencePayload)
            }
        }
    }

    private func upsertNoteIfNeeded(payload: WatchNoteTransferPayload) async {
        let noteID = payload.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noteID.isEmpty else { return }
        guard importingNoteIDs.insert(noteID).inserted else { return }

        defer { importingNoteIDs.remove(noteID) }
        await upsertNote(payload: payload)
    }

    private func upsertPresenceIfNeeded(payload: WatchPresenceTransferPayload) async {
        let presenceID = payload.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !presenceID.isEmpty else { return }
        guard importingPresenceIDs.insert(presenceID).inserted else { return }

        defer { importingPresenceIDs.remove(presenceID) }
        await upsertPresence(payload: payload)
    }

    private func deleteNote(id: String) async {
        let noteID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noteID.isEmpty else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de eliminar nota de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", noteID)

            do {
                let notes = try context.fetch(request)
                guard !notes.isEmpty else { return }

                notes.forEach(context.delete)
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar nota recibida desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func upsertNote(payload: WatchNoteTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de importar nota de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", payload.id)

            let note: Notas
            let matches = (try? context.fetch(request)) ?? []
            if let existing = matches.first {
                let currentModified = (existing.value(forKey: "fechaModificacion") as? Date) ?? .distantPast
                guard payload.fechaModificacion >= currentModified else { return }
                note = existing
                matches.dropFirst().forEach(context.delete)
            } else {
                note = Notas(context: context)
                note.id = payload.id
            }

            note.title = payload.title
            note.nota = payload.nota
            note.isfav = payload.isfav
            note.setValue(payload.categoria, forKey: "categoria")
            note.setValue(payload.direccionMapa, forKey: "direccionMapa")
            note.setValue(payload.fechaCreacion, forKey: "fechaCreacion")
            note.setValue(payload.fechaModificacion, forKey: "fechaModificacion")

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo importar nota recibida desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func upsert(payload: WatchDiarioTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de importar diario de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.fetchLimit = 1
            if let uuid = UUID(uuidString: payload.id) {
                request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
            } else {
                request.predicate = NSPredicate(format: "title == %@ AND fecha == %@", payload.title, payload.fecha as NSDate)
            }

            let diario: Diario
            if let existing = try? context.fetch(request).first {
                let currentModified = existing.fechaM ?? .distantPast
                guard payload.fechaM >= currentModified else { return }
                diario = existing
            } else {
                diario = Diario(context: context)
                diario.id = UUID(uuidString: payload.id) ?? UUID()
            }

            diario.title = payload.title
            diario.content = payload.content
            diario.emotion = payload.emotion
            diario.isFav = payload.isFav
            diario.setValue(payload.direccionMapa, forKey: "direccionMapa")
            diario.setValue(payload.capitulo.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "capitulo")
            diario.fecha = payload.fecha
            diario.fechaM = payload.fechaM

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo importar diario recibido desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func deleteDiario(id: String) async {
        let diarioID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: diarioID) else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de eliminar diario de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Diario> = Diario.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

            do {
                let entries = try context.fetch(request)
                guard !entries.isEmpty else { return }

                entries.forEach(context.delete)
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar diario recibido desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func upsertAgenda(payload: WatchAgendaTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de importar agenda de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            guard
                let agendaID = UUID(uuidString: payload.id),
                let entity = NSEntityDescription.entity(forEntityName: "AgendaItemEntity", in: context)
            else {
                return
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", agendaID as CVarArg)

            let row: NSManagedObject
            if let existing = try? context.fetch(request).first {
                let currentModified = (existing.value(forKey: "fechaModificacion") as? Date) ?? .distantPast
                guard payload.fechaModificacion >= currentModified else { return }
                row = existing
            } else {
                row = NSManagedObject(entity: entity, insertInto: context)
                row.setValue(agendaID, forKey: "id")
            }

            row.setValue(payload.titulo, forKey: "titulo")
            row.setValue(payload.fechaCreacion, forKey: "fechaCreacion")
            row.setValue(payload.fechaModificacion, forKey: "fechaModificacion")
            row.setValue(payload.nota, forKey: "nota")
            row.setValue(payload.fechaActividad, forKey: "fechaActividad")
            row.setValue(payload.hora, forKey: "hora")
            row.setValue(payload.lugar, forKey: "lugar")
            row.setValue(payload.contenido, forKey: "contenido")
            row.setValue(payload.prioridad, forKey: "prioridad")
            row.setValue(payload.colorHex, forKey: "colorHex")
            row.setValue(payload.completada, forKey: "completada")
            row.setValue(payload.recordatorioActivo, forKey: "recordatorioActivo")
            row.setValue(payload.reminderID, forKey: "reminderID")
            row.setValue(payload.seriesID.flatMap(UUID.init(uuidString:)), forKey: "seriesID")

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo importar agenda recibida desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func upsertPresence(payload: WatchPresenceTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de importar presencia de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            guard
                let presenceID = UUID(uuidString: payload.id),
                let entity = NSEntityDescription.entity(forEntityName: "PresenciaEventEntity", in: context)
            else {
                return
            }

            let request = NSFetchRequest<NSManagedObject>(entityName: "PresenciaEventEntity")
            request.predicate = NSPredicate(format: "id == %@", presenceID as CVarArg)

            let row: NSManagedObject
            let matches = (try? context.fetch(request)) ?? []
            if let existing = matches.first {
                row = existing
                matches.dropFirst().forEach(context.delete)
            } else {
                row = NSManagedObject(entity: entity, insertInto: context)
                row.setValue(presenceID, forKey: "id")
            }

            row.setValue(payload.createdAt, forKey: "createdAt")
            row.setValue(payload.dayStart, forKey: "dayStart")
            row.setValue(payload.eventType, forKey: "eventType")
            row.setValue(payload.mood, forKey: "mood")
            row.setValue(payload.note, forKey: "note")
            row.setValue(payload.source, forKey: "source")

            do {
                try context.save()
                Task { @MainActor in
                    NotificationCenter.default.post(name: .presenciaEventsDidChange, object: nil)
                }
            } catch {
                context.rollback()
                msg("❌ No se pudo importar presencia recibida desde watch: \(error.localizedDescription)")
            }
        }
    }

    private func deleteAgenda(id: String) async {
        let agendaID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let uuid = UUID(uuidString: agendaID) else { return }

        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data antes de eliminar agenda de watch: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
            request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)

            do {
                let rows = try context.fetch(request)
                guard !rows.isEmpty else { return }

                rows.forEach(context.delete)
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo eliminar agenda recibida desde watch: \(error.localizedDescription)")
            }
        }
    }
}
#else
@MainActor
final class WatchDiarioReceiver {
    static let shared = WatchDiarioReceiver()
}
#endif

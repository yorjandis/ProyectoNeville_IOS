import Foundation
import CoreData
import WatchConnectivity

@MainActor
final class WatchIncomingDataReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchIncomingDataReceiver()

    private enum Keys {
        static let notesBatch = "ios_notes_batch_v1"
        static let diarioBatch = "ios_diario_batch_v1"
        static let agendaBatch = "ios_agenda_batch_v1"
        static let premiumState = "ios_premium_state_v1"
    }

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleIncomingPayload(userInfo)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncomingPayload(message)
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncomingPayload(applicationContext)
    }

    private nonisolated func handleIncomingPayload(_ payload: [String: Any]) {
        if let rawPremiumState = payload[Keys.premiumState] as? [String: Any] {
            let yorjPremium = rawPremiumState["yorjPremium"] as? Bool ?? false
            let purchaseStatus = rawPremiumState["purchaseStatus"] as? Bool ?? false
            Task { @MainActor in
                self.applyPremiumState(yorjPremium: yorjPremium, purchaseStatus: purchaseStatus)
            }
            return
        }

        if let rawNote = payload[Keys.notesBatch] as? [String: Any],
           let notePayload = WatchNoteTransferPayload.fromDictionary(rawNote) {
            Task { @MainActor in
                await self.upsertNote(payload: notePayload)
            }
            return
        }

        if let rawDiario = payload[Keys.diarioBatch] as? [String: Any],
           let diarioPayload = WatchDiarioTransferPayload.fromDictionary(rawDiario) {
            Task { @MainActor in
                await self.upsertDiario(payload: diarioPayload)
            }
            return
        }

        if let rawAgenda = payload[Keys.agendaBatch] as? [String: Any],
           let agendaPayload = WatchAgendaTransferPayload.fromDictionary(rawAgenda) {
            Task { @MainActor in
                await self.upsertAgenda(payload: agendaPayload)
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
            msg("❌ No se pudo cargar Core Data para sincronizar notas en watchOS: \(error.localizedDescription)")
            return
        }

        let context = store.persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        await context.perform {
            let request: NSFetchRequest<Notas> = Notas.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "id == %@", payload.id)

            let note: Notas
            if let existing = try? context.fetch(request).first {
                let currentModified = (existing.value(forKey: "fechaModificacion") as? Date) ?? .distantPast
                guard payload.fechaModificacion >= currentModified else { return }
                note = existing
            } else {
                note = Notas(context: context)
                note.id = payload.id
            }

            note.title = payload.title
            note.nota = payload.nota
            note.isfav = payload.isfav
            note.setValue(payload.direccionMapa, forKey: "direccionMapa")
            note.setValue(payload.fechaCreacion, forKey: "fechaCreacion")
            note.setValue(payload.fechaModificacion, forKey: "fechaModificacion")

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar nota entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func upsertDiario(payload: WatchDiarioTransferPayload) async {
        let store = CoreDataController.shared

        do {
            if store.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                try await store.cargarStores()
            }
        } catch {
            msg("❌ No se pudo cargar Core Data para sincronizar diario en watchOS: \(error.localizedDescription)")
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
            diario.fecha = payload.fecha
            diario.fechaM = payload.fechaM

            do {
                try context.save()
            } catch {
                context.rollback()
                msg("❌ No se pudo aplicar diario entrante en watchOS: \(error.localizedDescription)")
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
            msg("❌ No se pudo cargar Core Data para sincronizar agenda en watchOS: \(error.localizedDescription)")
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
                msg("❌ No se pudo aplicar agenda entrante en watchOS: \(error.localizedDescription)")
            }
        }
    }

    private func applyPremiumState(yorjPremium: Bool, purchaseStatus: Bool) {
        let hasPremiumAccess = purchaseStatus || yorjPremium

        UserDefaults.standard.set(yorjPremium, forKey: "yorjPremium")
        UserDefaults.standard.set(hasPremiumAccess, forKey: "purchaseStatus")

        if let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName) {
            sharedDefaults.set(yorjPremium, forKey: "yorjPremium")
            sharedDefaults.set(hasPremiumAccess, forKey: "purchaseStatus")
        }

        let store = NSUbiquitousKeyValueStore.default
        store.set(yorjPremium, forKey: "yorjPremium")
        store.set(hasPremiumAccess, forKey: "purchaseStatus")
        store.synchronize()

        watchModel.shared.refreshPremiumAccessState()
    }
}

import Foundation
import CoreData
import WatchConnectivity

struct WatchNoteTransferPayload {
    static let userInfoKey = "watch_note_payload_v1"

    let id: String
    let title: String
    let nota: String
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
            direccionMapa: direccionMapa,
            isfav: isfav,
            fechaCreacion: Date(timeIntervalSince1970: fechaCreacionInterval),
            fechaModificacion: Date(timeIntervalSince1970: fechaModificacionInterval)
        )
    }
}

@MainActor
final class WatchNotesReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchNotesReceiver()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    private var importingNoteIDs = Set<String>()

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
        guard
            let raw = payload[WatchNoteTransferPayload.userInfoKey] as? [String: Any],
            let notePayload = WatchNoteTransferPayload.fromDictionary(raw)
        else {
            return
        }

        Task { @MainActor in
            await self.upsertIfNeeded(payload: notePayload)
        }
    }

    private func upsertIfNeeded(payload: WatchNoteTransferPayload) async {
        let noteID = payload.id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !noteID.isEmpty else { return }
        guard importingNoteIDs.insert(noteID).inserted else { return }

        defer { importingNoteIDs.remove(noteID) }
        await upsert(payload: payload)
    }

    private func upsert(payload: WatchNoteTransferPayload) async {
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
                note = existing
                matches.dropFirst().forEach(context.delete)
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
                msg("❌ No se pudo importar nota recibida desde watch: \(error.localizedDescription)")
            }
        }
    }
}

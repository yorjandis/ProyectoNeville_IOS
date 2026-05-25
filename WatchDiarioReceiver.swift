import Foundation
import CoreData
#if canImport(WatchConnectivity)
import WatchConnectivity

struct WatchDiarioTransferPayload {
    static let userInfoKey = "watch_diario_payload_v1"

    let id: String
    let title: String
    let content: String
    let emotion: String
    let isFav: Bool
    let direccionMapa: String
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
            fecha: Date(timeIntervalSince1970: fechaInterval),
            fechaM: Date(timeIntervalSince1970: fechaMInterval)
        )
    }
}

@MainActor
final class WatchDiarioReceiver: NSObject, WCSessionDelegate {
    static let shared = WatchDiarioReceiver()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

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
            let raw = payload[WatchDiarioTransferPayload.userInfoKey] as? [String: Any],
            let diarioPayload = WatchDiarioTransferPayload.fromDictionary(raw)
        else {
            return
        }

        Task { @MainActor in
            await self.upsert(payload: diarioPayload)
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
                msg("❌ No se pudo importar diario recibido desde watch: \(error.localizedDescription)")
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

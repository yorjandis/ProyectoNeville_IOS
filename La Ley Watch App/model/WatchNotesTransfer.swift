import Foundation
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
final class WatchNotesTransferSender: NSObject, WCSessionDelegate {
    static let shared = WatchNotesTransferSender()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func sendCreatedNote(_ payload: WatchNoteTransferPayload) {
        guard let session else { return }

        let userInfo = [WatchNoteTransferPayload.userInfoKey: payload.toDictionary()]

        // Background-safe path.
        session.transferUserInfo(userInfo)

        // Fast path when counterpart is reachable.
        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

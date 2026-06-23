import Foundation
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

    func toDictionary() -> [String: Any] {
        [
            "id": id,
            "title": title,
            "nota": nota,
            "categoria": categoria,
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
            categoria: dictionary["categoria"] as? String ?? "",
            direccionMapa: direccionMapa,
            isfav: isfav,
            fechaCreacion: Date(timeIntervalSince1970: fechaCreacionInterval),
            fechaModificacion: Date(timeIntervalSince1970: fechaModificacionInterval)
        )
    }
}

struct WatchNoteDeleteTransferPayload {
    static let userInfoKey = "watch_note_delete_payload_v1"

    let id: String

    func toDictionary() -> [String: Any] {
        ["id": id]
    }

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchNoteDeleteTransferPayload? {
        guard let id = dictionary["id"] as? String else { return nil }
        return WatchNoteDeleteTransferPayload(id: id)
    }
}

@MainActor
final class WatchNotesTransferSender: NSObject {
    static let shared = WatchNotesTransferSender()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.activate()
    }

    func sendCreatedNote(_ payload: WatchNoteTransferPayload) {
        guard let session else { return }

        let userInfo = [WatchNoteTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }

    func sendDeletedNote(id: String) {
        guard let session else { return }

        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }

        let payload = WatchNoteDeleteTransferPayload(id: trimmedID)
        let userInfo = [WatchNoteDeleteTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }

}

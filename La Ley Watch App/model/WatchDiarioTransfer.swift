import Foundation
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
final class WatchDiarioTransferSender: NSObject, WCSessionDelegate {
    static let shared = WatchDiarioTransferSender()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.delegate = self
        session?.activate()
    }

    func sendCreatedDiario(_ payload: WatchDiarioTransferPayload) {
        guard let session else { return }

        let userInfo = [WatchDiarioTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

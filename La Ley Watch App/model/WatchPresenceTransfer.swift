import Foundation
import WatchConnectivity

struct WatchPresenceTransferPayload {
    static let userInfoKey = "watch_presence_payload_v1"

    let id: String
    let createdAt: Date
    let dayStart: Date
    let eventType: String
    let mood: String?
    let note: String
    let source: String

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

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchPresenceTransferPayload? {
        guard
            let id = dictionary["id"] as? String,
            let createdAtInterval = dictionary["createdAt"] as? TimeInterval,
            let dayStartInterval = dictionary["dayStart"] as? TimeInterval,
            let eventType = dictionary["eventType"] as? String,
            let note = dictionary["note"] as? String,
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
            note: note,
            source: source
        )
    }
}

@MainActor
final class WatchPresenceTransferSender: NSObject {
    static let shared = WatchPresenceTransferSender()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.activate()
    }

    func sendCreatedPresence(_ payload: WatchPresenceTransferPayload) {
        guard let session else { return }

        let userInfo = [WatchPresenceTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }
}

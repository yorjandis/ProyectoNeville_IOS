import Foundation
import WatchConnectivity

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

    func toDictionary() -> [String: Any] {
        ["id": id]
    }

    static func fromDictionary(_ dictionary: [String: Any]) -> WatchAgendaDeleteTransferPayload? {
        guard let id = dictionary["id"] as? String else { return nil }
        return WatchAgendaDeleteTransferPayload(id: id)
    }
}

@MainActor
final class WatchAgendaTransferSender: NSObject {
    static let shared = WatchAgendaTransferSender()

    private let session: WCSession? = WCSession.isSupported() ? WCSession.default : nil

    private override init() {
        super.init()
        session?.activate()
    }

    func sendCreatedAgenda(_ payload: WatchAgendaTransferPayload) {
        guard let session else { return }

        let userInfo = [WatchAgendaTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }

    func sendDeletedAgenda(id: String) {
        guard let session else { return }

        let trimmedID = id.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty else { return }

        let payload = WatchAgendaDeleteTransferPayload(id: trimmedID)
        let userInfo = [WatchAgendaDeleteTransferPayload.userInfoKey: payload.toDictionary()]
        session.transferUserInfo(userInfo)

        if session.isReachable {
            session.sendMessage(userInfo, replyHandler: nil, errorHandler: nil)
        }
    }
}

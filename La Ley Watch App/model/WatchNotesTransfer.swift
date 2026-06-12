import Foundation

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
final class WatchNotesTransferSender {
    static let shared = WatchNotesTransferSender()

    private init() {}

    func sendCreatedNote(_ payload: WatchNoteTransferPayload) {
        // Las notas del watch se guardan en Core Data con CloudKit activado.
        // Enviarlas también por WatchConnectivity crea una segunda ruta hacia iOS.
        _ = payload
    }

}

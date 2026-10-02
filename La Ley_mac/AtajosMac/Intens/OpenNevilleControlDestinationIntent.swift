@preconcurrency import AppIntents
import Foundation

@available(iOS 18.0, macOS 26.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
enum NevilleControlDestination: String, AppEnum {
    case crearNota = "crear-nota"
    case crearNotaVoz = "crear-nota-voz"
    case crearDiario = "crear-diario"
    case crearAgenda = "crear-agenda"
    case crearRecordatorio = "crear-recordatorio"
    case presencia
    case ritualMatutino = "ritual-matutino"
    case cierre
    case diario
    case agenda
    case notas
    case metas
    case calma
    case coherencia
    case autores
    case chatIA = "chat-ia"
    case centroSanador = "centro-sanador"
    case conferencias
    case resumenSemanal = "resumen-semanal"
    case lectorEtiquetas = "lector-etiquetas"

    static let typeDisplayRepresentation = TypeDisplayRepresentation("Destino de La Ley")

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .crearNota: "Nueva nota",
        .crearNotaVoz: "Nueva nota de voz",
        .crearDiario: "Nueva entrada de diario",
        .crearAgenda: "Nueva entrada de agenda",
        .crearRecordatorio: "Nuevo recordatorio",
        .presencia: "Registrar presencia",
        .ritualMatutino: "Ritual matutino",
        .cierre: "Ritual de cierre",
        .diario: "Diario",
        .agenda: "Agenda",
        .notas: "Notas",
        .metas: "Metas",
        .calma: "Espacio Calma",
        .coherencia: "Coherencia cardiocerebral",
        .autores: "Autores",
        .chatIA: "Chat IA",
        .centroSanador: "Centro Sanador",
        .conferencias: "Conferencias",
        .resumenSemanal: "Resumen semanal",
        .lectorEtiquetas: "Lector de etiquetas"
    ]
}

@available(iOS 18.0, macOS 26.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *)
struct OpenNevilleControlDestinationIntent: OpenIntent {
    static let title: LocalizedStringResource = "Abrir en La Ley"

    @Parameter(title: "Destino")
    var target: NevilleControlDestination

    init() {}

    init(target: NevilleControlDestination) {
        self.target = target
    }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group")
        defaults?.set(target.rawValue, forKey: "controlCenter.pendingDestination")
        defaults?.synchronize()
        return .result()
    }
}

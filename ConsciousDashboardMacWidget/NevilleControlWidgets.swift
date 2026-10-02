@preconcurrency import AppIntents
import Foundation
import SwiftUI
import WidgetKit

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

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
protocol NevilleControlDescriptor {
    static var kind: String { get }
    static var title: LocalizedStringResource { get }
    static var controlDescription: LocalizedStringResource { get }
    static var systemImageName: String { get }
    static var destination: NevilleControlDestination { get }
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
struct NevilleLaunchControl<Descriptor: NevilleControlDescriptor>: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Descriptor.kind) {
            ControlWidgetButton(action: OpenNevilleControlDestinationIntent(target: Descriptor.destination)) {
                Label(Descriptor.title, systemImage: Descriptor.systemImageName)
            }
        }
        .displayName(Descriptor.title)
        .description(Descriptor.controlDescription)
    }
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum NewNoteControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.create-note"
    static let title: LocalizedStringResource = "Nueva nota"
    static let controlDescription: LocalizedStringResource = "Abre el editor para crear una nota."
    static let systemImageName = "square.and.pencil"
    static let destination = NevilleControlDestination.crearNota
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum NewVoiceNoteControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.create-voice-note"
    static let title: LocalizedStringResource = "Nueva nota de voz"
    static let controlDescription: LocalizedStringResource = "Abre la grabadora para crear una nota de voz."
    static let systemImageName = "waveform.and.mic"
    static let destination = NevilleControlDestination.crearNotaVoz
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum NewDiaryEntryControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.create-diary-entry"
    static let title: LocalizedStringResource = "Nueva entrada de diario"
    static let controlDescription: LocalizedStringResource = "Abre el editor para escribir en el diario."
    static let systemImageName = "book.pages"
    static let destination = NevilleControlDestination.crearDiario
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum NewAgendaEntryControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.create-agenda-entry"
    static let title: LocalizedStringResource = "Nueva entrada de agenda"
    static let controlDescription: LocalizedStringResource = "Abre el editor para añadir una actividad a la agenda."
    static let systemImageName = "calendar.badge.plus"
    static let destination = NevilleControlDestination.crearAgenda
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum NewReminderControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.create-reminder"
    static let title: LocalizedStringResource = "Nuevo recordatorio"
    static let controlDescription: LocalizedStringResource = "Abre el editor para programar un recordatorio."
    static let systemImageName = "bell.badge"
    static let destination = NevilleControlDestination.crearRecordatorio
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum PresenceControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.presence"
    static let title: LocalizedStringResource = "Registrar presencia"
    static let controlDescription: LocalizedStringResource = "Abre la práctica de presencia consciente."
    static let systemImageName = "camera.macro"
    static let destination = NevilleControlDestination.presencia
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum MorningRitualControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.morning-ritual"
    static let title: LocalizedStringResource = "Ritual matutino"
    static let controlDescription: LocalizedStringResource = "Inicia el ritual matutino."
    static let systemImageName = "sunrise"
    static let destination = NevilleControlDestination.ritualMatutino
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum ClosingRitualControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.closing-ritual"
    static let title: LocalizedStringResource = "Ritual de cierre"
    static let controlDescription: LocalizedStringResource = "Inicia el ritual de cierre del día."
    static let systemImageName = "moon.stars"
    static let destination = NevilleControlDestination.cierre
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenDiaryControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-diary"
    static let title: LocalizedStringResource = "Diario"
    static let controlDescription: LocalizedStringResource = "Abre el diario."
    static let systemImageName = "book.closed"
    static let destination = NevilleControlDestination.diario
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenAgendaControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-agenda"
    static let title: LocalizedStringResource = "Agenda"
    static let controlDescription: LocalizedStringResource = "Abre la agenda."
    static let systemImageName = "calendar"
    static let destination = NevilleControlDestination.agenda
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenNotesControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-notes"
    static let title: LocalizedStringResource = "Notas"
    static let controlDescription: LocalizedStringResource = "Abre tus notas."
    static let systemImageName = "note.text"
    static let destination = NevilleControlDestination.notas
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenGoalsControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-goals"
    static let title: LocalizedStringResource = "Metas"
    static let controlDescription: LocalizedStringResource = "Abre tus metas."
    static let systemImageName = "target"
    static let destination = NevilleControlDestination.metas
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenCalmSpaceControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-calm-space"
    static let title: LocalizedStringResource = "Espacio Calma"
    static let controlDescription: LocalizedStringResource = "Abre Espacio Calma."
    static let systemImageName = "sparkles"
    static let destination = NevilleControlDestination.calma
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenCoherenceControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-coherence"
    static let title: LocalizedStringResource = "Coherencia cardiocerebral"
    static let controlDescription: LocalizedStringResource = "Abre la práctica de coherencia cardiocerebral."
    static let systemImageName = "waveform.path.ecg"
    static let destination = NevilleControlDestination.coherencia
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenAuthorsControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-authors"
    static let title: LocalizedStringResource = "Autores"
    static let controlDescription: LocalizedStringResource = "Abre las vistas de los autores."
    static let systemImageName = "person.3"
    static let destination = NevilleControlDestination.autores
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenAIChatControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-ai-chat"
    static let title: LocalizedStringResource = "Chat IA"
    static let controlDescription: LocalizedStringResource = "Abre el chat con inteligencia artificial."
    static let systemImageName = "ellipsis.message"
    static let destination = NevilleControlDestination.chatIA
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenHealingCenterControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-healing-center"
    static let title: LocalizedStringResource = "Centro Sanador"
    static let controlDescription: LocalizedStringResource = "Abre el Centro Sanador."
    static let systemImageName = "cross.case.fill"
    static let destination = NevilleControlDestination.centroSanador
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenConferencesControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-conferences"
    static let title: LocalizedStringResource = "Conferencias"
    static let controlDescription: LocalizedStringResource = "Abre el listado de conferencias."
    static let systemImageName = "text.book.closed"
    static let destination = NevilleControlDestination.conferencias
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenWeeklyReviewControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-weekly-review"
    static let title: LocalizedStringResource = "Resumen semanal"
    static let controlDescription: LocalizedStringResource = "Abre el resumen semanal."
    static let systemImageName = "calendar.badge.checkmark"
    static let destination = NevilleControlDestination.resumenSemanal
}

@available(iOSApplicationExtension 18.0, macOSApplicationExtension 26.0, *)
enum OpenLabelScannerControl: NevilleControlDescriptor {
    static let kind = "com.ypg.nev.control.open-label-scanner"
    static let title: LocalizedStringResource = "Lector de etiquetas"
    static let controlDescription: LocalizedStringResource = "Abre el lector de etiquetas."
    static let systemImageName = "barcode.viewfinder"
    static let destination = NevilleControlDestination.lectorEtiquetas
}


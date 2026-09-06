#if os(iOS) || os(macOS)
import Foundation

private enum AgendaPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "Agenda_1"
    case c2 = "Agenda_2"
    case c3 = "Agenda_3"
    case c4 = "Agenda_4"
    case c5 = "Agenda_5"
}

extension PremiumFeaturePresentation {
    static var agenda: Self {
        .localized(
            id: .agenda,
            iconName: "calendar.badge.clock",
            title: ("premium.agenda.title", "Agenda consciente"),
            description: ("premium.agenda.description", "Organiza actividades, tareas y compromisos en el tiempo, añade recordatorios y mantén a la vista aquello que merece tu atención."),
            practicalValue: ("premium.agenda.value", "Libera carga mental, reduce olvidos y convierte tus prioridades en acciones concretas sin perder el equilibrio de tu día."),
            screenshotNames: AgendaPremiumScreenshot.orderedNames
        )
    }
}
#endif

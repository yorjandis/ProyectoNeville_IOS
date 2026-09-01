#if os(iOS) || os(macOS)
import Foundation

private enum AgendaPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "agenda_premium_1"
    case planning = "agenda_premium_2"
    case reminders = "agenda_premium_3"
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

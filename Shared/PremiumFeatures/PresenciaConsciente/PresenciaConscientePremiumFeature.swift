#if os(iOS) || os(macOS)
import Foundation

private enum PresenciaConscientePremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "Presencia_1"
    case c2 = "Presencia_2"
    case c3 = "Presencia_3"
}

extension PremiumFeaturePresentation {
    static var consciousPresence: Self {
        .localized(
            id: .consciousPresence,
            iconName: "figure.mind.and.body",
            title: ("premium.presence.title", "Presencia Consciente"),
            description: ("premium.presence.description", "Registra pequeños instantes de despertar, reconoce cuándo sales del piloto automático y observa la evolución de tus estados internos."),
            practicalValue: ("premium.presence.value", "Entrena el hábito de volver al presente con un solo toque y transforma momentos cotidianos en oportunidades reales de conciencia."),
            screenshotNames: PresenciaConscientePremiumScreenshot.orderedNames
        )
    }
}
#endif

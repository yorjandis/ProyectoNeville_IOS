#if os(iOS) || os(macOS)
import Foundation

private enum PresenciaConscientePremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "presencia_premium_1"
    case checkIn = "presencia_premium_2"
    case progress = "presencia_premium_3"
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

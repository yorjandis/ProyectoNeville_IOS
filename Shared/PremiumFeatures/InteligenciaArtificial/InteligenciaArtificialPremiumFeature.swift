#if os(iOS) || os(macOS)
import Foundation

private enum InteligenciaArtificialPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "ia_premium_1"
    case conversation = "ia_premium_2"
    case result = "ia_premium_3"
}

extension PremiumFeaturePresentation {
    static var integratedAI: Self {
        .localized(
            id: .integratedAI,
            iconName: "brain.head.profile.fill",
            title: ("premium.ai.title", "Inteligencia Artificial integrada"),
            description: ("premium.ai.description", "Obtén resúmenes, interpretaciones, prácticas concretas y conversaciones contextualizadas en el campo de conocimiento de cada autor."),
            practicalValue: ("premium.ai.value", "Pasa de leer a comprender y aplicar: convierte contenido complejo en ideas útiles para tu situación real y tus próximos pasos."),
            screenshotNames: InteligenciaArtificialPremiumScreenshot.orderedNames
        )
    }
}
#endif

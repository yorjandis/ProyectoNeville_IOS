#if os(iOS) || os(macOS)
import Foundation

private enum FrasesRelacionadasPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "frases_relacionadas_premium_1"
    case connections = "frases_relacionadas_premium_2"
    case exploration = "frases_relacionadas_premium_3"
}

extension PremiumFeaturePresentation {
    static var relatedQuotes: Self {
        .localized(
            id: .relatedQuotes,
            iconName: "point.3.connected.trianglepath.dotted",
            title: ("premium.related_quotes.title", "Frases Relacionadas"),
            description: ("premium.related_quotes.description", "Conecta enseñanzas de distintos autores con tus propias ideas para descubrir relaciones que antes permanecían separadas."),
            practicalValue: ("premium.related_quotes.value", "Construye un mapa vivo de tu aprendizaje y transforma citas aisladas en una comprensión personal más profunda."),
            screenshotNames: FrasesRelacionadasPremiumScreenshot.orderedNames
        )
    }
}
#endif

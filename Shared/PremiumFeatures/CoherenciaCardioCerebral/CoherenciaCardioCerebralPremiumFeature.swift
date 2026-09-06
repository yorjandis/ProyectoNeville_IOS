#if os(iOS) || os(macOS)
import Foundation

private enum CoherenciaCardioCerebralPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "CC_1"
    case c2 = "CC_2"
    case c3 = "CC_3"
    case c4 = "CC_4"
}

extension PremiumFeaturePresentation {
    static var cardioCoherence: Self {
        .localized(
            id: .cardioCoherence,
            iconName: "heart.circle.fill",
            title: ("premium.cardio_coherence.title", "Coherencia cardio-cerebral"),
            description: ("premium.cardio_coherence.description", "Sigue un asistente de respiración y enfoque diseñado para favorecer un estado interno más ordenado, sereno y creativo."),
            practicalValue: ("premium.cardio_coherence.value", "Crea una pausa de calidad en pocos minutos y entrena una respuesta más consciente ante la presión cotidiana."),
            screenshotNames: CoherenciaCardioCerebralPremiumScreenshot.orderedNames
        )
    }
}
#endif

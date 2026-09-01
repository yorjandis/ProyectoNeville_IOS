#if os(iOS) || os(macOS)
import Foundation

private enum ProtocoloTransformacionPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "transformacion_premium_1"
    case process = "transformacion_premium_2"
    case progress = "transformacion_premium_3"
}

extension PremiumFeaturePresentation {
    static var transformationProtocol: Self {
        .localized(
            id: .transformationProtocol,
            iconName: "21.circle.fill",
            title: ("premium.transformation.title", "Transformación personal · 21 días"),
            description: ("premium.transformation.description", "Sigue un programa guiado para reconocer patrones automáticos, interrumpirlos y entrenar respuestas conscientes con prácticas, diario y seguimiento."),
            practicalValue: ("premium.transformation.value", "Mantén foco y continuidad durante 21 días para que el aprendizaje deje de ser solo una idea y empiece a convertirse en experiencia."),
            screenshotNames: ProtocoloTransformacionPremiumScreenshot.orderedNames
        )
    }
}
#endif

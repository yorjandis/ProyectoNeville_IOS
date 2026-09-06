#if os(iOS) || os(macOS)
import Foundation

private enum ProtocoloTransformacionPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "ProtocoloTrans_1"
    case c2 = "ProtocoloTrans_2"
    case c3 = "ProtocoloTrans_3"
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

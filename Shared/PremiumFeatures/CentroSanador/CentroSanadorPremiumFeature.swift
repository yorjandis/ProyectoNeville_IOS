#if os(iOS) || os(macOS)
import Foundation

private enum CentroSanadorPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "centro_sanador_premium_1"
    case guidance = "centro_sanador_premium_2"
    case practice = "centro_sanador_premium_3"
}

extension PremiumFeaturePresentation {
    static var healingCenter: Self {
        .localized(
            id: .healingCenter,
            iconName: "cross.case.fill",
            title: ("premium.healing_center.title", "Centro Sanador"),
            description: ("premium.healing_center.description", "Accede a guías claras para momentos de ansiedad, miedo, estrés, bloqueo, conflicto o impulso, con prácticas explicadas paso a paso."),
            practicalValue: ("premium.healing_center.value", "Comprende lo que ocurre en tu cuerpo y recupera capacidad de elección justo cuando más la necesitas, con un apoyo práctico siempre disponible."),
            screenshotNames: CentroSanadorPremiumScreenshot.orderedNames
        )
    }
}
#endif

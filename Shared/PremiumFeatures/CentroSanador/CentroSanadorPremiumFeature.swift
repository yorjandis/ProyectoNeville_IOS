#if os(iOS) || os(macOS)
import Foundation

private enum CentroSanadorPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "CSanador_1"
    case c2 = "CSanador_2"
    case c3 = "CSanador_3"
    case c4 = "CSanador_4"
    case c5 = "CSanador_5"
    case c6 = "CSanador_6"
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

#if os(iOS) || os(macOS)
import Foundation

private enum EspacioCalmaPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "EspacioC_1"
    case c2 = "EspacioC_2"
    case c3 = "EspacioC_3"
    case c4 = "EspacioC_4"
    case c5 = "EspacioC_5"
    case c6 = "EspacioC_6"
}

extension PremiumFeaturePresentation {
    static var calmSpace: Self {
        .localized(
            id: .calmSpace,
            iconName: "leaf.fill",
            title: ("premium.calm_space.title", "Espacio Calma"),
            description: ("premium.calm_space.description", "Combina imágenes, música, sonidos y frases en una experiencia inmersiva pensada para ayudarte a bajar el ritmo y volver a ti."),
            practicalValue: ("premium.calm_space.value", "Convierte cualquier pausa en un pequeño ritual de regulación que favorece descanso, claridad y aprendizaje."),
            screenshotNames: EspacioCalmaPremiumScreenshot.orderedNames
        )
    }
}
#endif

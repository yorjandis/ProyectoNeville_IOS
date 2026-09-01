#if os(iOS) || os(macOS)
import Foundation

private enum EspacioCalmaPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "espacio_calma_premium_1"
    case environment = "espacio_calma_premium_2"
    case experience = "espacio_calma_premium_3"
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

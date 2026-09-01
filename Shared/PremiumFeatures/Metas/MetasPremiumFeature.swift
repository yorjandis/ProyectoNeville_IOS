#if os(iOS) || os(macOS)
import Foundation

private enum MetasPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "metas_premium_1"
    case planning = "metas_premium_2"
    case progress = "metas_premium_3"
}

extension PremiumFeaturePresentation {
    static var goals: Self {
        .localized(
            id: .goals,
            iconName: "target",
            title: ("premium.goals.title", "Metas y transformación personal"),
            description: ("premium.goals.description", "Define objetivos claros, divídelos en unidades alcanzables, mide tu progreso y apóyate en programas prácticos para consolidar hábitos."),
            practicalValue: ("premium.goals.value", "Convierte aspiraciones abstractas en un camino visible, refuerza tu constancia y celebra evidencia real de avance."),
            screenshotNames: MetasPremiumScreenshot.orderedNames
        )
    }
}
#endif

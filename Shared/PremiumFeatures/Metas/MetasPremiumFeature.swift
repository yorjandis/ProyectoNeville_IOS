#if os(iOS) || os(macOS)
import Foundation

private enum MetasPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "Metas_1"
    case c2 = "Metas_2"
    case c3 = "Metas_3"
    case c4 = "Metas_4"
    case c5 = "Metas_5"
    case c6 = "Metas_6"
    case c7 = "Metas_7"
    case c8 = "Metas_8"
    case c9 = "Metas_9"
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

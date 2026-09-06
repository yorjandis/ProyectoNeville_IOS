#if os(iOS) || os(macOS)
import Foundation

private enum RevisionSemanalPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "ResumenSemanal_1"
    case c2 = "ResumenSemanal_2"
}

extension PremiumFeaturePresentation {
    static var weeklyReview: Self {
        .localized(
            id: .weeklyReview,
            iconName: "calendar.badge.checkmark",
            title: ("premium.weekly_review.title", "Revisión semanal guiada"),
            description: ("premium.weekly_review.description", "Cierra la semana con una síntesis de metas, agenda, diario, emociones, presencia, coherencia y logros, conservando cada revisión."),
            practicalValue: ("premium.weekly_review.value", "Detecta patrones, reconoce avances y comienza la semana siguiente con aprendizaje acumulado en lugar de empezar de cero."),
            screenshotNames: RevisionSemanalPremiumScreenshot.orderedNames
        )
    }
}
#endif

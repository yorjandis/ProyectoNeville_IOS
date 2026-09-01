#if os(iOS) || os(macOS)
import Foundation

private enum CicloConscienteDiarioPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case introduction = "Ritual_premium_1"
    case intention = "Ritual_premium_2"
    case preparation = "Ritual_premium_3"
    case practice = "Ritual_premium_4"
    case completion = "Ritual_premium_5"
}

extension PremiumFeaturePresentation {
    static var consciousDailyCycle: Self {
        .localized(
            id: .consciousDailyCycle,
            iconName: "sun.and.horizon.fill",
            title: ("premium.daily_cycle.title", "Ciclo consciente diario"),
            description: ("premium.daily_cycle.description", "Comienza la mañana con intención, observa tu presencia durante el día y ciérralo con una revisión que conserva lo aprendido en tu Diario."),
            practicalValue: ("premium.daily_cycle.value", "Da continuidad a tu crecimiento con un ritmo sencillo: orientar, vivir con atención, integrar y usar lo aprendido al día siguiente."),
            screenshotNames: CicloConscienteDiarioPremiumScreenshot.orderedNames
        )
    }
}
#endif

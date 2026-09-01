#if os(iOS) || os(macOS)
import Foundation

private enum RecordatoriosPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "recordatorios_premium_1"
    case configuration = "recordatorios_premium_2"
    case notification = "recordatorios_premium_3"
}

extension PremiumFeaturePresentation {
    static var smartReminders: Self {
        .localized(
            id: .smartReminders,
            iconName: "bell.badge.fill",
            title: ("premium.reminders.title", "Recordatorios inteligentes"),
            description: ("premium.reminders.description", "Programa avisos para meditar, agradecer, visualizar, revisar tus metas o sostener cualquier práctica esencial para ti."),
            practicalValue: ("premium.reminders.value", "Reduce la distancia entre saber lo que te hace bien y recordarlo en el momento adecuado para convertirlo en hábito."),
            screenshotNames: RecordatoriosPremiumScreenshot.orderedNames
        )
    }
}
#endif

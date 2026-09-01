#if os(iOS) || os(macOS)
import Foundation

private enum TutorialesPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "tutoriales_premium_1"
    case lesson = "tutoriales_premium_2"
    case example = "tutoriales_premium_3"
}

extension PremiumFeaturePresentation {
    static var tutorials: Self {
        .localized(
            id: .tutorials,
            iconName: "play.rectangle.on.rectangle.fill",
            title: ("premium.tutorials.title", "Tutoriales guiados"),
            description: ("premium.tutorials.description", "Aprende visualmente a aprovechar las herramientas más potentes de la app mediante recorridos claros y ejemplos prácticos."),
            practicalValue: ("premium.tutorials.value", "Domina antes cada función, evita ensayo y error y empieza a obtener valor desde los primeros minutos."),
            screenshotNames: TutorialesPremiumScreenshot.orderedNames
        )
    }
}
#endif

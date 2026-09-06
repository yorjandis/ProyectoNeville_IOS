#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var tutorials: Self {
        .localized(
            id: .tutorials,
            iconName: "play.rectangle.on.rectangle.fill",
            title: ("premium.tutorials.title", "Tutoriales guiados"),
            description: ("premium.tutorials.description", "Aprende visualmente a aprovechar las herramientas más potentes de la app mediante recorridos claros y ejemplos prácticos."),
            practicalValue: ("premium.tutorials.value", "Domina antes cada función, evita ensayo y error y empieza a obtener valor desde los primeros minutos."),
            screenshotNames: []
        )
    }
}
#endif

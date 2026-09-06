#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var siriShortcuts: Self {
        .localized(
            id: .siriShortcuts,
            iconName: "mic.badge.plus",
            title: ("premium.siri.title", "Atajos y comandos con Siri"),
            description: ("premium.siri.description", "Crea notas, añade entradas al diario, guarda frases o abre herramientas usando tu voz y los Atajos del sistema."),
            practicalValue: ("premium.siri.value", "Captura lo importante incluso cuando tienes las manos ocupadas y reduce la fricción para mantener tu práctica al día."),
            screenshotNames: []
        )
    }
}
#endif

#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var smartCopiedText: Self {
        .localized(
            id: .smartCopiedText,
            iconName: "text.badge.checkmark",
            title: ("premium.copied_text.title", "Menú inteligente de texto"),
            description: ("premium.copied_text.description", "Selecciona fragmentos dentro de la app y accede de inmediato a acciones para guardar, interpretar, relacionar o transformar ese contenido."),
            practicalValue: ("premium.copied_text.value", "Aprovecha una idea cuando te inspira sin romper el ritmo de lectura y conviértela en material útil con menos pasos."),
            screenshotNames: []
        )
    }
}
#endif

#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var universalImport: Self {
        .localized(
            id: .universalImport,
            iconName: "square.and.arrow.down.fill",
            title: ("premium.universal_import.title", "Importación desde cualquier lugar"),
            description: ("premium.universal_import.description", "Guarda texto e imágenes desde webs y otras apps mediante el menú Compartir, con reconocimiento de texto y lectura de códigos QR."),
            practicalValue: ("premium.universal_import.value", "Captura una idea valiosa en el momento en que aparece y llévala directamente a tu sistema personal sin pasos innecesarios."),
            screenshotNames: []
        )
    }
}
#endif

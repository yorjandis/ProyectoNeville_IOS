#if os(iOS) || os(macOS)
import Foundation

private enum ContenidoExtendidoPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case overview = "contenido_premium_1"
    case reading = "contenido_premium_2"
    case learning = "contenido_premium_3"
}

extension PremiumFeaturePresentation {
    static var extendedContent: Self {
        .localized(
            id: .extendedContent,
            iconName: "books.vertical.fill",
            title: ("premium.extended_content.title", "Contenido extendido"),
            description: ("premium.extended_content.description", "Profundiza en lecturas, análisis, prácticas y materiales seleccionados que amplían las ideas principales de la aplicación."),
            practicalValue: ("premium.extended_content.value", "Pasa de una primera inspiración a un aprendizaje estructurado que puedas comprender, revisar e incorporar a tu vida."),
            screenshotNames: ContenidoExtendidoPremiumScreenshot.orderedNames
        )
    }
}
#endif

#if os(iOS) || os(macOS)
import Foundation

private enum LienzoCreativoPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "Lienzo_1"
    case c2 = "Lienzo_2"
    case c3 = "Lienzo_3"
    case c4 = "Lienzo_4"
}

extension PremiumFeaturePresentation {
    static var creativeCanvas: Self {
        .localized(
            id: .creativeCanvas,
            iconName: "paintpalette.fill",
            title: ("premium.creative_canvas.title", "Lienzo creativo"),
            description: ("premium.creative_canvas.description", "Diseña composiciones visuales con tus frases e imágenes favoritas para compartir, imprimir o mantener como recordatorio personal."),
            practicalValue: ("premium.creative_canvas.value", "Haz visible aquello en lo que deseas enfocarte y crea piezas personales capaces de acompañar y reforzar tu intención diaria."),
            screenshotNames: LienzoCreativoPremiumScreenshot.orderedNames
        )
    }
}
#endif

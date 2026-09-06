#if os(iOS) || os(macOS)
import Foundation

private enum LectorEtiquetasPremiumScreenshot: String, PremiumFeatureScreenshotName {
    case c1 = "InspAlimento_1"
    case c2 = "InspAlimento_2"
    case c3 = "InspAlimento_3"
    case c4 = "InspAlimento_4"
}

extension PremiumFeaturePresentation {
    static var labelScanner: Self {
        .localized(
            id: .labelScanner,
            iconName: "barcode.viewfinder",
            title: ("premium.label_scanner.title", "Lector de Etiquetas"),
            description: ("premium.label_scanner.description", "Analiza alimentos y consulta información nutricional, criterios de consumo, posibles riesgos e impacto metabólico en una lectura clara."),
            practicalValue: ("premium.label_scanner.value", "Toma decisiones de compra más informadas en segundos y convierte una etiqueta difícil de entender en una guía práctica."),
            screenshotNames: LectorEtiquetasPremiumScreenshot.orderedNames
        )
    }
}
#endif

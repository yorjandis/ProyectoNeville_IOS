#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var pdfExport: Self {
        .localized(
            id: .pdfExport,
            iconName: "doc.richtext.fill",
            title: ("premium.pdf_export.title", "Exportación PDF"),
            description: ("premium.pdf_export.description", "Transforma notas, frases, agenda, reflexiones y respuestas de IA en documentos PDF limpios, portables y fáciles de compartir."),
            practicalValue: ("premium.pdf_export.value", "Conserva tu trabajo personal fuera de la app, imprímelo o compártelo con una presentación cuidada y universal."),
            screenshotNames: []
        )
    }
}
#endif

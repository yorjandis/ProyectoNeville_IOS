#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var shareQR: Self {
        .localized(
            id: .shareQR,
            iconName: "qrcode",
            title: ("premium.share_qr.title", "Comparte con QR"),
            description: ("premium.share_qr.description", "Genera códigos QR con notas, frases y contenido elegido para compartirlo de forma visual, directa y compatible con cualquier cámara."),
            practicalValue: ("premium.share_qr.value", "Lleva una idea del dispositivo al mundo físico en segundos y compártela sin depender de cuentas, enlaces largos o plataformas."),
            screenshotNames: []
        )
    }
}
#endif

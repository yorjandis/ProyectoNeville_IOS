#if os(iOS) || os(macOS)
import Foundation

extension PremiumFeaturePresentation {
    static var protectedNotes: Self {
        .localized(
            id: .protectedNotes,
            iconName: "lock.shield.fill",
            title: ("premium.protected_notes.title", "Notas protegidas"),
            description: ("premium.protected_notes.description", "Añade una capa de privacidad a tus notas mediante biometría o contraseña y conserva tus reflexiones personales lejos de miradas ajenas."),
            practicalValue: ("premium.protected_notes.value", "Escribe con mayor libertad y tranquilidad sabiendo que tu espacio íntimo permanece bajo tu control."),
            screenshotNames: []
        )
    }
}
#endif

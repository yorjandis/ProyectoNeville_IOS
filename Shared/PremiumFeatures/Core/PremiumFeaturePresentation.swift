#if os(iOS) || os(macOS)
import Foundation

/// Identificador estable de cada experiencia de la Versión Extendida.
/// Se usa para abrir la presentación adecuada sin acoplar la navegación a la vista comercial.
enum PremiumFeatureID: String, Identifiable, CaseIterable, Sendable {
    case agenda
    case healingCenter
    case cardioCoherence
    case calmSpace
    case pdfExport
    case relatedQuotes
    case universalImport
    case integratedAI
    case labelScanner
    case creativeCanvas
    case goals
    case protectedNotes
    case consciousPresence
    case transformationProtocol
    case smartReminders
    case weeklyReview
    case siriShortcuts
    case smartCopiedText
    case shareQR
    case consciousDailyCycle
    case tutorials
    case extendedContent

    var id: String { rawValue }

    var presentation: PremiumFeaturePresentation {
        switch self {
        case .agenda: .agenda
        case .healingCenter: .healingCenter
        case .cardioCoherence: .cardioCoherence
        case .calmSpace: .calmSpace
        case .pdfExport: .pdfExport
        case .relatedQuotes: .relatedQuotes
        case .universalImport: .universalImport
        case .integratedAI: .integratedAI
        case .labelScanner: .labelScanner
        case .creativeCanvas: .creativeCanvas
        case .goals: .goals
        case .protectedNotes: .protectedNotes
        case .consciousPresence: .consciousPresence
        case .transformationProtocol: .transformationProtocol
        case .smartReminders: .smartReminders
        case .weeklyReview: .weeklyReview
        case .siriShortcuts: .siriShortcuts
        case .smartCopiedText: .smartCopiedText
        case .shareQR: .shareQR
        case .consciousDailyCycle: .consciousDailyCycle
        case .tutorials: .tutorials
        case .extendedContent: .extendedContent
        }
    }
}

/// Contenido que la plantilla comercial necesita para presentar una herramienta.
/// Los textos se resuelven mediante `L10n`, por lo que cada carpeta puede evolucionar
/// y traducirse de forma independiente sin tocar la vista compartida.
struct PremiumFeaturePresentation: Identifiable, Sendable {
    let id: PremiumFeatureID
    let iconName: String
    let title: String
    let description: String
    let practicalValue: String
    let screenshotNames: [String]

    static func localized(
        id: PremiumFeatureID,
        iconName: String,
        title: (key: String, fallback: String),
        description: (key: String, fallback: String),
        practicalValue: (key: String, fallback: String),
        screenshotNames: [String]
    ) -> Self {
        Self(
            id: id,
            iconName: iconName,
            title: PremiumFeatureLocalization.string(title.key, fallback: title.fallback),
            description: PremiumFeatureLocalization.string(description.key, fallback: description.fallback),
            practicalValue: PremiumFeatureLocalization.string(practicalValue.key, fallback: practicalValue.fallback),
            screenshotNames: screenshotNames
        )
    }
}

/// Contrato común para que cada función declare sus capturas mediante un enum.
/// `CaseIterable` conserva el orden exacto en el que aparecen sus casos.
protocol PremiumFeatureScreenshotName: CaseIterable, RawRepresentable where RawValue == String {}

extension PremiumFeatureScreenshotName {
    static var orderedNames: [String] {
        allCases.map(\.rawValue)
    }
}

nonisolated enum PremiumFeatureLocalization {
    static let table = "PremiumFeatures"

    static func string(_ key: String, fallback: String) -> String {
        L10n.string(key, fallback: fallback, table: table)
    }

    static func format(_ key: String, fallback: String, _ arguments: String...) -> String {
        var result = string(key, fallback: fallback)
        for (index, argument) in arguments.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: argument)
        }
        return result
    }
}
#endif

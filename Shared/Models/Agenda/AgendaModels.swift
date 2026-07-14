import SwiftUI

enum AgendaPriority: String, CaseIterable, Identifiable {
    case neutral
    case baja
    case media
    case alta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral: return L10n.exact("Neutral")
        case .baja: return L10n.exact("Baja")
        case .media: return L10n.exact("Media")
        case .alta: return L10n.exact("Alta")
        }
    }

    var tint: Color {
        switch self {
        case .neutral: return Color.black.opacity(0.35)
        case .baja: return Color(red: 0.55, green: 0.72, blue: 0.52)
        case .media: return Color(red: 0.87, green: 0.74, blue: 0.48)
        case .alta: return Color(red: 0.83, green: 0.53, blue: 0.47)
        }
    }
}

struct AgendaItemData: Identifiable, Hashable {
    var id: UUID
    var titulo: String
    var fechaCreacion: Date
    var fechaModificacion: Date
    var nota: String
    var fechaActividad: Date
    var hora: Date
    var lugar: String
    var contenido: String
    var prioridad: AgendaPriority
    var colorHex: String
    var completada: Bool?
    var recordatorioActivo: Bool
    var reminderID: String?
    var seriesID: UUID?
}

enum AgendaRecurrenceMode: String, CaseIterable, Identifiable {
    case none
    case weekdays
    case specificDates
    case frequency

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return L10n.exact("Sin repetir")
        case .weekdays: return L10n.exact("Días de la semana")
        case .specificDates: return L10n.exact("Fechas concretas")
        case .frequency: return L10n.exact("Frecuencia")
        }
    }
}

enum AgendaRecurrenceFrequency: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return L10n.exact("Semanal")
        case .monthly: return L10n.exact("Mensual")
        case .yearly: return L10n.exact("Anual")
        }
    }
}

enum AgendaDeleteScope {
    case onlyThis
    case wholeSeries
}

import SwiftUI

enum AgendaPriority: String, CaseIterable, Identifiable {
    case neutral
    case baja
    case media
    case alta

    var id: String { rawValue }

    var title: String {
        switch self {
        case .neutral: return "Neutral"
        case .baja: return "Baja"
        case .media: return "Media"
        case .alta: return "Alta"
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
        case .none: return "Sin repetir"
        case .weekdays: return "Días de la semana"
        case .specificDates: return "Fechas concretas"
        case .frequency: return "Frecuencia"
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
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        case .yearly: return "Anual"
        }
    }
}

enum AgendaDeleteScope {
    case onlyThis
    case wholeSeries
}

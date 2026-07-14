//
//  TimeUnit.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI

enum TimeUnit: String, CaseIterable, Codable {
    case minutos, horas, dias, semanas, meses, años

    var calendarComponent: Calendar.Component {
        switch self {
        case .minutos: return .minute
        case .horas: return .hour
        case .dias: return .day
        case .semanas: return .weekOfYear
        case .meses: return .month
        case .años: return .year
        }
    }
    
    func description(for value: Int) -> String {
            switch self {
            case .minutos:
                return value == 1 ? "minuto" : "minutos"
            case .dias:
                return value == 1 ? "día" : "días"
            case .semanas:
                return value == 1 ? "semana" : "semanas"
            case .meses:
                return value == 1 ? "mes" : "meses"
            case .años:
                return value == 1 ? "año" : "años"
            case .horas:
                return value == 1 ? "hora" : "horas"
            }
        }
    
}
//Asigna una prioridad a cada unidad de tiempo, para poder organizarlas en la lista de objetivos:
//comenzando por los objetivos de horas, seguido por dias, meses y años.
extension TimeUnit {
    var label: String {
        switch self {
        case .minutos: return "Minutos"
        case .horas: return "Horas"
        case .dias: return "Días"
        case .semanas: return "Semanas"
        case .meses: return "Meses"
        case .años: return "Años"
        }
    }

    var priority: Int {
        switch self {
        case .minutos: return 0
        case .horas: return 1
        case .dias: return 2
        case .semanas: return 3
        case .meses: return 4
        case .años: return 5
        }
    }
}

enum GoalScheduleType: String, CaseIterable, Codable {
    case interval
    case weekly
    case specificDates

    var label: String {
        switch self {
        case .interval: return "Por intervalo"
        case .weekly: return "Días por semana"
        case .specificDates: return "Fechas específicas"
        }
    }
}

enum GoalCompletionBasis: String, CaseIterable, Codable {
    case executions
    case duration

    var label: String {
        switch self {
        case .executions: return "Número de ejecuciones"
        case .duration: return "Duración total"
        }
    }
}

enum GoalDayPeriod: String, CaseIterable, Codable {
    case anytime
    case morning
    case afternoon
    case night

    var label: String {
        switch self {
        case .anytime: return "Cualquier momento"
        case .morning: return "Por la mañana"
        case .afternoon: return "Por la tarde"
        case .night: return "Por la noche"
        }
    }

    /// Limita una ejecución al tramo elegido. La noche termina a las 05:00
    /// del día siguiente para que una ejecución nocturna no caduque a medianoche.
    func window(on date: Date, calendar: Calendar = .current) -> (start: Date, end: Date)? {
        guard self != .anytime else { return nil }
        let day = calendar.startOfDay(for: date)

        switch self {
        case .anytime:
            return nil
        case .morning:
            return (
                calendar.date(byAdding: .hour, value: 5, to: day) ?? day,
                calendar.date(byAdding: .hour, value: 12, to: day) ?? day
            )
        case .afternoon:
            return (
                calendar.date(byAdding: .hour, value: 12, to: day) ?? day,
                calendar.date(byAdding: .hour, value: 20, to: day) ?? day
            )
        case .night:
            return (
                calendar.date(byAdding: .hour, value: 20, to: day) ?? day,
                calendar.date(byAdding: .hour, value: 29, to: day) ?? day
            )
        }
    }
}

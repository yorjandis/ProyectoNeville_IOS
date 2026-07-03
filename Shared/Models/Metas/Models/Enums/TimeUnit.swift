//
//  TimeUnit.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI

enum TimeUnit: String, CaseIterable, Codable {
    case minutos, horas, dias, meses, años

    var calendarComponent: Calendar.Component {
        switch self {
        case .minutos: return .minute
        case .horas: return .hour
        case .dias: return .day
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
        case .meses: return "Meses"
        case .años: return "Años"
        }
    }

    var priority: Int {
        switch self {
        case .minutos: return 0
        case .horas: return 1
        case .dias: return 2
        case .meses: return 3
        case .años: return 4
        }
    }
}

//
//  TimeUnit.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI

enum TimeUnit: String, CaseIterable {
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
}
//Asigna una prioridad a cada unidad de tiempo, para poder organizarlas en la lista de objetivos:
//comenzando por los objetivos de horas, seguido por dias, meses y años.
extension TimeUnit {
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

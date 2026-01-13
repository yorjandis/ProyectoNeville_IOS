//
//  DateHelper.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 8/1/26.
//

import SwiftUI

//Extensión de Date que calcula el tiempo restante para completarse una Hora, un dia, un mes y un año

//Utilizada para mostrar el tiempo que falta para que una unidad lista para chequear va a caducar:
extension Date {
    var nextHour: Date {
        let calendar = Calendar.current
        let nextHour = calendar.date(bySettingHour: calendar.component(.hour, from: self) + 1,
                                     minute: 0, second: 0, of: self)!
        return nextHour
    }
    
    var nextDay: Date {
        let calendar = Calendar.current
        let nextDay = calendar.date(bySettingHour: 0, minute: 0, second: 0,
                                    of: calendar.date(byAdding: .day, value: 1, to: self)!)!
        return nextDay
    }
    
    var nextMonth: Date {
        let calendar = Calendar.current
        let nextMonth = calendar.date(bySettingHour: 0, minute: 0, second: 0,
                                      of: calendar.date(byAdding: .month, value: 1, to: self)!.startOfMonth)!
        return nextMonth
    }
    
    var nextYear: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: self)
        let nextYear = calendar.date(from: DateComponents(year: (components.year ?? 0) + 1, month: 1, day: 1))!
        return nextYear
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: self))!
    }
}

//
//  EnumReminderFrecuency.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

import SwiftUI

import Foundation

//Constantes de Identificadores:
enum ReminderNotificationConstants {
    static let categoryId = "REMINDER_CATEGORY"
    static let viewActionId = "VIEW_REMINDER"
    static let cancelActionId = "CANCEL_REMINDER"
}



//La frecuencia es un intervalo albitrario en horas + minutos, o diario a una hora dada.
enum ReminderFrequency: Identifiable, Codable {

    case interval(hours: Int, minutes: Int)
    case daily(hour: Int, minute: Int)
    case date(Date)

    var id: String {
        switch self {
        case .interval(let h, let m):
            return "interval_\(h)_\(m)"
        case .daily(let h, let m):
            return "daily_\(h)_\(m)"
        case .date(let date):
            return "date_\(date.timeIntervalSince1970)"
        }
    }

    var description: String {
        switch self {
        case .interval(let h, let m):
            var parts: [String] = []
            if h > 0 { parts.append("\(h)h") }
            if m > 0 { parts.append("\(m)m") }
            return "Cada " + parts.joined(separator: " ")

        case .daily(let h, let m):
            return String(format: "Todos los días a las %02d:%02d", h, m)

        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "El \(formatter.string(from: date))"
        }
    }

    var timeInterval: TimeInterval? {
        switch self {
        case .interval(let h, let m):
            return TimeInterval(h * 3600 + m * 60)
        default:
            return nil
        }
    }

    var isInterval: Bool {
        if case .interval = self { return true }
        return false
    }
}

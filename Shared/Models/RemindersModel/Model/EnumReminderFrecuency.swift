//
//  EnumReminderFrecuency.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//

/*
 Te dejo un mini-resumen mental (por si en unos meses vuelves a este código)
     •    startedAt es la clave del progreso
     •    Crear → asignar
     •    Pausar → limpiar
     •    Reanudar → volver a asignar
 
     •    Cada tipo de frecuencia tiene su semántica temporal
     •    .interval → ciclo fijo
     •    .daily / .date / .monthly / .yearly → cuenta atrás al próximo disparo
     •    @ViewBuilder = lógica declarativa
     •    if / switch / EmptyView
     •    nunca return ni guard

 Con eso en la cabeza, este sistema es muy fácil de mantener y extender 👍
 */


import SwiftUI

import Foundation

//Constantes de Identificadores:
enum ReminderNotificationConstants {
    static let categoryId = "REMINDER_CATEGORY"
    static let stopActionId = "STOP_REMINDER"
}



//La frecuencia es un intervalo albitrario en horas + minutos, o diario a una hora dada.
enum ReminderFrequency: Identifiable, Codable, Equatable, Hashable {

    case interval(hours: Int, minutes: Int)
    case daily(hour: Int, minute: Int)
    case date(Date)
    case monthly(day: Int, hour: Int, minute: Int)
    case yearly(month: Int, day: Int, hour: Int, minute: Int)

    var id: String {
        switch self {
        case .interval(let h, let m):
            return "interval_\(h)_\(m)"
        case .daily(let h, let m):
            return "daily_\(h)_\(m)"
        case .date(let date):
            return "date_\(date.timeIntervalSince1970)"
        case .monthly(let day, let hour, let minute):
                return "monthly_\(day)_\(hour)_\(minute)"
        case .yearly(let month, let day, let hour, let minute):
               return "yearly_\(month)_\(day)_\(hour)_\(minute)"
            
        }
    }

    var description: String {
        switch self {
        case .interval(let h, let m):
            var parts: [String] = []
            if h > 0 { parts.append("\(h)h") }
            if m > 0 { parts.append("\(m)m") }
            let format = L10n.string("reminder.frequency.interval", fallback: "Cada %@")
            return String(format: format, locale: AppLanguage.current.locale, parts.joined(separator: " "))

        case .daily(let h, let m):
            let format = L10n.string(
                "reminder.frequency.daily",
                fallback: "Todos los días a las %02d:%02d"
            )
            return String(format: format, locale: AppLanguage.current.locale, h, m)

        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatter.locale = AppLanguage.current.locale
            let format = L10n.string("reminder.frequency.date", fallback: "El %@")
            return String(format: format, locale: AppLanguage.current.locale, formatter.string(from: date))
            
        case .monthly(let day, let hour, let minute):
            let format = L10n.string(
                "reminder.frequency.monthly",
                fallback: "Cada mes el día %d a las %02d:%02d"
            )
            return String(
                format: format,
                locale: AppLanguage.current.locale,
                day, hour, minute
            )
            
        case .yearly(let month, let day, let hour, let minute):
                var components = DateComponents()
                components.month = month
                components.day = day
                components.hour = hour
                components.minute = minute

                let calendar = Calendar.current
                let date = calendar.date(from: components) ?? Date()

                let formatter = DateFormatter()
                formatter.locale = AppLanguage.current.locale
                formatter.setLocalizedDateFormatFromTemplate("MMMMdHm")

                let format = L10n.string("reminder.frequency.yearly", fallback: "Cada año el %@")
                return String(
                    format: format,
                    locale: AppLanguage.current.locale,
                    formatter.string(from: date)
                )
            
            
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
    
    //Permitir mostrar la barra de progreso:
    var permitirBarraProgreso: Bool {
        switch self {
        case .interval, .daily, .date, .monthly, .yearly:
            return true
        }
    }
}

//Permitir calcular el tiempo restante para .interval, .daily y .date:
/*
 ¿Que hace?
 .daily    -> Próxima hora válida
 .date     -> La fecha exacta
 .interval -> nil (ya tiene su propia lógica)

 */
extension ReminderFrequency {

    /// Devuelve la próxima fecha en la que se disparará el recordatorio
    func nextFireDate(from now: Date = Date()) -> Date? {
        let calendar = Calendar.current

        switch self {

        case .interval:
            return nil

        case .daily(let hour, let minute):
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = minute

            guard let today = calendar.date(from: components) else { return nil }

            // Si la hora de hoy ya pasó, usar mañana
            return today > now
                ? today
                : calendar.date(byAdding: .day, value: 1, to: today)

        case .date(let date):
            return date > now ? date : nil

        case .monthly(let day, let hour, let minute):

            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = day
            components.hour = hour
            components.minute = minute

            // Intentar este mes
            if let thisMonth = calendar.date(from: components),
               thisMonth > now {
                return thisMonth
            }

            // Siguiente mes
            return calendar.date(byAdding: .month, value: 1, to: calendar.date(from: components)!)

        case .yearly(let month, let day, let hour, let minute):

            var components = calendar.dateComponents([.year], from: now)
            components.month = month
            components.day = day
            components.hour = hour
            components.minute = minute

            // Intentar este año
            if let thisYear = calendar.date(from: components),
               thisYear > now {
                return thisYear
            }

            // Siguiente año
            components.year! += 1
            return calendar.date(from: components)
        }
    }
}

//Cálculo del progreso:
extension ReminderFrequency {

    /// Calcula progreso (elapsed / total) desde startedAt hasta el próximo disparo
    func progressSince(startedAt: Date) -> (elapsed: TimeInterval, total: TimeInterval)? {

        guard let fireDate = nextFireDate() else { return nil }

        let total = fireDate.timeIntervalSince(startedAt)
        let elapsed = Date().timeIntervalSince(startedAt)

        guard total > 0 else { return nil }

        return (elapsed, total)
    }
}

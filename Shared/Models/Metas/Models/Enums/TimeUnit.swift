//
//  TimeUnit.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI

nonisolated enum GoalsL10n {
    static func text(_ key: String, fallback: String) -> String {
        L10n.string(key, fallback: fallback)
    }

    static func format(_ key: String, fallback: String, _ values: String...) -> String {
        var result = text(key, fallback: fallback)
        for (index, value) in values.enumerated() {
            result = result.replacingOccurrences(of: "{\(index)}", with: value)
        }
        return result
    }

    static func unitNoun(count: Int) -> String {
        text(
            count == 1 ? "goals.noun.unit.one" : "goals.noun.unit.other",
            fallback: count == 1 ? "unidad" : "unidades"
        )
    }

    static func executionCount(_ count: Int) -> String {
        format(
            count == 1 ? "goals.dynamic.execution_count.one" : "goals.dynamic.execution_count.other",
            fallback: count == 1 ? "{0} ejecución" : "{0} ejecuciones",
            String(count)
        )
    }

    static func executionTarget(value: Double, number: String, label: String) -> String {
        if label.isEmpty {
            return value == 1
                ? text("goals.dynamic.execution_target.one", fallback: "Una ejecución")
                : format("goals.dynamic.execution_target.amount", fallback: "{0} por ejecución", number)
        }

        return value == 1
            ? format("goals.dynamic.execution_target.label_one", fallback: "{0} por ejecución", label)
            : format("goals.dynamic.execution_target.label_amount", fallback: "{0} {1} por ejecución", number, label)
    }

    static func intervalCadence(frequency: Int, unit: TimeUnit) -> String {
        format(
            frequency == 1
                ? "goals.dynamic.cadence.interval.one"
                : "goals.dynamic.cadence.interval.other",
            fallback: frequency == 1 ? "Cada {1}" : "Cada {0} {1}",
            String(frequency),
            unit.description(for: frequency)
        )
    }

    static func weeklyCadence(days: Int) -> String {
        format(
            days == 1 ? "goals.dynamic.cadence.weekly.one" : "goals.dynamic.cadence.weekly.other",
            fallback: days == 1 ? "{0} día por semana" : "{0} días por semana",
            String(days)
        )
    }

    static func dayCount(_ count: Int) -> String {
        format(
            count == 1 ? "goals.dynamic.day_count.one" : "goals.dynamic.day_count.other",
            fallback: count == 1 ? "{0} día" : "{0} días",
            String(count)
        )
    }

    static func specificDatesCadence(count: Int? = nil) -> String {
        guard let count else {
            return text("goals.dynamic.cadence.specific_dates", fallback: "En fechas específicas")
        }
        return format(
            "goals.dynamic.cadence.specific_dates_count",
            fallback: "en {0} fechas específicas",
            String(count)
        )
    }

    static func duration(value: Int, unit: TimeUnit) -> String {
        format(
            "goals.dynamic.duration",
            fallback: "durante {0} {1}",
            String(value),
            unit.description(for: value)
        )
    }

    static func addingPeriod(_ cadence: String, period: GoalDayPeriod) -> String {
        guard period != .anytime else { return cadence }
        return format(
            "goals.dynamic.schedule_with_period",
            fallback: "{0} · {1}",
            cadence,
            period.label
        )
    }

    static func unitDisplayName(_ storedName: String?, index: Int) -> String {
        let legacySpanish = "Unidad \(index)"
        let legacyEnglish = "Unit \(index)"
        let legacyChinese = "第 \(index) 次"
        let legacyChineseUnit = "执行项 \(index)"
        let value = storedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard value.isEmpty
                || value == legacySpanish
                || value == legacyEnglish
                || value == legacyChinese
                || value == legacyChineseUnit else {
            return value
        }
        return format("goals.dynamic.unit_name", fallback: "Unidad {0}", String(index))
    }

    static func countdown(hours: Int, minutes: Int, seconds: Int) -> String {
        if hours > 0 {
            return format(
                "goals.dynamic.countdown.hours_minutes",
                fallback: "{0}h {1}m",
                String(hours),
                String(minutes)
            )
        }
        if minutes > 0 {
            return format(
                "goals.dynamic.countdown.minutes_seconds",
                fallback: "{0}m {1}s",
                String(minutes),
                String(seconds)
            )
        }
        return format("goals.dynamic.countdown.seconds", fallback: "{0}s", String(seconds))
    }
}

nonisolated enum TimeUnit: String, CaseIterable, Codable {
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
        let suffix = value == 1 ? "one" : "other"
        let key: String
        let fallback: String
        switch self {
        case .minutos:
            key = "time_unit.minute.\(suffix)"
            fallback = value == 1 ? "minuto" : "minutos"
        case .horas:
            key = "time_unit.hour.\(suffix)"
            fallback = value == 1 ? "hora" : "horas"
        case .dias:
            key = "time_unit.day.\(suffix)"
            fallback = value == 1 ? "día" : "días"
        case .semanas:
            key = "time_unit.week.\(suffix)"
            fallback = value == 1 ? "semana" : "semanas"
        case .meses:
            key = "time_unit.month.\(suffix)"
            fallback = value == 1 ? "mes" : "meses"
        case .años:
            key = "time_unit.year.\(suffix)"
            fallback = value == 1 ? "año" : "años"
        }
        return L10n.string(key, fallback: fallback)
    }
    
}
//Asigna una prioridad a cada unidad de tiempo, para poder organizarlas en la lista de objetivos:
//comenzando por los objetivos de horas, seguido por dias, meses y años.
extension TimeUnit {
    var label: String {
        description(for: 2).localizedCapitalized
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

nonisolated enum GoalScheduleType: String, CaseIterable, Codable {
    case interval
    case weekly
    case specificDates

    var label: String {
        switch self {
        case .interval: return L10n.string("goal.schedule.interval", fallback: "Por intervalo")
        case .weekly: return L10n.string("goal.schedule.weekly", fallback: "Días por semana")
        case .specificDates: return L10n.string("goal.schedule.specific_dates", fallback: "Fechas específicas")
        }
    }
}

/// Día de la semana según la numeración de `Calendar` (domingo = 1).
nonisolated enum GoalWeekday: Int, CaseIterable, Codable, Hashable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    static let mondayFirst: [GoalWeekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var label: String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        let symbols = formatter.standaloneWeekdaySymbols ?? formatter.weekdaySymbols ?? []
        guard symbols.indices.contains(rawValue - 1) else { return fallbackLabel }
        return symbols[rawValue - 1].localizedCapitalized
    }

    var shortLabel: String {
        let formatter = DateFormatter()
        formatter.locale = AppLanguage.current.locale
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? []
        guard symbols.indices.contains(rawValue - 1) else { return String(label.prefix(3)) }
        return symbols[rawValue - 1].localizedCapitalized
    }

    private var fallbackLabel: String {
        switch self {
        case .sunday: return "Domingo"
        case .monday: return "Lunes"
        case .tuesday: return "Martes"
        case .wednesday: return "Miércoles"
        case .thursday: return "Jueves"
        case .friday: return "Viernes"
        case .saturday: return "Sábado"
        }
    }
}

nonisolated enum GoalWeeklySchedule {
    static func mask(for weekdays: Set<GoalWeekday>) -> Int16 {
        weekdays.reduce(into: Int16(0)) { result, weekday in
            result |= Int16(1 << (weekday.rawValue - 1))
        }
    }

    static func weekdays(from mask: Int16) -> Set<GoalWeekday> {
        Set(GoalWeekday.allCases.filter { weekday in
            mask & Int16(1 << (weekday.rawValue - 1)) != 0
        })
    }

    static func defaultWeekdays(count: Int) -> Set<GoalWeekday> {
        let presets: [[GoalWeekday]] = [
            [.monday],
            [.tuesday, .thursday],
            [.monday, .wednesday, .friday],
            [.monday, .tuesday, .thursday, .saturday],
            [.monday, .tuesday, .wednesday, .thursday, .friday],
            [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday],
            GoalWeekday.mondayFirst
        ]
        return Set(presets[min(max(count, 1), 7) - 1])
    }

    /// Reproduce el reparto histórico (N días consecutivos desde el inicio)
    /// para metas guardadas antes de que existiera la selección explícita.
    static func legacyWeekdays(
        count: Int,
        anchoredAt referenceDate: Date,
        calendar: Calendar = .current
    ) -> Set<GoalWeekday> {
        Set((0..<min(max(count, 1), 7)).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: referenceDate) else {
                return nil
            }
            return GoalWeekday(rawValue: calendar.component(.weekday, from: date))
        })
    }

    static func scheduledDays(
        count: Int,
        from referenceDate: Date,
        weekdays: Set<GoalWeekday>,
        period: GoalDayPeriod,
        calendar: Calendar = .current
    ) -> [Date] {
        guard count > 0, !weekdays.isEmpty else { return [] }

        var result: [Date] = []
        var candidate = calendar.startOfDay(for: referenceDate)
        var inspectedDays = 0
        let inspectionLimit = max(count * 7 + 7, 14)

        while result.count < count, inspectedDays < inspectionLimit {
            if let weekday = GoalWeekday(
                rawValue: calendar.component(.weekday, from: candidate)
            ), weekdays.contains(weekday) {
                if let window = period.window(on: candidate, calendar: calendar) {
                    if candidate > calendar.startOfDay(for: referenceDate) || referenceDate <= window.end {
                        result.append(candidate)
                    }
                } else {
                    result.append(candidate)
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
            candidate = next
            inspectedDays += 1
        }
        return result
    }

    static func plannedCount(
        from referenceDate: Date,
        until endDate: Date,
        weekdays: Set<GoalWeekday>,
        period: GoalDayPeriod,
        maximum: Int = 5_000,
        calendar: Calendar = .current
    ) -> Int {
        guard endDate > referenceDate, !weekdays.isEmpty else { return 0 }

        var count = 0
        var candidate = calendar.startOfDay(for: referenceDate)
        while candidate < endDate, count < maximum {
            if let weekday = GoalWeekday(
                rawValue: calendar.component(.weekday, from: candidate)
            ), weekdays.contains(weekday) {
                if let window = period.window(on: candidate, calendar: calendar) {
                    if candidate > calendar.startOfDay(for: referenceDate) || referenceDate <= window.end {
                        count += 1
                    }
                } else {
                    count += 1
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
            candidate = next
        }
        return count
    }

    static func summary(for weekdays: Set<GoalWeekday>) -> String {
        let labels = GoalWeekday.mondayFirst.filter(weekdays.contains).map(\.label)
        let formatter = ListFormatter()
        formatter.locale = AppLanguage.current.locale
        return formatter.string(from: labels) ?? labels.joined(separator: ", ")
    }
}

nonisolated enum GoalCompletionBasis: String, CaseIterable, Codable {
    case executions
    case duration

    var label: String {
        switch self {
        case .executions: return L10n.string("goal.completion.executions", fallback: "No. ejecuciones")
        case .duration: return L10n.string("goal.completion.duration", fallback: "Duración total")
        }
    }
}

nonisolated enum GoalDayPeriod: String, CaseIterable, Codable {
    case anytime
    case morning
    case afternoon
    case night

    var label: String {
        switch self {
        case .anytime: return L10n.string("goal.period.anytime", fallback: "Cualquier momento")
        case .morning: return L10n.string("goal.period.morning", fallback: "Por la mañana")
        case .afternoon: return L10n.string("goal.period.afternoon", fallback: "Por la tarde")
        case .night: return L10n.string("goal.period.night", fallback: "Por la noche")
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

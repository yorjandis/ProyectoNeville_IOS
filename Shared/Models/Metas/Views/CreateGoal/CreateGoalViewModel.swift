//
//  CreateGoalViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI
import Combine

@MainActor
final class CreateGoalViewModel: ObservableObject {

    @Published var title: String            = ""        //Título de la meta
    @Published var description: String      = ""        //Campo Descripción de la meta
    @Published var note: String             = ""        //Campo Nota de la Meta
    @Published var amount: Int              = 21        //Cantidad de Unidades por defecto
    @Published var unit: TimeUnit           = .dias     //Unidad de tiempo por defecto
    @Published var frequency: Int           = 1         //Frecuencia por defecto
    @Published var scheduleType: GoalScheduleType = .interval
    @Published var weeklyDaysPerWeek: Int   = 3
    @Published var selectedWeeklyDays: Set<GoalWeekday> = GoalWeeklySchedule.defaultWeekdays(count: 3)
    @Published var dayPeriod: GoalDayPeriod = .anytime
    @Published var usesWeeklyTime: Bool = false
    @Published var weeklyTime: Date = GoalWeeklyTime.date(minutes: GoalWeeklyTime.defaultMinutes) ?? Date()
    @Published var customUnitLabel: String  = ""
    @Published var executionTargetValue: Double = 1
    @Published var completionBasis: GoalCompletionBasis = .executions
    @Published var durationValue: Int       = 30
    @Published var durationUnit: TimeUnit   = .dias
    @Published var specificDates: [Date]    = []
    @Published var unidadesInfo : [UnidadesInfo] = []     // Información de unidades de Metas
    

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        amount > 0 &&
        executionTargetValue > 0 &&
        (completionBasis != .duration || durationValue > 0) &&
        (scheduleType != .weekly || (!selectedWeeklyDays.isEmpty && selectedWeeklyDays.count == weeklyDaysPerWeek)) &&
        (scheduleType != .weekly || !usesWeeklyTime || dayPeriod == .anytime) &&
        (scheduleType != .specificDates || specificDates.count == amount)
    }

    var effectiveWeeklyTimeMinutes: Int? {
        guard scheduleType == .weekly, usesWeeklyTime else { return nil }
        return GoalWeeklyTime.minutes(from: weeklyTime)
    }

    var executionTargetText: String {
        let number = executionTargetValue.rounded() == executionTargetValue
            ? String(Int(executionTargetValue))
            : executionTargetValue.formatted(.number.precision(.fractionLength(0...2)))
        let label = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return GoalsL10n.executionTarget(
            value: executionTargetValue,
            number: number,
            label: label
        )
    }

    func estimatedUnitCount(from referenceDate: Date = Date()) -> Int {
        guard completionBasis == .duration,
              let endDate = Calendar.current.date(
                byAdding: durationUnit.calendarComponent,
                value: durationValue,
                to: referenceDate
              ) else { return amount }

        if scheduleType == .weekly {
            return max(
                GoalWeeklySchedule.plannedCount(
                    from: referenceDate,
                    until: endDate,
                    weekdays: selectedWeeklyDays,
                    period: dayPeriod,
                    timeMinutes: effectiveWeeklyTimeMinutes
                ),
                1
            )
        }

        let calendar = Calendar.current
        var count = 0
        var cursor = referenceDate
        while cursor < endDate, count < 5_000 {
            count += 1
            guard let next = calendar.date(
                byAdding: unit.calendarComponent,
                value: frequency,
                to: cursor
            ), next > cursor else { break }
            cursor = next
        }
        return max(count, 1)
    }
    
    func getTextoForUNidades(number : Int) -> String {
        let label = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? GoalsL10n.unitNoun(count: number) : label
    }

    func syncSpecificDates() {
        if specificDates.count < amount {
            let calendar = Calendar.current
            let lastDate = specificDates.last ?? Date()
            for offset in 0..<(amount - specificDates.count) {
                specificDates.append(calendar.date(byAdding: .day, value: offset + 1, to: lastDate) ?? lastDate)
            }
        } else if specificDates.count > amount {
            specificDates.removeLast(specificDates.count - amount)
        }
    }

    func setWeeklyDayCount(_ count: Int) {
        let normalizedCount = min(max(count, 1), 7)
        weeklyDaysPerWeek = normalizedCount
        guard selectedWeeklyDays.count != normalizedCount else { return }
        selectedWeeklyDays = GoalWeeklySchedule.defaultWeekdays(count: normalizedCount)
    }

    func toggleWeeklyDay(_ weekday: GoalWeekday) {
        if selectedWeeklyDays.contains(weekday) {
            guard selectedWeeklyDays.count > 1 else { return }
            selectedWeeklyDays.remove(weekday)
        } else {
            selectedWeeklyDays.insert(weekday)
        }
        weeklyDaysPerWeek = selectedWeeklyDays.count
    }

    func setWeeklyTimeEnabled(_ isEnabled: Bool) {
        usesWeeklyTime = isEnabled
        if isEnabled {
            dayPeriod = .anytime
        }
    }
    
    
    init() {}
}

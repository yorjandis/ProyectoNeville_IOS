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
    @Published var dayPeriod: GoalDayPeriod = .anytime
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
        (scheduleType != .specificDates || specificDates.count == amount)
    }

    var executionTargetText: String {
        let number = executionTargetValue.rounded() == executionTargetValue
            ? String(Int(executionTargetValue))
            : executionTargetValue.formatted(.number.precision(.fractionLength(0...2)))
        let label = customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        if label.isEmpty {
            return executionTargetValue == 1 ? "Una ejecución" : "\(number) por ejecución"
        }
        return executionTargetValue == 1 ? "\(label) por ejecución" : "\(number) \(label) por ejecución"
    }

    func estimatedUnitCount(from referenceDate: Date = Date()) -> Int {
        guard completionBasis == .duration,
              let endDate = Calendar.current.date(
                byAdding: durationUnit.calendarComponent,
                value: durationValue,
                to: referenceDate
              ) else { return amount }

        let calendar = Calendar.current
        if scheduleType == .weekly {
            let days = max(calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: referenceDate),
                to: calendar.startOfDay(for: endDate)
            ).day ?? 0, 1)
            return max((days / 7 * weeklyDaysPerWeek) + min(days % 7, weeklyDaysPerWeek), 1)
        }

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
        return label.isEmpty ? (number == 1 ? "unidad" : "unidades") : label
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
    
    
    static let shared = CreateGoalViewModel()
    
    private init() {}
}

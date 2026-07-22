//
//  ArchivedGoal.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

import Foundation
import CoreData

extension ArchivedGoalEntity {

    var wrappedTitle: String {
        title ?? ""
    }

    var unitsArray: [ArchivedUnitEntity] {
        let set = units as? Set<ArchivedUnitEntity> ?? []
        return set.sorted { $0.index < $1.index }
    }

    var progressRatio: Double {
        guard totalUnits > 0 else { return 0 }
        let completed = unitsArray.filter { $0.status == UnitStatus.completed.rawValue ||
            $0.status == UnitStatus.lost.rawValue }.count
        return Double(completed) / Double(totalUnits)
    }

    var hasLostUnits: Bool {
        unitsArray.contains { $0.status == UnitStatus.lost.rawValue }
    }

    var completedUnitsText: String {
        let completed = unitsArray.filter { $0.status == UnitStatus.completed.rawValue }.count
        return "\(completed)/\(totalUnits)"
    }
    
    var lostUnitIndexes: [Int] {
            unitsArray
                .filter { $0.status == UnitStatus.lost.rawValue }
                .map { Int($0.index) - 1 }
        }
    
    //Obtiene el progreso real
    var completionRate: Double {

        let completed = unitsArray.filter {
            $0.status == UnitStatus.completed.rawValue
        }.count

        let progressed = unitsArray.filter {
            $0.status == UnitStatus.completed.rawValue ||
            $0.status == UnitStatus.lost.rawValue
        }.count

        guard progressed > 0 else { return 0 }

        let rate = Double(completed) / Double(progressed)
        return rate
    }

    @discardableResult
    func restoreAsActiveGoal(context: NSManagedObjectContext) throws -> GoalEntity {
        let activeGoal = GoalEntity(context: context)
        activeGoal.id = UUID()
        activeGoal.title = self.title
        activeGoal.descriptionText = self.descriptionText
        activeGoal.totalUnits = self.totalUnits
        activeGoal.unitType = self.unitType
        activeGoal.frequency = self.frequency
        activeGoal.scheduleType = self.scheduleType
        activeGoal.weeklyDaysPerWeek = self.weeklyDaysPerWeek
        activeGoal.weeklyDaysMask = self.weeklyDaysMask
        activeGoal.weeklyTimeMinutes = self.weeklyTimeMinutes
        activeGoal.dayPeriod = self.dayPeriod
        activeGoal.customUnitLabel = self.customUnitLabel
        activeGoal.executionTargetValue = self.executionTargetValue
        activeGoal.completionBasis = self.completionBasis
        activeGoal.durationValue = self.durationValue
        activeGoal.durationUnit = self.durationUnit
        activeGoal.isStarted = false
        activeGoal.startDate = Date()

        let unitDetails = unitsArray.map { unit in
            UnidadesInfo(
                name: unit.name ?? "Unidad \(unit.index)",
                info: unit.info ?? ""
            )
        }

        let dates = unitsArray.compactMap(\.startDate)
        activeGoal.generateUnits(
            DetallesUnidades: unitDetails,
            specificDates: self.scheduleType == GoalScheduleType.specificDates.rawValue ? dates : []
        )
        try context.save()
        return activeGoal
    }
    
}

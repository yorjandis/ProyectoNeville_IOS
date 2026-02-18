//
//  ArchivedGoal.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//

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
        let completed = unitsArray.filter { $0.status == UnitStatus.completed.rawValue }.count
        return Double(completed) / Double(totalUnits)
    }

    var hasLostUnits: Bool {
        unitsArray.contains { $0.status == UnitStatus.lost.rawValue }
    }

    var completedUnitsText: String {
        let completed = unitsArray.filter { $0.status == UnitStatus.completed.rawValue }.count
        return "\(completed)/\(totalUnits)"
    }
    
    
    
}

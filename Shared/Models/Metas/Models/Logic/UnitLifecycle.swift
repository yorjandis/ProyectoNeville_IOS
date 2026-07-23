//
//  UnitLifecyclw.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//FASE 5️⃣ – LÓGICA DE UNIDAD

import CoreData
import SwiftUI

extension UnitEntity {

    var unitStatus: UnitStatus {
        UnitStatus(rawValue: status ?? "") ?? .pending
    }

    //Determina si una unidad esta disponible para ser fichada
    func canBeCompleted(now: Date) -> Bool {
        guard goal?.isStarted == true,
              let startDate,
              let endDate else { return false }
        return unitStatus == .pending && now >= startDate && now <= endDate
    }

    //Marca una Unidad como fichada
    func markCompleted(context: NSManagedObjectContext) {
        guard canBeCompleted(now: Date()) else { return }
        
        let now = Date.now
        self.completedDate = now //Almacena el momento del fichaje
        
        status = UnitStatus.completed.rawValue
        goal?.recordStatsEvent(.unitCompleted, unit: self, date: now, context: context)
        try? context.save()
    }

    //Actualiza el estado de las unidades perdidas
    func updateLostIfNeeded(now: Date) {
        guard goal?.isStarted == true else { return }
        goal?.repairSchedulingConsistencyIfNeeded(now: now)

        if unitStatus == .pending, let endDate, now > endDate {
            status = UnitStatus.lost.rawValue
            goal?.recordStatsEvent(.unitLost, unit: self, date: now, context: managedObjectContext)
        }
    }
}


extension GoalEntity {

    //Calcula el progreso de una unidad: para barra de progreso
    var progressRatio: Double {
        guard totalUnits > 0 else { return 0.0 }

        let progressed = unitsSet.filter {
            $0.unitStatus == .completed || $0.unitStatus == .lost
        }.count

        let ratio = Double(progressed) / Double(totalUnits)

        // Asegurarse de que no sea NaN o infinito
        if ratio.isFinite {
            return ratio
        } else {
            return 0.0
        }
    }

    //Determina si todas las unidades de un objetivo han sido completadas
    var isCompleted: Bool {
        unitsSet.allSatisfy {
            $0.unitStatus != .pending
        }
    }
}

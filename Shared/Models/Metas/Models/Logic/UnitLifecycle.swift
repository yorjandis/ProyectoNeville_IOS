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
        unitStatus == .pending &&
        now >= startDate ?? Date.now &&
        now <= endDate ?? Date.now
    }

    //Marca una Unidad como fichada
    func markCompleted(context: NSManagedObjectContext) {
        guard canBeCompleted(now: Date()) else { return }
        
        self.completedDate = Date.now //Almacena el momento del fichaje
        
        status = UnitStatus.completed.rawValue
        try? context.save()
    }

    //Actualiza el estado de las unidades perdidas
    func updateLostIfNeeded(now: Date) {
        if unitStatus == .pending && now > endDate ?? Date.now {
            status = UnitStatus.lost.rawValue
        }
    }
}


extension GoalEntity {

    //Calcula el progreso de una unidad: para barra de progreso
    var progressRatio: Double {
        guard totalUnits > 0 else { return 0.0 }
        
        let completed = unitsArray.filter { $0.unitStatus == .completed || $0.unitStatus == .lost }.count
        
        let ratio = Double(completed) / Double(totalUnits)
        
        // Asegurarse de que no sea NaN o infinito
        if ratio.isFinite {
            return ratio
        } else {
            return 0.0
        }
    }

    //Determina si todas las unidades de un objetivo han sido completadas
    var isCompleted: Bool {
        unitsArray.allSatisfy {
            $0.unitStatus != .pending
        }
    }
}

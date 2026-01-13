//
//  GoalEntity+Core.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//Extensiones del Modelo Core Data:

import CoreData
import SwiftUI

extension GoalEntity {

    var wrappedTitle: String {
        title ?? ""
    }
    

    var timeUnit: TimeUnit {
        TimeUnit(rawValue: unitType ?? "dias") ?? .dias
    }

    var unitsArray: [UnitEntity] {
        let set = units as? Set<UnitEntity> ?? []
        return set.sorted { $0.index < $1.index }
    }
    
    var frequencyValue: Int {
        max(1, Int(frequency))
    }
}


//Crear las unidades de tiempo de un Objetivo
extension GoalEntity {

    //Inicia un Onjetivo y ficha la primera unidad
    func start() {
        guard !isStarted else { return }
        isStarted = true
        startDate = Date()
        
        // Genera todas las unidades
        generateUnits()
        
        // Marca automáticamente la primera unidad como completada
            if let firstUnit = unitsArray.first {
                firstUnit.status = UnitStatus.completed.rawValue
                firstUnit.completedDate = Date.now
                try? self.managedObjectContext?.save()
            }
    }

    
    //Genera todas las unidades de un Objetivo
    private func generateUnits() {
        guard let context = self.managedObjectContext else { return }

        let calendar = Calendar.current       // ✅ Aquí se define
        let now = Date()
        let baseStart = timeUnit.alignedStart(from: now)
        
        for index in 1...totalUnits {
            let unit = UnitEntity(context: context)
            unit.id = UUID()
            unit.index = Int32(index)
            unit.status = "pending"
            unit.unitType = self.unitType //Almacena el tipo de unidad: horas, dias, meses, años
            unit.note = ""
            unit.name = String(index) //Unidad 1, 2, 3, 4, ...
            unit.goal = self   // ✅ MISMO CONTEXTO
            
            let step = frequencyValue

            unit.startDate = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: (Int(index) - 1) * step,
                to: baseStart
            )

            unit.endDate = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: step,
                to: unit.startDate!
            )
            
            
        }
        
 
        
    }
}


//Borra un objetivo y todas sus unidades:
extension GoalEntity {

    //Elimina todas las unidades 
    func deleteGoal(context: NSManagedObjectContext) {
        // Si hubiera notificaciones o timers, cancelarlos
        // e.g., NotificationManager.cancel(for: self)

        context.delete(self)

        do {
            try context.save()
            print("Objetivo y sus unidades eliminados correctamente")
        } catch {
            context.rollback()
            print("Error al eliminar objetivo: \(error.localizedDescription)")
        }
    }
}


//Calcula el tiempo que resta para que la próxima unidad este disponible para marcar
/*
 ✅ Qué hace este código:
     •    Busca la siguiente unidad pendiente.
     •    Si ya se puede marcar, devuelve "Disponible ahora".
     •    Si todavía no se puede marcar, calcula la diferencia de tiempo usando Calendar y formatea el string según la unidad (horas, días, meses, años).
     •    Retorna nil si todas las unidades están completadas.
 */
extension GoalEntity {

    /// Retorna la siguiente unidad pendiente que se puede marcar
    var nextPendingUnit: UnitEntity? {
        unitsArray.first { $0.unitStatus == .pending && $0.startDate ?? Date() <= Date() }
    }

    /// Retorna un string con el tiempo restante hasta la próxima unidad
    func timeUntilNextUnit(now: Date) -> String? {
        guard let nextUnit = unitsArray.first(where: { $0.unitStatus == .pending }),
              let start = nextUnit.startDate else {
            return nil
        }

        if now >= start {
            return "Listo"
        }

        switch timeUnit {
        case .minutos:
            let seconds = start.timeIntervalSince(now)
            let minutes = Int(ceil(seconds / 60))
            return "Próxima unidad en \(minutes) min"
        case .horas:
            let seconds = start.timeIntervalSince(now)
            let minutes = Int(ceil(seconds / 60))
            return "Próxima unidad en \(minutes)min"

        case .dias:
            let seconds = start.timeIntervalSince(now)
            let hours = Int(seconds / 3600)
            let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
            
            var hour    : String = ""
            var minutes_temp : String = ""
            if hours != 0 {
                hour = "\(hours)hr y "
            }
            if minutes != 0 {
                minutes_temp = "\(minutes)min"
            }
            
            return "Próxima unidad en \(hour)\(minutes_temp)"
            

        case .meses:
            let diff = Calendar.current.dateComponents([.day, .hour], from: now, to: start)
            var day     : String = ""
            var hour    : String = ""
            if diff.day != 0 {
                day = "\(diff.day ?? 0)\((diff.day ?? 0) == 1 ? "día" : "días") y "
            }
            if diff.hour != 0 {
                hour = "\(diff.hour ?? 0)hr"
            }
            
            return "Próxima unidad en \(day)\(hour)"
            
            
            

        case .años:
            let diff = Calendar.current.dateComponents([.month, .day, .hour], from: now, to: start)
            var month   : String = ""
            var day     : String = ""
            var hour    : String = ""
            
            if diff.month != 0 {
                month = "\(diff.month ?? 0)\((diff.month ?? 0) == 1 ? "mes" : "meses") y "
            }
            if diff.day != 0 {
                day = "\(diff.day ?? 0)\((diff.day ?? 0) == 1 ? "día" : "días") y "
            }
            if diff.hour != 0 {
                hour = "\(diff.hour ?? 0)hr"
            }
            
            return "Próxima unidad en \(month) \(day) \(hour)"
        }
    }
    
    
    
    func nextExpirationDate(from now: Date) -> Date? {
        guard let unit = nextPendingUnit,
              let start = unit.startDate else { return nil }

        return Calendar.current.date(
            byAdding: timeUnit.calendarComponent,
            value: frequencyValue,
            to: start
        )
    }
    
    
    
}





//Actualiza el título y la descripción de un objetivo:
extension GoalEntity {
     func update(title: String, description: String) throws  {
         self.title = title
         self.descriptionText = description
         try self.managedObjectContext?.save()
    }
}

//Normalización temporal para horas, dias, meses y años:
/*
 •    Horas a las 10:15 → primera unidad: 10:15–11:00
 •    segunda: 11:00–12:00
 •    Días → alineado a medianoche
 •    Meses → día 1
 •    Años → 1 de enero
 */
extension TimeUnit {

        func alignedStart(from date: Date) -> Date {
            let calendar = Calendar.current

            switch self {
            case .minutos:
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                return calendar.date(from: components)!
                
            case .horas:
                // Alinea a la hora actual sin añadir nada
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
                return calendar.date(from: components)!

            case .dias:
                // Inicio del día actual
                return calendar.startOfDay(for: date)

            case .meses:
                // Inicio del mes actual
                let comps = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: comps)!

            case .años:
                // Inicio del año actual
                let comps = calendar.dateComponents([.year], from: date)
                return calendar.date(from: comps)!
            }
        }
}


//Saber si un Objetivo tiene unidades perdidas:
extension GoalEntity {

    /// Indica si el objetivo tiene al menos una unidad perdida
    var hasLostUnits: Bool {
        unitsArray.contains { $0.unitStatus == .lost }
    }
}

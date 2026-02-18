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


//Inicia una Meta personalizada/Preestablecida
extension GoalEntity {

    //Inicia un Objetivo y ficha la primera unidad
    func start() {
        guard !isStarted else { return }
        

        isStarted = true
        startDate = Date()
        
        
        // Marca automáticamente la primera unidad como completada
            if let firstUnit = unitsArray.first {
                firstUnit.status = UnitStatus.completed.rawValue
                firstUnit.completedDate = Date()
            }

    }
    
    //Crear e inicia la Meta Para un Programa Preestablecido:
    func startProgramaPreestablecido(unitNotes : [UnidadesInfo] = []) {
        guard !isStarted else { return }
        
        guard managedObjectContext != nil else { return }
        
        isStarted = true
        startDate = Date()
        
        // Genera todas las unidades
        generateUnits(DetallesUnidades: unitNotes)
        

    }

    
    func generateUnits(DetallesUnidades: [UnidadesInfo] = []) {
        guard let context = self.managedObjectContext else { return }

        let calendar = Calendar.current
        let now = Date()
        let baseStart = timeUnit.alignedStart(from: now)
        
        let step = frequencyValue
        
        for index in 1...Int(totalUnits) {
            let unit = UnitEntity(context: context)
            unit.id = UUID()
            unit.index = Int32(index)
            unit.status = "pending"
            unit.unitType = self.unitType
            unit.goal = self
            
            // 👇 Lógica de nombre y nota
            if index - 1 < DetallesUnidades.count {
                let info = DetallesUnidades[index - 1]
                unit.name = info.name
                unit.note = info.note
            } else {
                // Lógica por defecto
                unit.name = "Unidad \(index)"
                unit.note = ""
            }

            // 👇 Fechas
            if let startDate = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: (index - 1) * step,
                to: baseStart
            ) {
                unit.startDate = startDate
                unit.endDate = calendar.date(
                    byAdding: timeUnit.calendarComponent,
                    value: step,
                    to: startDate
                )
            }
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
            msg("Objetivo y sus unidades eliminados correctamente")
        } catch {
            context.rollback()
            msg("Error al eliminar objetivo: \(error.localizedDescription)")
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


//Archiva una Meta Completada!
extension GoalEntity {

    func archive(context: NSManagedObjectContext) throws  {
            guard isCompleted else { return }
            guard let goalID = self.id else { return }
            
            // 🔎 1. Comprobar si ya existe en el histórico
            let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", goalID as CVarArg)
            request.fetchLimit = 1
            
            let existing = try context.fetch(request)
            
            guard existing.isEmpty else {
                msg("⚠️ La meta ya está archivada")
                return
            }
            
            // 🟣 2. Crear meta archivada
            let archivedGoal = ArchivedGoalEntity(context: context)
            archivedGoal.id = goalID
            archivedGoal.title = self.title
            archivedGoal.descriptionText = self.descriptionText
            archivedGoal.totalUnits = self.totalUnits
            archivedGoal.unitType = self.unitType
            archivedGoal.frequency = self.frequency
            archivedGoal.completionDate = Date()
            
            // 🟣 3. Copiar unidades
            for unit in unitsArray {
                let archivedUnit = ArchivedUnitEntity(context: context)
                archivedUnit.id = unit.id
                archivedUnit.name = unit.name
                archivedUnit.index = unit.index
                archivedUnit.status = unit.status
                archivedUnit.startDate = unit.startDate
                archivedUnit.endDate = unit.endDate
                archivedUnit.completedDate = unit.completedDate
                archivedUnit.note = unit.note
                archivedUnit.goal = archivedGoal
            }
            
            try context.save()
        }
    
}

//Actualizar una meta archivada

extension GoalEntity {
    
    func updateArchivedVersion(context: NSManagedObjectContext) throws {
        guard let goalID = self.id else { return }
        
        // 🔎 1. Buscar meta archivada
        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", goalID as CVarArg)
        request.fetchLimit = 1
        
        guard let archivedGoal = try context.fetch(request).first else {
            msg("⚠️ No existe versión archivada para actualizar")
            return
        }
        
        // 🟣 2. Actualizar propiedades principales
        archivedGoal.title = self.title
        archivedGoal.descriptionText = self.descriptionText
        archivedGoal.totalUnits = self.totalUnits
        archivedGoal.unitType = self.unitType
        archivedGoal.frequency = self.frequency
        archivedGoal.completionDate = Date()
        
        // 🟣 3. Eliminar unidades archivadas antiguas
        if let oldUnits = archivedGoal.units as? Set<ArchivedUnitEntity> {
            for unit in oldUnits {
                context.delete(unit)
            }
        }
        
        // 🟣 4. Copiar nuevamente las unidades actuales
        for unit in unitsArray {
            let archivedUnit = ArchivedUnitEntity(context: context)
            archivedUnit.id = unit.id
            archivedUnit.index = unit.index
            archivedUnit.status = unit.status
            archivedUnit.startDate = unit.startDate
            archivedUnit.endDate = unit.endDate
            archivedUnit.completedDate = unit.completedDate
            archivedUnit.note = unit.note
            archivedUnit.goal = archivedGoal
        }
        
        try context.save()
    }
}

//Saber si la unidad esta archivada:
extension  GoalEntity {
    
    static func isArchived(id: UUID, context : NSManagedObjectContext)  -> Bool {
        
        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        do{
            let result =  try context.fetch(request)
            return !result.isEmpty
        }catch{
            return false
        }
    }
    
    
}

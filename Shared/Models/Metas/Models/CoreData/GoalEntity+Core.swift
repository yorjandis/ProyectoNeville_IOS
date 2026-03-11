//
//  GoalEntity+Core.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//Extensiones del Modelo Core Data:

/*
🟢 Reglas de negocio Yor:
 Si alineas al calendario, y el usuario inicia una meta horaria a las 10:37, la unidad 1 será:
   •    10:00 - 11:00
 Eso significa que completas una unidad cuyo intervalo empezó antes del inicio real de la meta.

 Eso puede ser correcto si tu regla es:

 “la meta entra en la unidad natural actual”.

 Por ejemplo:
     •    si empieza a las 10:37, entra en la franja de 10:00–11:00
 */




import CoreData
import SwiftUI

extension GoalEntity {

    var wrappedTitle: String {
        title ?? ""
    }
    

    var timeUnit: TimeUnit {
        TimeUnit(rawValue: unitType ?? "dias") ?? .dias
    }

    var unitsSet: Set<UnitEntity> {
        units as? Set<UnitEntity> ?? []
    }

    var unitsArray: [UnitEntity] {
        unitsSet.sorted { $0.index < $1.index }
    }
    
    var frequencyValue: Int {
        max(1, Int(frequency))
    }
}


//Inicia una Meta personalizada/Preestablecida
extension GoalEntity {
    
    private func rescheduleUnits(from referenceDate: Date, alignToCalendar: Bool = true) {
        let calendar = Calendar.current
        let baseStart = alignToCalendar
            ? timeUnit.alignedStart(from: referenceDate)
            : referenceDate

        let step = frequencyValue

        for unit in unitsArray {
            let index = max(Int(unit.index) - 1, 0)

            guard let startDate = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: index * step,
                to: baseStart
            ) else {
                continue
            }

            unit.startDate = startDate
            unit.endDate = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: step,
                to: startDate
            )
        }
    }

    //Inicia un Objetivo y ficha la primera unidad
    func start() {
        guard !isStarted else { return }

        isStarted = true
        let now = Date()
        startDate = now

        rescheduleUnits(from: now, alignToCalendar: true)

        if let firstUnit = unitsArray.first {
            firstUnit.status = UnitStatus.completed.rawValue
            firstUnit.completedDate = now
        }

        if let context = managedObjectContext, context.hasChanges {
            try? context.save()
        }
    }
    
    //Crear e inicia la Meta Para un Programa Preestablecido:
    func startProgramaPreestablecido(unitNotes: [UnidadesInfo] = []) {
        guard !isStarted else { return }
        guard managedObjectContext != nil else { return }

        isStarted = true
        let now = Date()
        startDate = now

        generateUnits(DetallesUnidades: unitNotes)
        rescheduleUnits(from: now, alignToCalendar: true)

        if let context = managedObjectContext, context.hasChanges {
            try? context.save()
        }
    }

    func generateUnits(DetallesUnidades: [UnidadesInfo] = []) {
        guard let context = self.managedObjectContext else { return }

        for index in 1...Int(totalUnits) {
            let unit = UnitEntity(context: context)
            unit.id = UUID()
            unit.index = Int32(index)
            unit.status = UnitStatus.pending.rawValue
            unit.unitType = self.unitType
            unit.goal = self

            if index - 1 < DetallesUnidades.count {
                let info = DetallesUnidades[index - 1]
                unit.name = info.name
                unit.info = info.info
            } else {
                unit.name = "Unidad \(index)"
                unit.info = ""
            }

            // No asignar fechas aquí
            unit.startDate = nil
            unit.endDate = nil
        }
    }
    
    /*
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
                 unit.info = info.info
             } else {
                 // Lógica por defecto
                 unit.name = "Unidad \(index)"
                 unit.info = ""
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
     */
    
    
    
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

    private func firstPendingUnit(availableAt now: Date?) -> UnitEntity? {
        unitsSet
            .filter { unit in
                guard unit.unitStatus == .pending else { return false }
                guard let now else { return true }
                return (unit.startDate ?? now) <= now
            }
            .min(by: { $0.index < $1.index })
    }

    /// Retorna la siguiente unidad pendiente que se puede marcar
    var nextPendingUnit: UnitEntity? {
        firstPendingUnit(availableAt: Date())
    }

    /// Retorna un string con el tiempo restante hasta la próxima unidad
    func timeUntilNextUnit(now: Date) -> String? {
        guard isStarted else { return nil }

        guard let nextUnit = firstPendingUnit(availableAt: nil),
              let start = nextUnit.startDate else {
            return nil
        }

        if now >= start {
            return "Listo"
        }
        
        let secondsRemaining = Int(ceil(start.timeIntervalSince(now)))
        if secondsRemaining < 60 {
            return "Próxima unidad en \(max(secondsRemaining, 0))s"
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
            
            var hour: String = ""
            var minutesTemp: String = ""
            if hours != 0 {
                hour = "\(hours)hr y "
            }
            if minutes != 0 {
                minutesTemp = "\(minutes)min"
            }
            
            return "Próxima unidad en \(hour)\(minutesTemp)"

        case .meses:
            let diff = Calendar.current.dateComponents([.day, .hour], from: now, to: start)
            var day: String = ""
            var hour: String = ""
            if diff.day != 0 {
                day = "\(diff.day ?? 0)\((diff.day ?? 0) == 1 ? "día" : "días") y "
            }
            if diff.hour != 0 {
                hour = "\(diff.hour ?? 0)hr"
            }
            
            return "Próxima unidad en \(day)\(hour)"

        case .años:
            let diff = Calendar.current.dateComponents([.month, .day, .hour], from: now, to: start)
            var month: String = ""
            var day: String = ""
            var hour: String = ""
            
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

    @discardableResult
    func refreshLostUnits(now: Date) -> Bool {
        guard isStarted else { return false }

        var didChange = false
        for unit in unitsSet {
            guard unit.unitStatus == .pending else { continue }
            if now > (unit.endDate ?? Date.now) {
                unit.status = UnitStatus.lost.rawValue
                didChange = true
            }
        }
        return didChange
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
            let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return calendar.date(from: comps) ?? date

        case .horas:
            let comps = calendar.dateComponents([.year, .month, .day, .hour], from: date)
            return calendar.date(from: comps) ?? date

        case .dias:
            return calendar.startOfDay(for: date)

        case .meses:
            let comps = calendar.dateComponents([.year, .month], from: date)
            return calendar.date(from: comps) ?? date

        case .años:
            let comps = calendar.dateComponents([.year], from: date)
            return calendar.date(from: comps) ?? date
        }
    }
}


//Saber si un Objetivo tiene unidades perdidas:
extension GoalEntity {

    /// Indica si el objetivo tiene al menos una unidad perdida
    var hasLostUnits: Bool {
        unitsSet.contains { $0.unitStatus == .lost }
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
                archivedUnit.info = unit.info
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


//Para determinar las posiciones de las unidades perdidas: Para señalizar esto en la barra de progreso
extension GoalEntity {

    /// Índices de unidades perdidas (0...n)
    var lostUnitIndexes: [Int] {
        unitsSet
            .filter { $0.unitStatus == .lost }
            .map { Int($0.index) - 1 }
            .sorted()
    }
}

//Para Ordenar las targetas de Metas por urgencia: Primero las que requieran fichaje inmediato
extension GoalEntity {

    /// Fecha relevante para ordenar metas por urgencia
    var urgencyDate: Date? {

        // Si hay una unidad que ya se puede completar
        if let unit = nextPendingUnit {
            return unit.endDate
        }

        // Si no hay unidad disponible aún, tomar la próxima futura
        if let futureUnit = firstPendingUnit(availableAt: nil) {
            return futureUnit.startDate
        }

        return nil
    }
    //Comparador de Urgencia:
    static func urgencySort(_ g1: GoalEntity, _ g2: GoalEntity) -> Bool {

            // Completadas siempre al final
            if g1.isCompleted && !g2.isCompleted { return false }
            if !g1.isCompleted && g2.isCompleted { return true }

            let d1 = g1.urgencyDate ?? .distantFuture
            let d2 = g2.urgencyDate ?? .distantFuture

            if d1 != d2 {
                return d1 < d2
            }

            // fallback: prioridad temporal
            let u1 = TimeUnit(rawValue: g1.unitType ?? "")?.priority ?? 99
            let u2 = TimeUnit(rawValue: g2.unitType ?? "")?.priority ?? 99

            return u1 < u2
        }
    
}

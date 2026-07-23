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

enum GoalStatsEventType: String {
    case goalStarted
    case unitCompleted
    case unitLost
    case goalArchived
}

extension GoalEntity {

    enum NextUnitAvailability {
        case notStarted
        case ready
        case scheduled(Date)
        case finished
    }

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

    var goalScheduleType: GoalScheduleType {
        GoalScheduleType(rawValue: scheduleType ?? "") ?? .interval
    }

    var goalDayPeriod: GoalDayPeriod {
        GoalSchedulingRules.normalizedDayPeriod(
            scheduleType: goalScheduleType,
            intervalUnit: timeUnit,
            requestedPeriod: GoalDayPeriod(rawValue: dayPeriod ?? "") ?? .anytime,
            weeklyTimeMinutes: GoalWeeklyTime.normalized(Int(weeklyTimeMinutes))
        )
    }

    var weeklyDaysValue: Int {
        min(max(Int(weeklyDaysPerWeek), 1), 7)
    }

    var selectedWeeklyDays: Set<GoalWeekday> {
        GoalWeeklySchedule.weekdays(from: weeklyDaysMask)
    }

    var weeklyTimeMinutesValue: Int? {
        guard goalScheduleType == .weekly else { return nil }
        return GoalWeeklyTime.normalized(Int(weeklyTimeMinutes))
    }

    func schedulingWindow(
        on day: Date,
        calendar: Calendar = .current
    ) -> (start: Date, end: Date)? {
        if let minutes = weeklyTimeMinutesValue {
            return GoalWeeklyTime.window(on: day, minutes: minutes, calendar: calendar)
        }
        return goalDayPeriod.window(on: day, calendar: calendar)
    }

    func effectiveWeeklyDays(from referenceDate: Date) -> Set<GoalWeekday> {
        let explicitDays = selectedWeeklyDays
        guard explicitDays.isEmpty else { return explicitDays }
        return GoalWeeklySchedule.legacyWeekdays(
            count: weeklyDaysValue,
            anchoredAt: referenceDate
        )
    }

    var unitLabel: String {
        let value = customUnitLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? GoalsL10n.unitNoun(count: 1) : value
    }

    var goalCompletionBasis: GoalCompletionBasis {
        GoalCompletionBasis(rawValue: completionBasis ?? "") ?? .executions
    }

    var goalDurationUnit: TimeUnit {
        TimeUnit(rawValue: durationUnit ?? "") ?? .dias
    }

    var durationValueNumber: Int {
        max(Int(durationValue), 1)
    }

    var executionValueNumber: Double {
        executionTargetValue > 0 ? executionTargetValue : 1
    }

    var executionTargetText: String {
        let value = executionValueNumber
        let number = value.rounded() == value
            ? String(Int(value))
            : value.formatted(.number.precision(.fractionLength(0...2)))
        let label = customUnitLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return GoalsL10n.executionTarget(value: value, number: number, label: label)
    }

    var scheduleSummary: String {
        let cadence: String
        switch goalScheduleType {
        case .interval:
            cadence = GoalsL10n.intervalCadence(frequency: frequencyValue, unit: timeUnit)
        case .weekly:
            let weeklyCadence = GoalsL10n.weeklyCadence(days: weeklyDaysValue)
            let weekdays = selectedWeeklyDays
            cadence = weekdays.isEmpty
                ? weeklyCadence
                : "\(weeklyCadence) · \(GoalWeeklySchedule.summary(for: weekdays))"
        case .specificDates:
            cadence = GoalsL10n.specificDatesCadence()
        }
        if goalScheduleType == .weekly, let minutes = weeklyTimeMinutesValue {
            return GoalsL10n.addingWeeklyTime(cadence, minutes: minutes)
        }
        return GoalsL10n.addingPeriod(cadence, period: goalDayPeriod)
    }

    var planSummary: String {
        let ending: String
        switch goalCompletionBasis {
        case .executions:
            ending = GoalsL10n.executionCount(Int(totalUnits))
        case .duration:
            ending = GoalsL10n.duration(value: durationValueNumber, unit: goalDurationUnit)
        }
        return GoalsL10n.format(
            "goals.dynamic.plan_summary",
            fallback: "{0} · {1} · {2}",
            executionTargetText,
            scheduleSummary,
            ending
        )
    }

    func durationEndDate(from referenceDate: Date) -> Date? {
        guard goalCompletionBasis == .duration else { return nil }
        return Calendar.current.date(
            byAdding: goalDurationUnit.calendarComponent,
            value: durationValueNumber,
            to: referenceDate
        )
    }

    /// Calcula las oportunidades que caben realmente dentro de la duración.
    /// Ejemplo: 30 días a 5 días/semana = 22 ejecuciones.
    func plannedUnitCount(from referenceDate: Date) -> Int {
        guard goalCompletionBasis == .duration,
              let endDate = durationEndDate(from: referenceDate) else {
            return max(Int(totalUnits), 1)
        }

        let calendar = Calendar.current
        let maximumUnits = 5_000

        switch goalScheduleType {
        case .specificDates:
            return max(Int(totalUnits), 1)

        case .weekly:
            var selectionReference = referenceDate
            let referenceDay = calendar.startOfDay(for: referenceDate)
            if let window = schedulingWindow(on: referenceDay), referenceDate > window.end {
                selectionReference = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
            }
            let count = GoalWeeklySchedule.plannedCount(
                from: referenceDate,
                until: endDate,
                weekdays: effectiveWeeklyDays(from: selectionReference),
                period: goalDayPeriod,
                timeMinutes: weeklyTimeMinutesValue,
                maximum: maximumUnits,
                calendar: calendar
            )
            return min(max(count, 1), maximumUnits)

        case .interval:
            var count = 0
            var cursor = referenceDate
            while cursor < endDate, count < maximumUnits {
                count += 1
                guard let next = calendar.date(
                    byAdding: timeUnit.calendarComponent,
                    value: frequencyValue,
                    to: cursor
                ), next > cursor else { break }
                cursor = next
            }
            return max(count, 1)
        }
    }
}


//Inicia una Meta personalizada/Preestablecida
extension GoalEntity {
    
    private func applyWindow(start: Date, defaultEnd: Date) -> (Date, Date) {
        guard let periodWindow = schedulingWindow(on: start) else {
            return (start, defaultEnd)
        }
        return (periodWindow.start, periodWindow.end)
    }

    private func rescheduleUnits(from referenceDate: Date, alignToCalendar: Bool = true) {
        let calendar = Calendar.current

        if goalScheduleType == .specificDates {
            for unit in unitsArray {
                guard let scheduledDate = unit.startDate else { continue }
                let dayStart = calendar.startOfDay(for: scheduledDate)
                let defaultEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let window = applyWindow(start: dayStart, defaultEnd: defaultEnd)
                unit.startDate = window.0
                unit.endDate = window.1
            }
            return
        }

        if goalScheduleType == .weekly {
            var selectionReference = referenceDate
            let referenceDay = calendar.startOfDay(for: referenceDate)
            if let todayWindow = schedulingWindow(on: referenceDay), referenceDate > todayWindow.end {
                selectionReference = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
            }
            let scheduledDays = GoalWeeklySchedule.scheduledDays(
                count: unitsArray.count,
                from: referenceDate,
                weekdays: effectiveWeeklyDays(from: selectionReference),
                period: goalDayPeriod,
                timeMinutes: weeklyTimeMinutesValue,
                calendar: calendar
            )
            for (unit, scheduledDay) in zip(unitsArray, scheduledDays) {
                guard let defaultEnd = calendar.date(byAdding: .day, value: 1, to: scheduledDay) else { continue }
                let window = applyWindow(start: scheduledDay, defaultEnd: defaultEnd)
                unit.startDate = window.0
                unit.endDate = window.1
            }
            return
        }

        var scheduleReference = referenceDate
        if let todayWindow = goalDayPeriod.window(on: referenceDate), referenceDate > todayWindow.end {
            scheduleReference = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        }
        let baseStart = alignToCalendar
            ? timeUnit.alignedStart(from: scheduleReference)
            : scheduleReference

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

            let defaultEnd = calendar.date(
                byAdding: timeUnit.calendarComponent,
                value: step,
                to: startDate
            ) ?? startDate
            let window = applyWindow(start: startDate, defaultEnd: defaultEnd)
            unit.startDate = window.0
            unit.endDate = window.1
        }
    }

    //Inicia un Objetivo y ficha la primera unidad
    func start() {
        guard !isStarted else { return }

        let now = Date()
        repairSchedulingConsistencyIfNeeded(now: now)
        ensurePlannedUnitCount(from: now)
        isStarted = true
        startDate = now

        rescheduleUnits(from: now, alignToCalendar: true)

        // Conserva el comportamiento histórico de las metas por intervalo. En
        // calendarios semanales o explícitos, iniciar no equivale a ejecutar.
        if goalScheduleType == .interval,
           goalCompletionBasis == .executions,
           goalDayPeriod == .anytime,
           timeUnit != .semanas,
           let firstUnit = unitsArray.first {
            firstUnit.status = UnitStatus.completed.rawValue
            firstUnit.completedDate = now
            recordStatsEvent(.unitCompleted, unit: firstUnit, date: now, context: managedObjectContext)
        }

        recordStatsEvent(.goalStarted, date: now, context: managedObjectContext)

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
        repairSchedulingConsistencyIfNeeded(now: now)
        startDate = now

        generateUnits(DetallesUnidades: unitNotes)
        rescheduleUnits(from: now, alignToCalendar: true)
        recordStatsEvent(.goalStarted, date: now, context: managedObjectContext)

        if let context = managedObjectContext, context.hasChanges {
            try? context.save()
        }
    }

    func generateUnits(DetallesUnidades: [UnidadesInfo] = [], specificDates: [Date] = []) {
        guard let context = self.managedObjectContext else { return }
        guard totalUnits > 0 else { return }

        let existingIndexes = Set(unitsArray.map { Int($0.index) })

        for index in 1...Int(totalUnits) {
            guard !existingIndexes.contains(index) else { continue }
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
                if executionValueNumber == 1 {
                    let customLabel = customUnitLabel?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    unit.name = customLabel.isEmpty
                        ? "Unidad \(index)"
                        : "\(customLabel.prefix(1).uppercased())\(customLabel.dropFirst()) \(index)"
                } else {
                    let number = executionValueNumber.rounded() == executionValueNumber
                        ? String(Int(executionValueNumber))
                        : executionValueNumber.formatted(
                            .number.precision(.fractionLength(0...2))
                        )
                    let customLabel = customUnitLabel?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let target = customLabel.isEmpty ? number : "\(number) \(customLabel)"
                    unit.name = "\(target) · \(index)"
                }
                unit.info = ""
            }

            if index - 1 < specificDates.count {
                let dayStart = Calendar.current.startOfDay(for: specificDates[index - 1])
                let defaultEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                let window = applyWindow(start: dayStart, defaultEnd: defaultEnd)
                unit.startDate = window.0
                unit.endDate = window.1
            } else {
                unit.startDate = nil
                unit.endDate = nil
            }
        }
    }

    private func ensurePlannedUnitCount(from referenceDate: Date) {
        guard goalCompletionBasis == .duration, let context = managedObjectContext else { return }
        let expectedCount = plannedUnitCount(from: referenceDate)

        for unit in unitsArray where Int(unit.index) > expectedCount {
            context.delete(unit)
        }
        totalUnits = Int32(expectedCount)
        generateUnits()
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
                guard let start = unit.startDate, let end = unit.endDate else { return false }
                return start <= now && now <= end
            }
            .min { lhs, rhs in
                let leftDate = lhs.startDate ?? .distantFuture
                let rightDate = rhs.startDate ?? .distantFuture
                return leftDate == rightDate ? lhs.index < rhs.index : leftDate < rightDate
            }
    }

    /// Retorna la siguiente unidad pendiente que se puede marcar
    var nextPendingUnit: UnitEntity? {
        firstPendingUnit(availableAt: Date())
    }

    func nextUnitAvailability(now: Date) -> NextUnitAvailability {
        guard isStarted else { return .notStarted }
        guard let nextUnit = firstPendingUnit(availableAt: nil),
              let start = nextUnit.startDate else {
            return .finished
        }
        return now >= start ? .ready : .scheduled(start)
    }

    func isNextUnitReady(now: Date) -> Bool {
        if case .ready = nextUnitAvailability(now: now) {
            return true
        }
        return false
    }

    /// Retorna un string con el tiempo restante hasta la próxima unidad
    func timeUntilNextUnit(now: Date) -> String? {
        switch nextUnitAvailability(now: now) {
        case .notStarted, .finished:
            return nil
        case .ready:
            return L10n.string("goal.next_unit.ready", fallback: "Listo")
        case .scheduled(let start):
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = AppLanguage.current.locale
            formatter.dateTimeStyle = .numeric
            formatter.unitsStyle = .full
            return formatter.localizedString(for: start, relativeTo: now)
        }
    }

    @discardableResult
    func refreshLostUnits(now: Date) -> Bool {
        guard isStarted else { return false }

        var didChange = repairSchedulingConsistencyIfNeeded(now: now)
        for unit in unitsSet {
            guard unit.unitStatus == .pending else { continue }
            if now > (unit.endDate ?? Date.now) {
                unit.status = UnitStatus.lost.rawValue
                recordStatsEvent(.unitLost, unit: unit, date: now, context: managedObjectContext)
                didChange = true
            }
        }
        return didChange
    }

    func nextExpirationDate(from now: Date) -> Date? {
        nextPendingUnit?.endDate
    }
}





//Actualiza el título y la descripción de un objetivo:
extension GoalEntity {
     func update(title: String, description: String) throws  {
         self.title = title
         self.descriptionText = description
         try self.managedObjectContext?.save()
     }

    func updateSchedulingMetadata(
        unitLabel newLabel: String,
        dayPeriod newPeriod: GoalDayPeriod,
        weeklyTimeMinutes newWeeklyTimeMinutes: Int? = nil,
        weeklyDays newWeeklyDays: Set<GoalWeekday>? = nil,
        referenceDate: Date = Date()
    ) {
        let oldLabel = unitLabel
        let oldPeriod = goalDayPeriod
        let oldWeeklyTime = weeklyTimeMinutesValue
        let oldWeeklyDays = effectiveWeeklyDays(from: referenceDate)
        let storedPeriod = GoalDayPeriod(rawValue: dayPeriod ?? "") ?? .anytime
        let cleanLabel = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedWeeklyTime = goalScheduleType == .weekly
            ? GoalWeeklyTime.normalized(newWeeklyTimeMinutes)
            : nil
        let normalizedWeeklyDays: Set<GoalWeekday>? = {
            guard goalScheduleType == .weekly, let newWeeklyDays else { return nil }
            return newWeeklyDays.isEmpty ? oldWeeklyDays : newWeeklyDays
        }()
        let normalizedPeriod = GoalSchedulingRules.normalizedDayPeriod(
            scheduleType: goalScheduleType,
            intervalUnit: timeUnit,
            requestedPeriod: newPeriod,
            weeklyTimeMinutes: normalizedWeeklyTime
        )
        customUnitLabel = cleanLabel
        if let normalizedWeeklyDays {
            weeklyDaysMask = GoalWeeklySchedule.mask(for: normalizedWeeklyDays)
            weeklyDaysPerWeek = Int16(normalizedWeeklyDays.count)
        }
        weeklyTimeMinutes = Int32(normalizedWeeklyTime ?? GoalWeeklyTime.disabledMinutes)
        dayPeriod = normalizedPeriod.rawValue
        let weeklyScheduleChanged = goalScheduleType == .weekly
            && (
                storedPeriod != normalizedPeriod
                || oldPeriod != goalDayPeriod
                || oldWeeklyTime != normalizedWeeklyTime
                || oldWeeklyDays != effectiveWeeklyDays(from: referenceDate)
            )
        let intervalScheduleChanged = goalScheduleType == .interval
            && storedPeriod != normalizedPeriod

        for unit in unitsArray {
            let defaultOldName = "\(oldLabel.prefix(1).uppercased())\(oldLabel.dropFirst()) \(unit.index)"
            let index = Int(unit.index)
            let localizedOldName = GoalsL10n.unitDisplayName(nil, index: index)
            if unit.name == defaultOldName
                || unit.name == "Unidad \(unit.index)"
                || unit.name == "Unit \(unit.index)"
                || unit.name == "第 \(unit.index) 次"
                || unit.name == "执行项 \(unit.index)"
                || unit.name == localizedOldName {
                unit.name = cleanLabel.isEmpty
                    ? "Unidad \(unit.index)"
                    : "\(cleanLabel.prefix(1).uppercased())\(cleanLabel.dropFirst()) \(unit.index)"
            }

            if weeklyScheduleChanged || intervalScheduleChanged { continue }
            guard unit.unitStatus == .pending, let currentStart = unit.startDate else { continue }
            let calendar = Calendar.current
            let baseStart: Date
            let defaultEnd: Date
            if goalScheduleType == .weekly || goalScheduleType == .specificDates {
                baseStart = calendar.startOfDay(for: currentStart)
                defaultEnd = calendar.date(byAdding: .day, value: 1, to: baseStart) ?? baseStart
            } else {
                baseStart = timeUnit.alignedStart(from: currentStart)
                defaultEnd = calendar.date(
                    byAdding: timeUnit.calendarComponent,
                    value: frequencyValue,
                    to: baseStart
                ) ?? baseStart
            }

            if let window = schedulingWindow(on: baseStart) {
                unit.startDate = window.start
                unit.endDate = window.end
            } else {
                unit.startDate = baseStart
                unit.endDate = defaultEnd
            }
        }

        if weeklyScheduleChanged {
            let calendar = Calendar.current
            let pendingUnits = unitsArray.filter { $0.unitStatus == .pending }
            let scheduledDays = GoalWeeklySchedule.scheduledDays(
                count: pendingUnits.count,
                from: referenceDate,
                weekdays: effectiveWeeklyDays(from: referenceDate),
                period: goalDayPeriod,
                timeMinutes: weeklyTimeMinutesValue,
                calendar: calendar
            )
            for (unit, scheduledDay) in zip(pendingUnits, scheduledDays) {
                let defaultEnd = calendar.date(byAdding: .day, value: 1, to: scheduledDay) ?? scheduledDay
                let window = applyWindow(start: scheduledDay, defaultEnd: defaultEnd)
                unit.startDate = window.0
                unit.endDate = window.1
            }
        } else if intervalScheduleChanged {
            let calendar = Calendar.current
            let pendingUnits = unitsArray.filter { $0.unitStatus == .pending }
            let baseStart = timeUnit.alignedStart(from: referenceDate)
            for (offset, unit) in pendingUnits.enumerated() {
                guard let start = calendar.date(
                    byAdding: timeUnit.calendarComponent,
                    value: offset * frequencyValue,
                    to: baseStart
                ) else { continue }
                let defaultEnd = calendar.date(
                    byAdding: timeUnit.calendarComponent,
                    value: frequencyValue,
                    to: start
                ) ?? start
                let window = applyWindow(start: start, defaultEnd: defaultEnd)
                unit.startDate = window.0
                unit.endDate = window.1
            }
        }
    }

    @discardableResult
    func repairSchedulingConsistencyIfNeeded(now: Date = Date()) -> Bool {
        let storedPeriod = GoalDayPeriod(rawValue: dayPeriod ?? "") ?? .anytime
        let rawWeeklyTime = GoalWeeklyTime.normalized(Int(weeklyTimeMinutes))
        let effectiveWeeklyTime = goalScheduleType == .weekly ? rawWeeklyTime : nil
        let normalizedPeriod = GoalSchedulingRules.normalizedDayPeriod(
            scheduleType: goalScheduleType,
            intervalUnit: timeUnit,
            requestedPeriod: storedPeriod,
            weeklyTimeMinutes: effectiveWeeklyTime
        )
        let hasOrphanedWeeklyTime = goalScheduleType != .weekly && rawWeeklyTime != nil
        guard storedPeriod != normalizedPeriod || hasOrphanedWeeklyTime else { return false }

        updateSchedulingMetadata(
            unitLabel: unitLabel,
            dayPeriod: normalizedPeriod,
            weeklyTimeMinutes: effectiveWeeklyTime,
            referenceDate: now
        )
        return true
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

        case .semanas:
            let day = calendar.startOfDay(for: date)
            return calendar.dateInterval(of: .weekOfYear, for: day)?.start ?? day

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

    /// Conserva la ejecución terminada en el historial y crea una nueva copia
    /// sin iniciar, usando el mismo flujo que Restaurar en Metas Archivadas.
    @discardableResult
    func reactivateCompleted(context: NSManagedObjectContext) throws -> GoalEntity {
        guard isStarted, isCompleted, let goalID = id else {
            throw NSError(
                domain: "GoalReactivation",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: GoalsL10n.text(
                        "goals.error.not_completed",
                        fallback: "La meta todavía no está completada"
                    )
                ]
            )
        }

        try archive(context: context)

        let request: NSFetchRequest<ArchivedGoalEntity> = ArchivedGoalEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", goalID as CVarArg)
        guard let archivedGoal = try context.fetch(request).first else {
            throw NSError(
                domain: "GoalReactivation",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: GoalsL10n.text(
                        "goals.error.preserve_previous_run",
                        fallback: "No se pudo conservar la ejecución anterior"
                    )
                ]
            )
        }

        let reactivatedGoal = try archivedGoal.restoreAsActiveGoal(context: context)
        context.delete(self)
        try context.save()
        return reactivatedGoal
    }

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
            archivedGoal.scheduleType = self.scheduleType
            archivedGoal.weeklyDaysPerWeek = self.weeklyDaysPerWeek
            archivedGoal.weeklyDaysMask = self.weeklyDaysMask
            archivedGoal.weeklyTimeMinutes = Int32(self.weeklyTimeMinutesValue ?? GoalWeeklyTime.disabledMinutes)
            archivedGoal.dayPeriod = self.goalDayPeriod.rawValue
            archivedGoal.customUnitLabel = self.customUnitLabel
            archivedGoal.executionTargetValue = self.executionTargetValue
            archivedGoal.completionBasis = self.completionBasis
            archivedGoal.durationValue = self.durationValue
            archivedGoal.durationUnit = self.durationUnit
            archivedGoal.completionDate = Date()
            recordStatsEvent(.goalArchived, date: archivedGoal.completionDate, context: context)
            
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

extension GoalEntity {

    func recordStatsEvent(
        _ type: GoalStatsEventType,
        unit: UnitEntity? = nil,
        date: Date? = Date(),
        context explicitContext: NSManagedObjectContext? = nil
    ) {
        guard let context = explicitContext ?? managedObjectContext else { return }
        let eventDate = date ?? Date()
        let calendar = Calendar.current

        if let unitID = unit?.id, let goalID = id {
            let request: NSFetchRequest<GoalStatsEventEntity> = GoalStatsEventEntity.fetchRequest()
            request.predicate = NSPredicate(
                format: "eventType == %@ AND goalID == %@ AND unitID == %@",
                type.rawValue,
                goalID as CVarArg,
                unitID as CVarArg
            )
            request.fetchLimit = 1

            if let existing = try? context.fetch(request), existing.isEmpty == false {
                return
            }
        }

        let event = GoalStatsEventEntity(context: context)
        event.id = UUID()
        event.eventType = type.rawValue
        event.createdAt = eventDate
        event.dayStart = calendar.startOfDay(for: eventDate)
        event.goalID = id
        event.goalTitle = title
        event.unitID = unit?.id
        event.unitIndex = unit?.index ?? 0
        event.unitType = unit?.unitType ?? unitType
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
        archivedGoal.scheduleType = self.scheduleType
        archivedGoal.weeklyDaysPerWeek = self.weeklyDaysPerWeek
        archivedGoal.weeklyDaysMask = self.weeklyDaysMask
        archivedGoal.weeklyTimeMinutes = Int32(self.weeklyTimeMinutesValue ?? GoalWeeklyTime.disabledMinutes)
        archivedGoal.dayPeriod = self.goalDayPeriod.rawValue
        archivedGoal.customUnitLabel = self.customUnitLabel
        archivedGoal.executionTargetValue = self.executionTargetValue
        archivedGoal.completionBasis = self.completionBasis
        archivedGoal.durationValue = self.durationValue
        archivedGoal.durationUnit = self.durationUnit
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

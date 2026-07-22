//
//  ProgramasViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//


import SwiftUI
import CoreData
import Combine

@MainActor
class ProgramasViewModel: ObservableObject {

    @Published var programasAgrupados:
        [(String, [ProgramasPreestablecido])] = []
    
    let context = CoreDataController.shared.context
    private static let decoder = JSONDecoder()
    private static var cacheByFile: [String: ProgramasPreestablecido] = [:]
    private static var groupedCache: [AppLanguage: [(String, [ProgramasPreestablecido])]] = [:]

    init() {
        cargarProgramas()
    }

    private func cargarProgramas() {
        let language = AppLanguage.current
        if let cache = Self.groupedCache[language] {
            programasAgrupados = cache
            return
        }

        let grupos = ProgramaArchivo.agrupados

        let loadedGroups = grupos.map { grupo in

            let modelos = grupo.1.compactMap {
                cargarJSON(nombre: $0.rawValue)
            }

            return (grupo.0, modelos)
        }

        Self.groupedCache[language] = loadedGroups
        programasAgrupados = loadedGroups
    }

    private func cargarJSON(nombre: String) -> ProgramasPreestablecido? {
        let cacheKey = "\(AppLanguage.current.rawValue):\(nombre)"
        if let cached = Self.cacheByFile[cacheKey] {
            return cached
        }

        guard let url = Bundle.main.url(
            forResource: nombre,
            withExtension: "json"
        ) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try Self.decoder.decode(ProgramasPreestablecido.self, from: data)
            let localized = GoalEditorialLocalization.program(filename: nombre, fallback: decoded)
            Self.cacheByFile[cacheKey] = localized
            return localized
        } catch {
            print(error)
            return nil
        }
    }
    
    
    //Crear Meta para Programa preestablecido sin iniciarla automáticamente:
    func createProgramaPreestablecido(programa : ProgramasPreestablecido) {
        Self.createProgramaPreestablecido(programa: programa, context: context)
    }
    
    static func createProgramaPreestablecido(
        programa: ProgramasPreestablecido,
        context: NSManagedObjectContext
    ) {
        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.title = programa.title
        goal.descriptionText = programa.description
        goal.totalUnits = Int32(programa.noUnidades)
        goal.unitType = programa.tipoUnidad.rawValue
        goal.frequency = Int32(programa.frecuencia)
        goal.scheduleType = programa.scheduleType.rawValue
        goal.weeklyDaysPerWeek = Int16(programa.weeklyDaysPerWeek)
        goal.weeklyDaysMask = GoalWeeklySchedule.mask(
            for: GoalWeeklySchedule.defaultWeekdays(count: programa.weeklyDaysPerWeek)
        )
        goal.dayPeriod = programa.dayPeriod.rawValue
        goal.customUnitLabel = programa.customUnitLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        goal.executionTargetValue = 1
        goal.completionBasis = GoalCompletionBasis.executions.rawValue
        goal.durationValue = 0
        goal.durationUnit = TimeUnit.dias.rawValue
        goal.isStarted = false
        
        // Genera unidades pero mantiene la meta sin iniciar
        goal.generateUnits(
            DetallesUnidades: programa.unidadesinfo,
            specificDates: programa.scheduleType == .specificDates ? programa.resolvedSpecificDates : []
        )
        
        //Salvando el contexto
        do {
            try context.save()
        } catch {
            context.rollback()
            msg("Error guardando programa preestablecido:", error)
        }
    }
    
    
}

//
//  ProgramasViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//


import SwiftUI
import Combine

@MainActor
final class ProgramasViewModel: ObservableObject {
    
    @Published var programas: [ProgramasPreestablecido] = []
    
    let context = CoreDataController.shared.context
    
    private let repository = ProgramasRepository()
    
    init() {
        load()
    }
    
    private func load() {
        programas = repository.loadAll()
    }
    
    //Crear Metas para Programa preestablecidas, y los Inicia:
    func createProgramaPreestablecido(programa : ProgramasPreestablecido) {
        
         let goal = GoalEntity(context: context)
         goal.id = UUID()
         goal.title = programa.title
         goal.descriptionText = programa.description
         goal.totalUnits = Int32(programa.noUnidades)
         goal.unitType = programa.tipoUnidad.rawValue
         goal.frequency = Int32(programa.frecuencia)
         goal.isStarted = false
        
        msg(programa.unidadesNotes)
        
        // genera unidades
        goal.startProgramaPreestablecido(unitNotes: programa.unidadesNotes)
        
         
        //Salvando el contexto
        do {
            try context.save()
        } catch {
            context.rollback()
            msg("Error guardando programa preestablecido:", error)
        }
        
        
    }
    
}

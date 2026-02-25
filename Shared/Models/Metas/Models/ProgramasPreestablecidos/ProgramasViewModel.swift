//
//  ProgramasViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//


import SwiftUI
import Combine

@MainActor
class ProgramasViewModel: ObservableObject {

    @Published var programasAgrupados:
        [(String, [ProgramasPreestablecido])] = []
    
    let context = CoreDataController.shared.context

    init() {
        cargarProgramas()
    }

    private func cargarProgramas() {

        let grupos = ProgramaArchivo.agrupados

        programasAgrupados = grupos.map { grupo in

            let modelos = grupo.1.compactMap {
                cargarJSON(nombre: $0.rawValue)
            }

            return (grupo.0, modelos)
        }
    }

    private func cargarJSON(nombre: String) -> ProgramasPreestablecido? {

        guard let url = Bundle.main.url(
            forResource: nombre,
            withExtension: "json"
        ) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder()
                .decode(ProgramasPreestablecido.self, from: data)
        } catch {
            print(error)
            return nil
        }
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
        
      
        // genera unidades
        goal.startProgramaPreestablecido(unitNotes: programa.unidadesinfo)
        
         
        //Salvando el contexto
        do {
            try context.save()
        } catch {
            context.rollback()
            msg("Error guardando programa preestablecido:", error)
        }
        
        
    }
    
    
}




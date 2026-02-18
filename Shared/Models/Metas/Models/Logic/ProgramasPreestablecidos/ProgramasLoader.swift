//
//  ProgramasLoader.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//

// Carga los programas Preestablecidos
import SwiftUI

//ViewModel



final class ProgramasRepository {
    
    func loadAll() -> [ProgramasPreestablecido] {
        
        ProgramaArchivo.allCases.compactMap { archivo in
            loadPrograma(named: archivo.rawValue)
        }
    }
    
    private func loadPrograma(named filename: String) -> ProgramasPreestablecido? {
        
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "json"
        ) else {
            print("Archivo no encontrado:", filename)
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ProgramasPreestablecido.self, from: data)
        } catch {
            print("Error decodificando:", error)
            return nil
        }
    }
}



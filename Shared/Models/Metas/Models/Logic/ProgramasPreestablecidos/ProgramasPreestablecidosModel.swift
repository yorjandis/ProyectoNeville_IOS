//
//  ProgramasPreestablecidos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//



import SwiftUI

//Modelo del Json
struct UnidadesInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let note: String
    
    enum CodingKeys: String, CodingKey {
            case name
            case note
        }
        
        init(name: String, note: String) {
            self.id = UUID()
            self.name = name
            self.note = note
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.note = try container.decode(String.self, forKey: .note)
            self.id = UUID() // 👈 generado automáticamente
        }
}

struct ProgramasPreestablecido: Codable, Identifiable {
    let id: UUID
    let title: String
    let detalles : String
    let description: String
    let unidadesNotes: [UnidadesInfo]
    let noUnidades: Int
    let tipoUnidad : TimeUnit
    let frecuencia : Int
    
    enum CodingKeys: String, CodingKey {
            case title
            case detalles
            case description
            case unidadesNotes
            case noUnidades
            case tipoUnidad
            case frecuencia
        }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decode(String.self, forKey: .title)
        self.detalles = try container.decode(String.self, forKey: .detalles)
        self.description = try container.decode(String.self, forKey: .description)
        self.unidadesNotes = try container.decode([UnidadesInfo].self, forKey: .unidadesNotes)
        self.noUnidades = try container.decode(Int.self, forKey: .noUnidades)
        self.tipoUnidad = try container.decode(TimeUnit.self, forKey: .tipoUnidad)
        self.frecuencia = try container.decode(Int.self, forKey: .frecuencia)

        self.id = UUID()
    }
        
    init(title: String,
         detalles: String,
         description: String,
         unidadesNotes: [UnidadesInfo],
         noUnidades: Int,
         tipoUnidad: TimeUnit,
         frecuencia: Int) {

        self.id = UUID()
        self.title = title
        self.detalles = detalles
        self.description = description
        self.unidadesNotes = unidadesNotes
        self.noUnidades = noUnidades
        self.tipoUnidad = tipoUnidad
        self.frecuencia = frecuencia
    }
}



//Archivos json de programas Preestablecidos
enum ProgramaArchivo: String, CaseIterable {
    case dietaSemanalA = "programa_sem_a"
}

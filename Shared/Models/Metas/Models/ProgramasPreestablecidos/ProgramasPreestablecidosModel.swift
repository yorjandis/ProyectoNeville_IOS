//
//  ProgramasPreestablecidos.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/26.
//



import SwiftUI




//Archivos json de programas Preestablecidos
enum ProgramaArchivo: String, CaseIterable {
    case prog_dieta_semanal_1
    case prog_dieta_semanal_2
    case prog_dieta_semanal_3
    case prog_dejar_fumar_1
    case prog_dejar_fumar_2
    case prog_dejar_alcohol_1
    case prog_dejar_alcohol_2
    case prog_respiracion_buteyko
    case prog_anti_ansiedad
    case prog_anti_ansiedad_2
    case prog_reset_dopaminergico_1
    case prog_reset_dopaminergico_2
    case prog_regulacion_digital_menores_1
    case prog_regulacion_digital_menores_2
    
    case prog_visualizacion_creativa_neville_1
    case prog_visualizacion_creativa_neville_2
    case prog_visualizacion_creativa_neville_3
 
}

//Creamos los grupos Base: elimnando los números al final de los programas
extension ProgramaArchivo{
    var grupoBase: String {
        rawValue.replacingOccurrences(
            of: "_\\d+$",
            with: "",
            options: .regularExpression
        )
    }
}

//Agrupación Automática final:
extension ProgramaArchivo {

    static var agrupados: [(String, [ProgramaArchivo])] {

        let dic = Dictionary(grouping: allCases) {
            $0.grupoBase
        }

        return dic
            .map { ($0.key, $0.value.sorted { $0.rawValue < $1.rawValue }) }
            .sorted { $0.0 < $1.0 }
    }
}






//Modelo del Json
struct UnidadesInfo: Codable, Identifiable {
    let id: UUID
    let name: String
    let info: String
    
    enum CodingKeys: String, CodingKey {
            case name
            case info
        }
        
        init(name: String, info: String) {
            self.id = UUID()
            self.name = name
            self.info = info
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.info = try container.decode(String.self, forKey: .info)
            self.id = UUID() // 👈 generado automáticamente
        }
}

struct ProgramasPreestablecido: Codable, Identifiable {
    let id: UUID
    let title: String
    let detalles : String
    let description: String
    let unidadesinfo: [UnidadesInfo]
    let noUnidades: Int
    let tipoUnidad : TimeUnit
    let frecuencia : Int
    
    enum CodingKeys: String, CodingKey {
            case title
            case detalles
            case description
            case unidadesinfo
            case noUnidades
            case tipoUnidad
            case frecuencia
        }
        
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.decode(String.self, forKey: .title)
        self.detalles = try container.decode(String.self, forKey: .detalles)
        self.description = try container.decode(String.self, forKey: .description)
        self.unidadesinfo = try container.decode([UnidadesInfo].self, forKey: .unidadesinfo)
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
        self.unidadesinfo = unidadesNotes
        self.noUnidades = noUnidades
        self.tipoUnidad = tipoUnidad
        self.frecuencia = frecuencia
    }
}



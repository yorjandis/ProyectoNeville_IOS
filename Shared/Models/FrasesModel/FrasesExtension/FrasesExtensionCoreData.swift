//
//  FrasesExtensionCoreData.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/2/26.
//

import Foundation
import CoreData

//Variables computadas:
extension Frases{
    //Es personal la frase
    var isPersonal: Bool {
        noinbuilt
    }
    
    //Frase Tiene Nota
    var tieneNota: Bool {
        !(nota?.isEmpty ?? true)
    }
    
    //Normaliza el texto de la frase
    var textoNormalizado: String {
        frase?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
    
    //Devuelve el nombre del Autor completo
    var getNameAutor : String {
        switch self.autor {
        case "nev": return "Neville Goddard (Conferencista,Autor, Místico y Pensador)"
        case "jd": return "Dr. Joe Dispenza (Conferencista, Autor, especialidad: Neurociencia y conexión mente-cuerpo)"
        case "bruceL": return "Dr. Bruce H. Lipton (Biólogo Molecular, Autor, Conferecista)"
        case "gregg": return "Greegg Braden (Autor, Conferencista, Geólogo, Antiguas Culturas)"
        default: return self.autor ?? ""
        }
    }
    
    
}


    


//Actualizar una frase Personal:
extension Frases {
    func actualizarFrasePersonal(
            texto: String,
            nota: String,
            autor: String,
            isFav: Bool,
            context: NSManagedObjectContext
        ) throws {
            guard isPersonal else { return }

            self.frase = texto
            self.nota = nota
            self.autor = autor
            self.isfav = isFav

            if context.hasChanges {
                try context.save()
            }
        }
    /*
     en el FrasesModel:
     try frase.actualizar(...)
     */
}

//Resolver Duplicados:
extension Frases {
    //Resuelve las frases duplicadas y devuelve el número de frases duplicadas que se han procesado
    static func resolverDuplicados(
            en context: NSManagedObjectContext
        ) throws -> Int {

            let request: NSFetchRequest<Frases> = fetchRequest()
            let frases = try context.fetch(request)

            let grupos = Dictionary(grouping: frases) {
                $0.textoNormalizado
            }

            var eliminadas = 0

            for grupo in grupos.values where grupo.count > 1 {
                let conservar = grupo.sorted {
                    $0.isPersonal && !$1.isPersonal
                }.first!

                grupo.filter { $0 != conservar }.forEach {
                    context.delete($0)
                    eliminadas += 1
                }
            }

            if context.hasChanges {
                try context.save()
            }

            return eliminadas
        }
    /*
     en FrasesModel:
     let eliminadas = try Frases.resolverDuplicados(en: context)
     */
}


//Reutilizar Queries Fetch:
enum FrasesQuery {
    case todas
    case favoritas
    case personales
    case conNotas
    case porAutor(String)
    case buscarTexto(String)
    case buscarEnNotas(String)
}
extension Frases {

    //Devuelve el listado de frases de acuerdo con criterios de filtro
    //Nota: en FrasesModel hay 20 funciones con fetch repetidos.
    static func fetch(_ query: FrasesQuery,context: NSManagedObjectContext) throws -> [Frases] {

        let request: NSFetchRequest<Frases> = fetchRequest()

        switch query {
        case .buscarEnNotas(let text):
            request.predicate = NSPredicate(format: "nota CONTAINS[cd] %@", text)
        case .favoritas:
            request.predicate = NSPredicate(format: "isfav == YES")

        case .personales:
            request.predicate = NSPredicate(format: "noinbuilt == YES")

        case .conNotas:
            request.predicate = NSPredicate(format: "nota != nil AND nota != ''")

        case .buscarTexto(let text):
            request.predicate = NSPredicate(format: "frase CONTAINS[cd] %@", text)

        case .porAutor(let autor):
            request.predicate = NSPredicate(format: "autor == %@", autor)
            
        case .todas:
            break
        }

        return try context.fetch(request)
    }
}

//Devuelve una entidad Frase dado su texto:
extension Frases {
    static func getFraseByText(fraseTexto: String, context: NSManagedObjectContext) throws -> Frases? {
        let request: NSFetchRequest<Frases> = Frases.fetchRequest()
        request.predicate = NSPredicate(format: "frase == %@", fraseTexto)
        return try context.fetch(request).first
    }
}


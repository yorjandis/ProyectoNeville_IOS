//
//  parsearFrasesNuevoFormato.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/1/26.
//

/*
 Leer el nuevo formato y se devuelve una estructura de información de cada Frase:
 El parser espera este formato:
 
 id=nev_001
 autor=nev
 nota=Esto es una nota de ejemplo
 fuente=Tomado de la conferencia: ""
 cotexto="Creación de la Realidad,Poder creativo de Dios"
 texto=En presencia de la dignidad los principios no se negocian
 relacionadas=nev_002,nev_005

 id=nev_002
 autor=nev
 nota=Esto es una nota de ejemplo
 fuente=Tomado de la conferencia: ""
 cotexto="Creación de la Realidad,Poder creativo de Dios"
 texto=En presencia de la dignidad los principios no se negocian
 relacionadas=nev_002,nev_005
 
 Donde cada bloque debe estar separado por 1 línea en blanco.
 */



import SwiftUI

func parsearFrasesNuevoFormato(_ contenido: String) -> [FraseDTO] {

    let bloques = contenido
        .components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    var resultado: [FraseDTO] = []

    for bloque in bloques {

        var id:         String?
        var autor:      String?
        var nota :      String?
        var fuente:     String?
        var contexto:   [String] = []
        var texto:      String?
        var relacionadas: [String] = []

        let lineas = bloque.components(separatedBy: .newlines)

        //Seperando los componentes de cada Bloque
        for linea in lineas {
            let partes = linea.components(separatedBy: "=")
            guard partes.count >= 2 else { continue }

            let clave = partes[0].trimmingCharacters(in: .whitespaces)
            let valor = partes.dropFirst().joined(separator: "=")
                .trimmingCharacters(in: .whitespaces)

            switch clave {
            case "id":
                id = valor
            case "autor":
                autor = valor
            case "nota":
                nota = valor
            case "fuente":
                fuente = valor
            case "contexto":
                contexto = valor
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            case "texto":
                texto = valor
            case "relacionadas":
                relacionadas = valor
                    .components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            default:
                break
            }
        }

        // Validación mínima
        if let id, let autor, let nota, let fuente,  let texto {
            resultado.append(
                FraseDTO(
                    id: id,
                    autor: autor,
                    nota: nota,
                    fuente: fuente,
                    contexto: contexto,
                    texto: texto,
                    relacionadas: relacionadas
                )
            )
        } else {
            msg("⚠️ Bloque inválido:\n\(bloque)")
        }
    }
    
    //Detección de duplicados (solo para el desarrollador) de:  ids / frases
    
    msg(findDuplicatesDTO(dtoArray: resultado))
        

    return resultado
}


//Buscar id duplicados en las frases creadas
//Devuelve las frases que están duplicadas
fileprivate func findDuplicatesDTO(dtoArray : [FraseDTO]) -> String {
    
    var idCount: [String: Int] = [:]
    var textoCount: [String: Int] = [:]
    
    // 1️⃣ Contamos cuántas veces aparece cada id y cada texto
    for frase in dtoArray {
        idCount[frase.id, default: 0] += 1
        textoCount[frase.texto, default: 0] += 1
    }
    
    // 2️⃣ Filtramos las frases que estén duplicadas por id o por texto
    
    let idDuplicados = dtoArray.filter { frase in
        (idCount[frase.id] ?? 0) > 1
    }
    
    let frasesDuplicadas = dtoArray.filter { frase in
        (textoCount[frase.texto] ?? 0) > 1
    }
    
    /*
     let arrayDuplicados =  dtoArray.filter { frase in
         (idCount[frase.id] ?? 0) > 1 ||
         (textoCount[frase.texto] ?? 0) > 1
     }
     */
    
    let resultIDDuplicados = Set(idDuplicados.map(\.id)).joined(separator: ",")
    let resultFrasesDuplicadas = Set(frasesDuplicadas.map(\.texto)).joined(separator: "\n")
    
    return """

____________________DUPLICADOS EN FRASES TXT __________________

=> IDs duplicados:\n \(resultIDDuplicados)\n\n=> Frases duplicadas:\n \(resultFrasesDuplicadas)

_______________________________________________________________

"""
    
   
    
}

//
//  convertirFormatoAntiguoANuevo.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/1/26.
//

/*
 Convierte el antiguo formato:
La imaginación crea la Realidad|nev
 en:
 id=nev_001
 autor=nev
 texto=La imaginación crea la Realidad
 relacionadas=
 
 Reglas de generación de ID únicos:
 Reglas de generación de ID
     •    Prefijo: autor en minúsculas
     •    Secuencia incremental por autor
     •    Formato: autor_001, autor_002, etc.
 */

/*
 import SwiftUI

 //Yor: esta función solo se utilizará una sola vez: Es una función Auxiliar
 func convertirFormatoAntiguoANuevo(_ contenido: String) -> String {

     let lineas = contenido
         .components(separatedBy: .newlines)
         .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
         .filter { !$0.isEmpty }

     var contadorPorAutor: [String: Int] = [:]
     var bloques: [String] = []

     for linea in lineas {

         let partes = linea.components(separatedBy: "|")
         guard partes.count == 2 else {
             print("⚠️ Línea inválida: \(linea)")
             continue
         }

         let texto = partes[0].trimmingCharacters(in: .whitespaces)
         let autor = partes[1].trimmingCharacters(in: .whitespaces)

         let claveAutor = autor.lowercased()
         let secuencia = (contadorPorAutor[claveAutor] ?? 0) + 1
         contadorPorAutor[claveAutor] = secuencia

         let id = String(format: "%@_%03d", claveAutor, secuencia)

         let bloque = """
         id=\(id)
         autor=\(autor)
         texto=\(texto)
         relacionadas=
         """

         bloques.append(bloque)
     }

     return bloques.joined(separator: "\n\n")
 }
 */


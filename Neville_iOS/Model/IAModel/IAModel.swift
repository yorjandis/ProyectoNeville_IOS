//
//  IAModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 20/10/25.
//

import SwiftUI
import FoundationModels

@MainActor
@available(iOS 26.0, *)
final class IAModel :  ObservableObject{
    
    let model : LanguageModelSession
   //@Published var output : String = ""
   @Published var parrafos: [Parrafo] = []
    
    let maxLength : Int = 4000
    @Published var noFragmentos : Int = 0
    @Published var fragmentoActual : Int = 0
    
    
    
    init(){
        self.model = LanguageModelSession()
    }
    
    
    func executeRequest(texto : String) async {
        guard !texto.isEmpty else { return }
       // self.output = ""
        self.parrafos.removeAll()
        
            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLength)
            var resultados: [String] = []
            
        do{
            for (index, fragmento) in fragmentos.enumerated() {
                let session : LanguageModelSession = LanguageModelSession()
                print("Procesando fragmento \(index + 1)/\(fragmentos.count)...")
                self.fragmentoActual = index + 1
                let respuesta = try await session.respond(to: "Extrae las ideas claves de este texto: \(fragmento)").content
                let procesado = procesarLineasNumeradas(from: respuesta).replacingOccurrences(of: "\n", with: "\n\n")
                resultados.append(procesado)
                
                /*/
                // Actualizamos el texto parcial para que se vea progresivamente
                await MainActor.run {
                    self.output =   resultados.joined(separator: "\n\n")
                }
                 */
                
            }
            
            //Actualizando la variable observada
            //self.output =   resultados.joined(separator: "\n\n") //Salida de texto plano
            let outputCompleto = resultados.joined(separator: "\n\n")
            self.parrafos = formatearParrafosDesdeTexto(outputCompleto) // Salida a la variable observable
            
            // print("el número de párrafos es: \(self.parrafos.count)")
            
            
        }catch{
            self.parrafos.append(Parrafo(encabezado: "Error: \(error.localizedDescription)", contenido: ""))
        }
            
            
           
        }
    
    
    //Divide el texto en frafmentos:
    private func dividirTexto(_ texto: String, maxLength: Int) -> [String] {
            var fragmentos: [String] = []
            var inicio = texto.startIndex
            
            while inicio < texto.endIndex {
                let fin = texto.index(inicio, offsetBy: maxLength, limitedBy: texto.endIndex) ?? texto.endIndex
                let fragmento = String(texto[inicio..<fin])
                fragmentos.append(fragmento)
                inicio = fin
            }
        self.noFragmentos = fragmentos.count
            return fragmentos
        }
    
    // Filtra las líneas numeradas y elimina los dos primeros caracteres de cada una
    private func procesarLineasNumeradas(from texto: String) -> String {
        let lineas = texto.components(separatedBy: .newlines)
        let procesadas = lineas.compactMap { linea -> String? in
            let trimmed = linea.trimmingCharacters(in: .whitespaces)
            guard trimmed.first?.isNumber == true else { return nil }
            guard trimmed.count > 2 else { return nil }
            let inicio = trimmed.index(trimmed.startIndex, offsetBy: 2)
            return String(trimmed[inicio...]).trimmingCharacters(in: .whitespaces)
        }
        return procesadas.joined(separator: "\n")
    }
    
    
    // Convierte el texto formateado en una lista de párrafos con encabezado y contenido
    private func formatearParrafosDesdeTexto(_ texto: String) -> [Parrafo] {
        var parrafos: [Parrafo] = []
        
        // Nueva expresión regular: permite "**Encabezado:**" o "**Encabezado**:"
        let regex = try! NSRegularExpression(
            pattern: "\\*\\*(.*?)\\*\\*:?\\s*(.*?)(?=\\n\\n|$)",
            options: [.dotMatchesLineSeparators]
        )
        
        let rango = NSRange(texto.startIndex..<texto.endIndex, in: texto)
        let coincidencias = regex.matches(in: texto, options: [], range: rango)
        
        for coincidencia in coincidencias {
            if let rangoEncabezado = Range(coincidencia.range(at: 1), in: texto),
               let rangoContenido = Range(coincidencia.range(at: 2), in: texto) {
                
                let encabezado = String(texto[rangoEncabezado]).trimmingCharacters(in: .whitespacesAndNewlines)
                let contenido = String(texto[rangoContenido]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                parrafos.append(Parrafo(encabezado: encabezado, contenido: contenido))
            }
        }
        
        return parrafos
    }
    
}



//Representa una unidad de contenido de salida de la IA
struct Parrafo {
    let encabezado: String
    let contenido: String
}

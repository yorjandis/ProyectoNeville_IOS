//
//  IAModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 20/10/25.
//

import SwiftUI
import FoundationModels
import Combine
#if os(macOS)
import AppKit
#endif

@MainActor
@available(iOS 26.0, macOS 26.0, *)
final class IAModelAppleIntelligence :  ObservableObject{
    
    var model : LanguageModelSession
    
    
    @Published var puntosClaves     : [String] = [] //Salida: resumen de los puntos claves del texto
    @Published var resumenGeneral   : String = "" //Salida: resumen general del contenido
    @Published var practicas        : [String] = [] //Salida: Listado de concejos prácticos sobre el contenido
    @Published var practicaConcreta : String = "" //Salida: UN ejemplo de aplicación práctica de: Frase, reflexión, cita, etc
    @Published var interpretacion   : String = "" //Salida: Interpretación de un texto de acuerdo a las ideas fundamentales de Neville Goddard
    
    @Published var dialogoConUsuario : String = ""
    
    let maxLengthContext : Int = 4000
    @Published var noFragmentos     : Int = 0 //Representa el número de fragmentos al dividir el contenido para Apple Intelligence
    @Published var fragmentoActual  : Int = 0 //Un contador para la barra de progreso

    
    init(){
        self.model = LanguageModelSession{}
    }
    
    
    
    
    
    
    //Nueva función con Generación Guiada (Conferencias)
    func executeRequestPuntosClaves(texto : String) async {
        

        guard !texto.isEmpty else { return }
        
        //Divide el texto en fragmentos para ser procesados:
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
        
        self.noFragmentos = fragmentos.count //Actualizando la variable UI de progreso
        
        self.puntosClaves.removeAll() //Vacia el buffer
        

            do{
                for (index, fragmento) in fragmentos.enumerated() {
                    let session : LanguageModelSession = LanguageModelSession() //Creando una sesión para analizar cada fragmento
                   
                    
                    self.fragmentoActual = index + 1 //Actualizando la Variable UI de progreso
                    
                    let promt = """
                Actua como un experto en comprensión y síntesis de información.

                Sigue estas directrices:
                - Analiza cuidadosamente el texto y resume las ideas claves.
                - No agregues opiniones personales.
                - Usa un lenguaje sencillo y un tono profesional.
                
                Texto a analizar:
                \(fragmento)
                
                """
                    
                    let respuesta : Summary = try await session.respond(to: promt, generating: Summary.self).content
                    
                    //Filtrando las entradas de respuesta que no terminen en un punto final:"." . Estas no parecen que contengan significado y se deben a que se analiza un fragmento de texto.
                    let resultFiltro = respuesta.keyPoints.filter { str in
                        str.last == "."
                    }
                    self.puntosClaves += resultFiltro
                    
                    
                    
                }
                
                
            }catch{
                self.puntosClaves.append("Error al procesar el texto")
            }
        
        //Resetando las variables UI de progreso
        self.noFragmentos = 0
        self.fragmentoActual = 0

    }
    
    
    //Produce un resumen general del contenido (Conferencias)
    func executeRequestResumenGeneral(texto : String) async {
        
        guard !texto.isEmpty else { return }

        // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
        
        self.noFragmentos = fragmentos.count //Actualizando Variables UI
        
        var resultados: String = "" //Resumenes parciales de cada fragmento
        
        self.resumenGeneral = ""
        
        
        /*Método:
         Genera un resumen general del contenido
         */
            
        do{
            for (index, fragmento) in fragmentos.enumerated() {
                let session : LanguageModelSession = LanguageModelSession()
                let prompt1 = """
        Actúa como un experto en comunicación que resume conferencias.

        Lee atentamente el siguiente texto y escribe un resumen claro, conciso y fiel al contenido original.
        
        Sigue estas directrices:
        - No agregues opiniones personales ni información que no esté en el texto.
        - Usa lenguaje sencillo, frases cortas y un tono didáctico.

        Texto de la conferencia:
        \(fragmento)
        """
                self.fragmentoActual = index + 1 //Actualizando Variables UI
                
                let respuesta = try await session.respond(to: prompt1).content
                resultados.append(respuesta)
            }
            
            //Haciendo un resumen conciso del resultado final
            let sessionFinal : LanguageModelSession = LanguageModelSession()
            let prompt2 = """
                Actúa como un experto en comunicación que resume conferencias.
        
                Lee atentamente el siguiente texto y escribe un resumen claro, detallado y fiel al contenido original.
                
                Sigue estas directrices:
                - No agregues opiniones personales ni información que no esté en el texto.
                - Usa lenguaje sencillo, frases cortas y un tono didáctico.
        
                Texto de la conferencia:
                \(resultados)
        """
           let temp =  try await sessionFinal.respond(to: prompt2, generating: ResumenG.self).content

            self.resumenGeneral = temp.resumen
        }catch{
            self.resumenGeneral = "Ha ocurrido un error en el procesamiento"
        }
              
        //reseteando las variables de UI
        self.noFragmentos = 0
        self.fragmentoActual = 0
        
        
        }
    
    
    //Produce un listado de aplicaciones prácticas (Conferencias)
    func executeRequestListAplicacionPractica(texto : String, autor : String = "nev") async {
        
        guard !texto.isEmpty else { return }

            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
        
        self.noFragmentos = fragmentos.count //Actualizando la Variable UI de progreso
        
            var resultados: String = "" //Resumenes parciales de cada fragmento
        
        self.practicas.removeAll()
        
        /*Método:
         1. Realiza un resumen general del contenido
         2. Extrae las ideas claves y genera ejemplos prácticos
         */
        
        //Obteniendo los principios de conocimiento según el autor:
        var principios : String = ""
        switch autor {
        case "nev": principios = NevilleEngine.corePrinciples
        case "jd": principios = DispenzaEngine.corePrinciples
        case "bruceL" : principios = LiptonEngine.corePrinciples
        case "gregg": principios = BradenEngine.corePrinciples
        default: principios = NevilleEngine.corePrinciples
        }
            
        do{
            for (index, fragmento) in fragmentos.enumerated() {
                let session : LanguageModelSession = LanguageModelSession()
                let prompt1 = """
        Actúa como un experto en comunicación que resume conferencias.

        Lee atentamente el siguiente texto y escribe un resumen claro, conciso y fiel al contenido original.
        
        No agregues opiniones personales ni información que no esté en el texto.
        
        Usa lenguaje sencillo, frases cortas y un tono didáctico.

        Texto de la conferencia:
        \(fragmento)
        """
                self.fragmentoActual = index + 1 //Actualizando la variable UI de progreso
                
                let respuesta = try await session.respond(to: prompt1).content
                resultados.append(respuesta)
            }
            
            //Generando concejos para aplicar el conocimiento en la vida práctica
            let sessionFinal : LanguageModelSession = LanguageModelSession()
            let prompt2 = """
                Basado en estos principios:
                \(principios)
                
                Extrae las ideas claves del texto y genera para cada una un ejemplo práctico.

                No agregues opiniones personales ni información que no esté en el texto.

                Usa un tono positivo, motivador y personal.

                El texto a analizar es este:
                \(resultados)
                """
           let temp =  try await sessionFinal.respond(to: prompt2, generating: PracticalAdvice.self).content

            self.practicas = temp.actionableSteps
        }catch{
            self.practicas.append("Ha ocurrido un error en el procesamiento")
        }
              
        //Reseteando las variables UI de progreso
        self.noFragmentos = 0
        self.fragmentoActual = 0
        
        }
    
    
    //Produce una aplicación práctica de una Frase, nota, reflexión, ayuda y cita
    func executeRequestPracticaConcreta(texto: String, autor : String = "nev") async {
         guard !texto.isEmpty else {return}
        //Actúa como un experto en aprendizaje aplicado, desarrollo personal y autoayuda.
        
        //Obteniendo los principios de conocimiento según el autor:
        var principios : String = ""
        switch autor {
        case "nev": principios = NevilleEngine.corePrinciples
        case "jd": principios = DispenzaEngine.corePrinciples
        case "bruceL" : principios = LiptonEngine.corePrinciples
        case "gregg": principios = BradenEngine.corePrinciples
        default: principios = NevilleEngine.corePrinciples
        }
        
        let promt = """
            Basado en estos principios:
            \(principios)
            
            Analiza el texto y genera un modo de aplicar sus ideas. 
            
            Sigue estas directrices:
            - Sé preciso y mantén un tono profesional.
            - No exeder de 200 palabras.
            - No añadas ideas propias.
            - No menciones los principios.
            - Solo muestra el texto del ejemplo práctico.
            
            El texto es este:
            \(texto)
            """
        
        self.practicaConcreta = ""
        
        
        /*Método:
         Genera un ejemplo práctico de la vida diaria
         */
        
        do{
            let session : LanguageModelSession = LanguageModelSession()
            let response = try await session.respond(to: promt).content
            self.practicaConcreta = response
        }catch{
            self.practicaConcreta = "No se pudo procesar el texto"
        }
    }
    
    
    
    //Genera una interpretación de un texto(Frase, refelxion, cita, nota, respuesta) de acuerdo con las ideas fundamentales de Neville Goddard
    func executeRequestInterpretaTexto(texto: String, autor : String = "nev") async {
        guard !texto.isEmpty else {return}
        
        
        //Obteniendo los principios de conocimiento según el autor:
        var principios : String = ""
        switch autor {
        case "nev": principios = NevilleEngine.corePrinciples
        case "jd": principios = DispenzaEngine.corePrinciples
        case "bruceL" : principios = LiptonEngine.corePrinciples
        case "gregg": principios = BradenEngine.corePrinciples
        default: principios = NevilleEngine.corePrinciples
        }
        
        let prompt = """
        Basado en estos principios:
        \(principios)
                    
        Analiza e interpreta este texto:
        \(texto)
                    
        Responde solo en base a los principios anteriores.
        
        No hagas mención directa de los principios.
                    
        Usa un tono profesional.
                              
        No utilices ideas propias.
                    
        No uses más de 250 palabras.
        """
        self.interpretacion = ""
        
        do{
            let session : LanguageModelSession = LanguageModelSession()
            let response = try await session.respond(to: prompt).content
            self.interpretacion = response
        }catch{
            self.interpretacion = "No se pudo procesar el texto"
        }
  
    }
    
    
    
    
    /// Divide el texto en fragmentos con longitud máxima, agregando los últimos N párrafos
    /// del fragmento anterior como contexto superpuesto.
    
      private func dividirTexto(_ texto: String, maxLength: Int) -> [String] {
          var fragmentos: [String] = []
          var inicio = texto.startIndex
          
          while inicio < texto.endIndex {
              // Calculamos el índice máximo tentativo
              let finTentativo = texto.index(inicio, offsetBy: maxLength, limitedBy: texto.endIndex) ?? texto.endIndex
              var finReal = finTentativo
              
              // Obtenemos el fragmento tentativo
              let rangoTentativo = inicio..<finTentativo
              let subTexto = String(texto[rangoTentativo])
              
              // Buscamos el último salto de párrafo antes del límite
              if let rangoUltimoSalto = subTexto.range(of: "\n", options: .backwards) {
                  let distancia = subTexto.distance(from: subTexto.startIndex, to: rangoUltimoSalto.lowerBound)
                  if distancia > 0 {
                      finReal = texto.index(inicio, offsetBy: distancia)
                  }
              }
              
              // Creamos el fragmento con el rango calculado
              let fragmento = String(texto[inicio..<finReal])
              fragmentos.append(fragmento.trimmingCharacters(in: .whitespacesAndNewlines))
              
              // Avanzamos el inicio al final real del fragmento
              inicio = finReal
              
              // Si el siguiente carácter es un salto de línea, lo saltamos
              if inicio < texto.endIndex {
                  inicio = texto.index(after: inicio)
              }
          }
          
          self.noFragmentos = fragmentos.count
          return fragmentos
      }
      
   
    

    
    //Función estática que chequea la disponibilidad del modelo en el dispositivo
   static func isAvailable() -> Bool {
        let model = SystemLanguageModel.default
        
        switch model.availability {
        case .available:
            return true
        case .unavailable:
            return false
        }
    }
    
    
    
    
    
    
}



//Estructura generable para Puntos Claves
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Estructura que representa un resumen de las ideas claves de un texto dado.")
struct Summary {
    @Guide(description: "Listado conciso de las ideas claves del texto.")
    let keyPoints: [String]
}

//Estructura generable para Resumen General
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Estructura que representa un resumen general y conciso de un texto dado.")
struct ResumenG {
    @Guide(description: "Resumen general y conciso del contenido")
    let resumen: String
}

//Estructura generable para listado de concejos prácticos
@available(iOS 26.0, macOS 26.0, *)
@Generable(description: "Estructura que representa consejos prácticos derivados de las enseñanzas de una conferencia.")
struct PracticalAdvice {
    @Guide(description: "Lista de consejos o acciones concretas que una persona puede aplicar para implementar las ideas presentadas en la conferencia.")
    let actionableSteps: [String]
}


///Tipos de salida de resultados. Delinea las funciones de IA actuales.
///Puede ser:
///-puntosClaves: Genera un listado de los puntos claves (solo para conferencias)
///-resumen: Genera un resumen del contenido (solo para conferencias)
///-practicas: Genera un listado de aplicaciones prácticas (solo para conferencias)
///-practicaConcreta: Genera una aplicación práctica de un texto dado (para: frases, reflexiones, citas, entradas del usuario, etc)
///-interpretar: Genera una interpretación de un texto de acuerdo con las ideas fundamentales de Neville Goddard (frases,reflexiones, citas,etc)
///-autoayuda: Genera una respuesta a una petición del usuario relacionada con las enseñanzas de Neville Goddard
enum TiposSalida{
    case puntosClaves      
    case resumen
    case practicas
    case practicaConcreta
    case interpretar
    //case autoayuda
}



//Create a view only if Apple Intelligence is available.
@ViewBuilder
func CreateViewIfAppleIntelligence<Content: View>( content: () -> Content) -> some View {
    if #available(iOS 26.0, macOS 26.0, *) {
        if SystemLanguageModel.default.isAvailable {
            content()
        }
    }
}






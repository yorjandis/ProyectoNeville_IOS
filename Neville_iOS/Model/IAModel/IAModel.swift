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
    
    var model : LanguageModelSession
    
    
    @Published var puntosClaves : [String] = [] //Salida: resumen de los puntos claves del texto
    @Published var resumenGeneral : String = "" //Salida: resumen general del contenido
    @Published var practicas : [String] = [] //Listado de concejos prácticos sobre el contenido
    @Published var practicaConcreta : String = "" //UN ejemplo de aplicación práctica de: Frase, reflexión, cita, etc
    @Published var interpretacion : String = "" //Genera una interpretación de un texto de acuerdo a las ideas fundamentales de Neville Goddard
    
    @Published var dialogoConUsuario : String = ""
    
    let maxLength : Int = 4000
    @Published var noFragmentos : Int = 0
    @Published var fragmentoActual : Int = 0
    
    let ideasFundamentales = """
                    La conciencia es la única realidad y la causa de toda experiencia en la vida. Todo lo que vivimos es un reflejo de nuestro estado interno, ya que el mundo exterior actúa como un espejo de lo que creemos y sentimos ser. Lo que se acepta como verdad en la mente y se siente con intensidad se materializa en el mundo objetivo. Por ello, no se atrae lo que se desea, sino lo que se cree y se siente verdadero en el presente.
                    """
    
    
    
    init(){
        self.model = LanguageModelSession{
            """
            Eres el Maestro Neville Goddard y ofreces conocimientos y concejos prácticos.
            """
        }
    }
    
    
    
    //Nueva función con Generación Guiada
    func executeRequestPuntosClaves(texto : String) async {
        guard !texto.isEmpty else { return }
        
        let fragmentos = dividirTexto(texto, maxLength: self.maxLength)
            
            //Crea un resumen de los puntos más importantes
        
        self.puntosClaves.removeAll()
            
            do{
                for (index, fragmento) in fragmentos.enumerated() {
                    let session : LanguageModelSession = LanguageModelSession() //Creando una sesión para analizar cada fragmento
                   
                    
                    self.fragmentoActual = index + 1
                    
                    let promt = """
                Actua como un experto en comprensión y síntesis de la información.
                
                Analiza cuidadosamente el siguiente texto y extrae las ideas claves
                
                No agregues opiniones personales ni información que no esté en el texto.
                
                Usa lenguaje sencillo y un tono didáctico.
                
                Texto a analizar:
                \(fragmento)
                
                """
                    
                    let respuesta = try await session.respond(to: promt, generating: Summary.self).content
                    
                    
                    self.puntosClaves += respuesta.keyPoints
                    
                    
                    
                }
                
                
            }catch{
                self.puntosClaves.append("Error al procesar el texto")
            }

    }
    
    
    //Produce un resumen general del contenido
    func executeRequestResumenGeneral(texto : String) async {
        
        guard !texto.isEmpty else { return }

            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLength)
            var resultados: String = "" //Resumenes parciales de cada fragmento
        
        self.resumenGeneral = ""
            
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
                self.fragmentoActual = index + 1
                let respuesta = try await session.respond(to: prompt1).content
                resultados.append(respuesta)
            }
            
            //Haciendo un resumen conciso del resultado final
            let sessionFinal : LanguageModelSession = LanguageModelSession()
            let prompt2 = """
                Actúa como un experto en comunicación que resume conferencias.

                Lee atentamente el siguiente texto y escribe un resumen claro, detallado y fiel al contenido original.
                
                No agregues opiniones personales ni información que no esté en el texto.
                
                Usa lenguaje sencillo, frases cortas y un tono didáctico.

                Texto de la conferencia:
        \(resultados)
        """
           let temp =  try await sessionFinal.respond(to: prompt2, generating: ResumenG.self).content

            self.resumenGeneral = temp.resumen
        }catch{
            self.resumenGeneral = "Ha ocurrido un error en el procesamiento"
        }
              
        }
    
    
    //Produce un listado de aplicaciones prácticas de una conferencia
    func executeRequestAplicacionPractica(texto : String) async {
        
        guard !texto.isEmpty else { return }

            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLength)
            var resultados: String = "" //Resumenes parciales de cada fragmento
        
        self.practicas.removeAll()
        
            
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
                self.fragmentoActual = index + 1
                let respuesta = try await session.respond(to: prompt1).content
                resultados.append(respuesta)
            }
            
            //Generando concejos para aplicar el conocimiento en la vida práctica
            let sessionFinal : LanguageModelSession = LanguageModelSession()
            let prompt2 = """
                Actúa como un experto en aprendizaje aplicado y desarrollo personal.

                Extrae las ideas claves y detalla ejemplos prácticos para la vida diaria.
                
                No agregues opiniones personales ni información que no esté en el texto.

                Usa un tono positivo, motivador y personal.

                Texto de la conferencia:
                \(resultados)
                """
           let temp =  try await sessionFinal.respond(to: prompt2, generating: PracticalAdvice.self).content

            self.practicas = temp.actionableSteps
        }catch{
            self.practicas.append("Ha ocurrido un error en el procesamiento")
        }
              
        }
    
    
    //Produce una aplicación práctica de una Frase, reflexión, ayuda y cita
    func executeRequestPracticaConcreta(texto: String) async {
         guard !texto.isEmpty else {return}
        //Actúa como un experto en aprendizaje aplicado, desarrollo personal y autoayuda.
        let promt = """
            Actua como lo haria Neville Goddard, un maestro místico. 
            
            Analiza este texto: \(texto) y extrae un ejemplo práctico en la vida diaria.
            
            Incluye solo el texto del ejemplo práctico.
            
            Usa un tono positivo y motivador
            """
        
        self.practicaConcreta = ""
        
        do{
            let session : LanguageModelSession = LanguageModelSession()
            let response = try await session.respond(to: promt).content
            self.practicaConcreta = response
        }catch{
            self.practicaConcreta = "No se pudo procesar el texto"
        }
    }
    
    
    
    //Genera una interpretación de un texto de acuerdo con las ideas fundamentales de Neville Goddard
    func executeRequestInterpretaTexto(texto: String) async {
        guard !texto.isEmpty else {return}
        
        let prompt = """
        Eres el maestro Neville Goddard, experto en esta área de cononimientos: \(self.ideasFundamentales)

        Según tu área de conocmientos, analiza e interpreta este texto: \(texto)
        
        Además:
        - Sé preciso y mantén un tono profesional.
        - No exeder de 150 palabras.
        - No añadas ideas propias.

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
    
    
    
    //Genera un diálogo con el usuario acerca de temas sobre las enseñanzas de Neville Goddard:
    func executeRequestAutoayuda(texto: String) async {
        guard !texto.isEmpty else {return}
        
        let prompt = """
            Eres el Maestro Neville Goddard.
            
            Analiza e interpreta este texto: \(texto) y ofrece una explicación amena.
            
            Responde y céntrate solo en las enseñanzas de Neville Goddard para dar una respuesta.
            
            Usa un tono profesional.
            
            Termina dando un concejo práctico.
            
            No utilices ideas propias, solo el conocimiento de Neville Goddard.
            
            No uses más de 250 palabras.
            """
        
        do{
            let response = try await self.model.respond(to: prompt).content
            
            self.dialogoConUsuario = response
            
            
        }catch{
            //Si ocurre un problema reinicia la session
            self.model = LanguageModelSession()
        }
        
        
        
        
    }
    
    
    
    
    //Divide el texto en fragmentos de cierto tamaño,  para ser procesados por la IA. Esto se debe a que la ventana de contexto es pequeña en Apple Inteligence
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
@available(iOS 26, *)
@Generable(description: "Estructura que representa un resumen de los puntos más importantes de un texto dado.")
struct Summary {
    @Guide(description: "Lista de los puntos o ideas clave del texto, en frases breves y concisas.")
    let keyPoints: [String]
}

//Estructura generable para Resumen General
@available(iOS 26, *)
@Generable(description: "Estructura que representa un resumen general y conciso de un texto dado.")
struct ResumenG {
    @Guide(description: "Resumen general y conciso del contenido")
    let resumen: String
}

//Estructura generable para listado de concejos prácticos
@available(iOS 26, *)
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
    if #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable {
        content()
    }
}






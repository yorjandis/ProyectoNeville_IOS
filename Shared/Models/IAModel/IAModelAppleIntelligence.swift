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
    @Published var practicas        : [String] = [] //Listado de concejos prácticos sobre el contenido
    @Published var practicaConcreta : String = "" //UN ejemplo de aplicación práctica de: Frase, reflexión, cita, etc
    @Published var interpretacion   : String = "" //Genera una interpretación de un texto de acuerdo a las ideas fundamentales de Neville Goddard
    
    @Published var dialogoConUsuario : String = ""
    
    let maxLengthContext : Int = 4000
    @Published var noFragmentos     : Int = 0 //Representa el número de fragmentos al dividir el contenido para Apple Intelligence
    @Published var fragmentoActual  : Int = 0 //Un contador para la barra de progreso
    
    let Premisas = """
            Premisas:
            - La Conciencia es la única realidad y la causa de toda experiencia.
            - La conciencia se divide en mente consciente(principio masculino) y mente subconsciente(principio femenino).
            - Dios es la conciencia. Es el campo de energía infinito que nos envuelve constantemente.
            - La mente conciente concibe ideas y las imprime en el subconsciente por medio del sentimiento.
            - La mente subconsciente recibe las impresiones por medio del sentimiento y les da forma y expresión en el mundo objetivo.
            - Nada viene de afuera sino de adentro, del subconsciente.
            - El subconsciente es la matriz de la creación.
            - Solo puedes ver y experimentar los contenidos de tu conciencia.
            - No atraemos lo que deseamos, atraemos lo que somos conscientes de ser.
            - El deseo debe asumirse como un hecho cumplido, sintiendo su realidad, para que pueda manifestarse.
            - Pedir o esperar equivale a reconocer su ausencia, mientras que sentir que ya se posee activa el poder creativo del subconsciente.
            - Nuestra vida es un reflejo del estado interno y del concepto que tenemos de nosotros mismos.
            - La imaginación es el poder operante de Dios mismo y crea la realidad.
            - Dios es la maravillosa imaginación del hombre.
            - El mundo físico es la proyección de la conciencia.
            - El mundo físico es el reino de los efectos, mientras que el subconsciente en el reino de las causas. Todo procede del interior, de nuestro subconsciente o mente creativa.
            - Lo que se acepta como verdad en la mente y se siente con intensidad se materializa en el mundo objetivo.
            - La verdadera oración consiste en asumir el sentimiento de ser o tener aquello que se desea, hasta que se sienta natural y real.
            - El cambio en la experiencia externa requiere un cambio en la concepción de uno mismo.
            - Elevar la conciencia al nivel del deseo cumplido y permanecer en ese estado provoca que las circunstancias se transformen en armonía con ese nuevo estado.
            - El sueño y los estados de relajación son momentos clave para la creación de estados y experiencias subjetivas. Antes de dormir, es fundamental asumir el sentimiento del deseo ya realizado.
            - La creación comienza con una asunción, esto es, asumir el sentimiento del desea ya presente y cumplido.
            - El arte de la revisión permite cambiar tu experiencia actual. Comienza revisando, en el ojo de tu mente, cada experiencia negativa y transfórmala en una experiencia positiva utilizando tu imaginación y sentimiento. Esto activa el poder creativo del subconsciente trayendo a tu experiencia la nueva realidad imaginada.
            - Los pensamientos y emociones no retroceden al pasado, avanzan hacia el futuro para confrontarte con hechos y experiencias.
            - Para cambiar tu mundo primero debes cambiar el concepto de tí mísmo.
            - Cada reacción emocional, positiva o negativa, imprime en el subconsciente un patrón que se manifestará como experiencia futura.
            - No pongas tu atención en las limitaciones actuales sino en el estado que deseas manifestar.
            - La fe, entendida como sentimiento de realidad presente, es el medio por el cual toda creación se hace tangible. Tener fe es sentir la realidad del estado buscado.
            - Jesucristo es la imaginación del hombre.
            - La Biblia no es histórica sino un manual psicológico para comprender las grandes verdades de la creación deliberada.
            - Solo se debe aceptar y sentir todo lo que contribuya a la realización de tu deseo.
            - El concepto de sí mísmo determina como te ven los demás.
            - Todo lo que ocurre en tu vida, aunque parezca real y un hecho inalterable, es un reflejo de la actividad anterior de tu conciencia.
            - Tus sentimientos crean el patrón desde el cual tu mundo es creado y un cambio de sentimiento es un cambio de patrón.
            - Pecar es fracasar en el cumplimiento de tu asunción.
            - El alfarero representa nuestra maravillosa imaginación humana. La imaginación moldea la realidad del mismo modo que el alfarero le da forma al barro.  
            - La justicia se entiende por la rectitud de pensamiento y sentimiento, alineados con el ideal que quieres ver manifestado.
            - El mal o el diablo no es más que el sentimiento de duda que sientes antes la realización de tu deseos; y como todo sentimiento, activa el poder del subconsciente impidiendo que tus deseos se hagan realidad.
            - Una asunción aunque parezca falsa, si se persiste en ella, se materializará en hechos.
            - Las señales siguen, no preceden, al acto imaginario.
            - Los estados de ánimo y sentimientos determinan las circunstancias de la vida.
            - No luches contra tus problemas. Tu problema vivirá mientras seas consciente de él. Saca tu atención de tus problemas y ponla en lo que deseas.
            - Nada te impide realizar tu objetivo salvo tu incapacidad de sentir que ya eres aquello que deseas ser.
            - Todo lo que puedas imaginar ya existe y puede ser tuyo. Haz realidad tus deseos imaginando y sintiendo tu deseo cumplido.
            - "Todo lo que contemplas, aunque parece estar fuera, esta dentro, en tu imaginación de la cual este mundo de mortalidad no es más que una sombra"(William Blake)
            
            Responde de manera creativa pero siempre en consonancia con estas premisas.
            
            Responde de manera clara y precisa, como un Maestro a sus discípulos.

            """
    
    
    
    
    init(){
        self.model = LanguageModelSession{
            """
            Eres el Maestro Neville Goddard y ofreces conocimientos y concejos prácticos.
            """
        }
    }
    
    
    
    //Nueva función con Generación Guiada (Conferencias)
    func executeRequestPuntosClaves(texto : String) async {
        guard !texto.isEmpty else { return }
        
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
            
        /*Método:
         Crea un listado de los puntos claves del contenido
         */
        
        
        self.puntosClaves.removeAll()
            
            do{
                for (index, fragmento) in fragmentos.enumerated() {
                    let session : LanguageModelSession = LanguageModelSession() //Creando una sesión para analizar cada fragmento
                   
                    
                    self.fragmentoActual = index + 1
                    
                    let promt = """
                Actua como un experto en comprensión y síntesis de información.
                
                Sigue estas directrices:
                -Analiza cuidadosamente el texto y resume las ideas claves.
                -No agregues opiniones personales.
                -Usa un lenguaje sencillo y un tono profesional.
                
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

    }
    
    
    //Produce un resumen general del contenido (Conferencias)
    func executeRequestResumenGeneral(texto : String) async {
        
        guard !texto.isEmpty else { return }

            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
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
    
    
    //Produce un listado de aplicaciones prácticas (Conferencias)
    func executeRequestListAplicacionPractica(texto : String) async {
        
        guard !texto.isEmpty else { return }

            // Dividir texto en fragmentos
        let fragmentos = dividirTexto(texto, maxLength: self.maxLengthContext)
            var resultados: String = "" //Resumenes parciales de cada fragmento
        
        self.practicas.removeAll()
        
        /*Método:
         1. Realiza un resumen general del contenido
         2. Extrae las ideas claves y genera ejemplos prácticos
         */
            
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
                En consonancia con estas premisas: \(self.Premisas) extrae las ideas claves del texto y genera por cada una un ejemplo práctico.

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
              
        }
    
    
    //Produce una aplicación práctica de una Frase, nota, reflexión, ayuda y cita
    func executeRequestPracticaConcreta(texto: String) async {
         guard !texto.isEmpty else {return}
        //Actúa como un experto en aprendizaje aplicado, desarrollo personal y autoayuda.
        let promt = """
            Tomando como base estas premisas: \(self.Premisas) analiza el texto y extrae un ejemplo práctico. 
            
            Además:
            - Sé preciso y mantén un tono profesional.
            - No exeder de 150 palabras.
            - No añadas ideas propias ni texto contenido en las premisas.
            - No menciones la palabra premisas.
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
    func executeRequestInterpretaTexto(texto: String) async {
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






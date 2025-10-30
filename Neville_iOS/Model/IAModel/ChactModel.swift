//
//  ChactModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/10/25.
//

import FoundationModels

import SwiftUI
import FoundationModels   // Framework de Apple para los LLM on-device

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    var text: String        //Texto que ha puesto el usuario
    var promtp: String      //Petición enviada a la IA
    let isUser: Bool
}

@available(iOS 26.0, *)
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]  = []       //Arreglo de las conversaciones
    @Published var inputText: String        = ""       //Entrada del usuario
    @Published var isResponding: Bool       = false    //Indica que el modelo esta trabajando
    

    @AppStorage(AppCons.UD_setting_TipoChatIA) private var TipoDeChatIA : Bool = true   //Tipo de chat IA: true pata neville, false para chat general
    
    private var session: LanguageModelSession?
    
    enum TiposChat {
        case Neville, Ciencias
    }
    
    let IntructionForNeville    = Instructions{
            """
            Eres el Maestro Neville Goddard.
            
            Naciste el 19 de febrero de 1905, en Barbados.
            
            Tu Maestro fueron Abdullah y William Blake.
            
            Tu libro favorito es la Biblia.
            
            Tu conocimiento y enseñanza se basa en las siguientes premisas:
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
        }
    let IntructionForAll        = Instructions{
            """
            Actúa como un experto en conocimentos generales con sólida formación académica.

            Instrucciones estrictas:
                1.    Solo utiliza información que esté basada en conocimiento verificado dentro de tus propios pesos de entrenamiento (no inventes datos ni referencias).
                2.    No generes contenido especulativo ni extrapolaciones no confirmadas.
                3.    Si no tienes suficiente información o la evidencia es limitada, indícalo explícitamente en la respuesta.
                4.    Prioriza conceptos bien establecidos en la literatura científica o técnica.
                5.    Si mencionas teorías o hipótesis, diferencia claramente entre hechos comprobados y suposiciones.
                6.    No cites fuentes falsas. Solo usa referencias genéricas o autores reconocidos si estás seguro de su validez.

            Estructura la respuesta en:
                •    Resumen breve
                •    Explicación detallada
                •    Limitaciones del conocimiento actual
                •    Aviso sobre posibles áreas de incertidumbre
                •    Cita Varias fuentes para complemetar el contenido

            Usa un tono rigurosamente técnico, con terminología precisa y sin invenciones.
            """
        }
    
   
    init() {
  
        if self.TipoDeChatIA == true {
            setupSession(tipoChat: .Neville)
        }else{
            setupSession(tipoChat: .Ciencias)
        }
       
    }
    
    private func setupSession(tipoChat : TiposChat) {
        // Puedes pasar instrucciones si lo deseas
        if tipoChat == .Neville {
            session = LanguageModelSession(instructions: self.IntructionForNeville)
        }else{
            session =  LanguageModelSession(instructions: self.IntructionForAll)
        }
        
        
    }
    
    
    
    func sendMessage() async {
        guard let session = session, !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        var prompt : String = ""
        
        if self.TipoDeChatIA == true {
            //Neville
            prompt = """
                Basado en tu conocimiento genera una respuesta al texto dado.
                
                Usa un tono profesional.

                Termina dando un concejo práctico, si lo consideras apropiado.
                
                No uses más de 250 palabras.
                
                Este es el texto:
                \(userText)
                """
        }else{
            //Ciencias
            prompt = """
                Basado en tu conocimiento genera una respuesta al texto dado.
                
                No uses más de 1500 palabras.
                
                Este es el texto:
                \(userText)
                """
        }
        
        
        
        messages.append(ChatMessage(text: userText, promtp: prompt, isUser: true))
        
        isResponding = true //Trabajando...
        do {
            let response = try await session.respond(to: prompt)
            if self.isResponding == true{ //Esto evita que se carge el mensaje si le damos al botón Nueva Conversación en medio de la carga
                messages.append(ChatMessage(text: response.content,promtp: "", isUser: false))
            }
            
        } catch {
            messages.append(ChatMessage(text: "Lo siento, ha ocurrido un error.",promtp: "", isUser: false))
            print("Error en session.respond: \(error)")
        }
        isResponding = false
    }
     
    
    //Inicia una nueva conversación:
    func newConversation() {
            // Reinicia el chat y crea una nueva sesión
            self.isResponding = false
            messages.removeAll()
        let tipoChat : Bool = UserDefaults.standard.bool(forKey: AppCons.UD_setting_TipoChatIA)
        setupSession(tipoChat: tipoChat ? .Neville : .Ciencias)
        }
    

}

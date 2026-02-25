//
//  ChactModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/10/25.
//

import FoundationModels

import SwiftUI
import FoundationModels   // Framework de Apple para los LLM on-device
import Combine

//Autores del chapIA
enum Autores {
    case neville, JoeDispenza, bruce, gregg
    
    var getNombre: String {
        switch self {
        case .neville:
            return "Neville"
        case .JoeDispenza:
            return "Joe Dispenza"
        case .bruce:
            return "Dr. Bruce Lipton"
        case .gregg:
            return "Gregg Braden"
        }
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    var text: String        //Texto que ha puesto el usuario
    var promtp: String      //Petición enviada a la IA
    let isUser: Bool
}

@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage]  = []       //Arreglo de las conversaciones
    @Published var inputText: String        = ""       //Entrada del usuario
    @Published var isResponding: Bool       = false    //Indica que el modelo esta trabajando
    @Published var LastIDForScroolling: UUID? = nil   //Se actualiza con el ID del último mensaje de la lista
    
    @AppStorage(AppCons.UD_setting_IA_TratamientoPersonal)    var TratamientoDeIA : Bool = true // true: Representa a Neville, false: Tratamiento impersonal
    

    @Published var  session: LanguageModelSession?
    
    
    static let maxCharactersContext: Int = 4100 //Máximo de caracteres de la ventana de entrada del chat de IA
    
    
    static let shared = ChatViewModel()
    
    
    //Responde de manera creativa pero siempre en consonancia con estas premisas.
    
    //Responde de manera clara y precisa, como un Maestro a sus discípulos.
   
    private init() {}
    
    //Inicializa la sesión con un conjunto de instrucciones
    func setupSession(instrucciones : String = "") {
        // Puedes pasar instrucciones si lo deseas
        //self.session = LanguageModelSession(instructions: instrucciones)
        self.session = LanguageModelSession()
    }
    
    
    
    func sendMessage(autor : Autores, questionUser : String) async {
        
        guard let session = session, !inputText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        let userText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        
        var prompt : String = ""
        
        switch autor {
        case .neville:
             prompt = NevilleEngine.buildPrompt(question: questionUser)
        case .JoeDispenza:
             prompt = DispenzaEngine.buildPrompt(question: questionUser)
        case .bruce:
             prompt = LiptonEngine.buildPrompt(question: questionUser)
        case .gregg:
             prompt = BradenEngine.buildPrompt(question: questionUser)
        }
        

        self.messages.append(ChatMessage(text: userText, promtp: questionUser, isUser: true))
        
        
        isResponding = true //Trabajando...
        
        do {
            let response = try await session.respond(to: prompt)
            if self.isResponding == true{ //Esto evita que se carge el mensaje si le damos al botón Nueva Conversación en medio de la carga
                self.messages.append(ChatMessage(text: response.content,promtp: "", isUser: false))
            }
            
        } catch {
            self.messages.append(ChatMessage(text: "Lo siento, ha ocurrido un error.",promtp: "", isUser: false))
            msg("Error en session.respond: \(error)")
        }
        isResponding = false //Terminó el trabajo
    }
     
    
    //Inicia una nueva conversación:
    func newConversation() {
            // Reinicia el chat y crea una nueva sesión
            self.isResponding = false
            self.messages.removeAll()
        setupSession() //Crea una nueva sesión de IA
        }
    
     // Función auxiliar: Convierte un tipo Color  a formato hexadecimal, para la configuración del CSS del componente RichText
    static func hexString(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Convertir a hexadecimal
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }
    

}





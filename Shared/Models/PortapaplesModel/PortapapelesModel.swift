//
//  PortapapelesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 5/12/25.
//

//iOS/macOS. Detecta cambios en el portapapales y devuelve el nuevo texto copiado al mismo.
/*
 Nota: estas funciones son utilizadas en el fichero ContentTextShowView, ChatIA, RespondView (IA), para poder procesar el texto copiado
 y psarlo a notas, frases, interprertar y chatear con la IA
 */

import SwiftUI
import Combine

#if os(macOS)
import AppKit

/*
 macOS No tiene un observador de cambios en el portapapeles, como iOS. En su lugar,  mantiene un contador (changeCount) del portapapeles.
Que hace este código:
    •    lee el contador del portapapeles ( operación O(1) )
    •    compara con el valor previo
    •    si cambió, intenta obtener texto (una consulta simple al pasteboard)

Son operaciones baratas y síncronas que no bloquean el hilo principal.
 */
@MainActor
final class ClipboardObserver: ObservableObject {
    
    @Published var clipboardText: String? = nil
    

    private var timer: AnyCancellable?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    /// Este método es MainActor-isolated, por lo tanto se ejecuta en el context ator correcto
        @MainActor
        private func stop() {
            timer?.cancel()
            print("⏹ Clipboard monitor detenido")
        }

    init() {
        //Incia un timer que se repite cada medio segundo
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.checkClipboard()
            }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        let texto = pasteboard.string(forType: .string) ?? ""

        if texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            if texto.contains(ClipboardHelper.marcaOculta) {
                self.clipboardText = texto
            } else {
                self.clipboardText = nil
            }
        } else {
            self.clipboardText = nil
        }
    }
}


#else

//iOS si tiene un observador de cambios en el portapapeles
final class ClipboardObserver: ObservableObject {
    
    @Published var clipboardText: String? = nil
    
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIPasteboard.changedNotification)
            .sink { _ in
                let texto = UIPasteboard.general.string ?? "" //Obtiene el texto en el portapapeles
 
                if texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                    
                    if ClipboardHelper.contieneMarcaOculta(texto){
                        self.clipboardText = UIPasteboard.general.string
                    }else{
                        self.clipboardText = nil
                    }
                }else{
                    self.clipboardText = nil
                }
               
            }
    }
    
    

}

#endif

//Clase auxiliar para manejar la insersión de caracteres ocultos en un texto, asi podremos saber que el texto procede de nuestra App
struct ClipboardHelper{
    
    /*
     Otros caracteres ocultos que se pueden utilizar:
     Zero Width Space       U+200B  Invisible más liviano (este es el utilizado)
     Zero Width Joiner      U+200D  Unión invisible
     Zero Width Non-Joiner  U+200C  Separación invisible
     */
    
    static let marcaOculta : String = "\u{200B}"  // Zero Width Space

    
    //Inserta un caracter oculto cada dos palabras en un texto:
   static  func insertarMarcaOculta(en texto: String, marca: String = ClipboardHelper.marcaOculta) -> String {
        // Dividimos el texto en palabras
        let palabras = texto.split(separator: " ")

        var resultado = [String]()
        for (indice, palabra) in palabras.enumerated() {
            resultado.append(String(palabra))
            
            // Cada dos palabras añadimos la marca
            if (indice + 1) % 2 == 0 {
                resultado.append(marca)
            }
        }
        
        return resultado.joined(separator: " ")
    }
    
    
    //Detecta si el texto contiene el caracter oculto:
    static func contieneMarcaOculta(_ texto: String, marca: String = ClipboardHelper.marcaOculta) -> Bool {
        return texto.contains(marca)
    }
    
    //Limpiar el texto de marca oculta:
    static func limpiarMarcaOculta(_ texto: String, marca: String = ClipboardHelper.marcaOculta) -> String {
        return texto.replacingOccurrences(of: marca, with: "")
    }
}



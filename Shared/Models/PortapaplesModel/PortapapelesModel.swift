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
            msg("⏹ Clipboard monitor detenido")
        }

    init() {
        //Incia un timer que se repite cada medio segundo
        timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                guard NSApplication.shared.isActive else {
                    self.clipboardText = nil
                    return
                }
                
                let pasteboard = NSPasteboard.general
                
                guard pasteboard.changeCount != self.lastChangeCount else { return }
                self.lastChangeCount = pasteboard.changeCount
                
                self.clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
            }
    }

}


#else

//iOS si tiene un observador de cambios en el portapapeles
@MainActor
final class ClipboardObserver: ObservableObject {
    
    @Published var clipboardText: String? = nil
    
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = NotificationCenter.default
            .publisher(for: UIPasteboard.changedNotification)
            .sink { _ in
                #if os(iOS)
                guard UIApplication.shared.applicationState == .active else {
                    self.clipboardText = nil
                    return
                }
                
                self.clipboardText = UIPasteboard.general.string ?? ""
                
                #elseif os(macOS)
                guard NSApplication.shared.isActive else {
                    self.clipboardText = nil
                    return
                }
                self.clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
                #endif
                

            }
    }
    
}

#endif




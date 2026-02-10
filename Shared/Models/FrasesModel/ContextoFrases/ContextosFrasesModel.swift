//
//  ContextosFrasesModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/1/26.
//

import Foundation
import CoreData



// Frases → Contextos
extension Frases {
    //Listado de Contextos de una frase
    var contextosArray: [Contexto] {
        let set = contextos as? Set<Contexto> ?? []
        return set.sorted { $0.nombre! < $1.nombre! }
    }

    //Vincular una frase con  un contexto
    func vincularConContexto(_ contexto: Contexto) {
        
        let actuales = contextos as? Set<Contexto> ?? []

            guard !actuales.contains(contexto) else {
                return // ya está vinculado
            }
        
        self.addToContextos(contexto)
        contexto.addToFrases(self)
    }

    //Desvincular una frase de un contexto
    func desvincularDeContexto(_ contexto: Contexto) {
        self.removeFromContextos(contexto)
        contexto.removeFromFrases(self)
    }

    //Eliminar todos los contextos de una frase
    func eliminarTodosLosContextos() {
        contextosArray.forEach { desvincularDeContexto($0) }
    }
}

// Contextos → Frases (opcional, para acceder a frases ordenadas)
extension Contexto {
    //Devuelve las frases que pertenecen a un contexto dado
    var frasesArray: [Frases] {
        let set = frases as? Set<Frases> ?? []
        return set.sorted { $0.frase ?? "" < $1.frase ?? "" }
    }
}


/*
 Reglas de borrado y actualización automática
     •    Eliminar un contexto:
 Solo necesitas context.delete(contexto) → gracias a Nullify, todas las frases se actualizan automáticamente.
     •    Modificar el nombre de un contexto:
 Cambia contexto.nombre = "NuevoNombre" → todas las frases vinculadas verán el cambio inmediatamente.

 No necesitas recorrer frases ni hacer loops, CoreData maneja las relaciones correctamente.
 */


/*
 // Contextos de una frase
 let frase: Frases = ...
 for contexto in frase.contextosArray {
     print(contexto.nombre)
 }

 // Frases de un contexto
 let contexto: Contexto = ...
 for frase in contexto.frasesArray {
     print(frase.frase ?? "")
 }
 */


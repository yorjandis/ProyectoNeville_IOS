//
//  FrasesRelacionadasModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/1/26.
//

import Foundation
import CoreData
import Combine

@MainActor
final class FrasesRelacionadasModel : ObservableObject {
    
    static var shared = FrasesRelacionadasModel()
    
    @Published var updateUI: UUID = UUID() //Muestra/oculta el panel de frases relacionadas
    
    
    private init(){
        
    }
}


//Listado de Frases Relacionadas
extension Frases {
        var relacionadasArray: [Frases] {
            let set = relacionadas as? Set<Frases> ?? []
            return set.sorted { $0.localizedText < $1.localizedText }
        }
}

//Añadir/Quitar Relaciones (SIMÉTRICO):
//Esto es obligatorio para coherencia
extension Frases {

    func vincularCon(_ otra: Frases) {
        guard otra != self else { return }

        self.addToRelacionadas(otra)
        otra.addToRelacionadas(self)
    }

    func desvincularDe(_ otra: Frases) {
        self.removeFromRelacionadas(otra)
        otra.removeFromRelacionadas(self)
    }

    func eliminarTodasLasRelaciones() {
        relacionadasArray.forEach { desvincularDe($0) }
    }
}

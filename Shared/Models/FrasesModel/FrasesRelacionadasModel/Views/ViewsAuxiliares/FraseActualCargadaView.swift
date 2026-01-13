//
//  FraseActualCargada.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/1/26.
//

//Vista del tab: FraseActual en el tab panel de relaciones

import SwiftUI



struct FraseActualCargadaView: View {
    
    let frase : Frases?
    
    var body: some View {
        VStack(spacing: 10){
            
            //Text(self.frase?.autor ?? "") //Muestra el Autor de la Frase
            
            Text(self.frase?.frase ?? "")
            
            Text(self.frase?.nota ?? "")
            
            //Eliminar todas las relaciones de la frase cargada
            Button("Eliminar Todas Las Relaciones"){
                frase?.eliminarTodasLasRelaciones()
            }
            .buttonStyle(.bordered)
            
        }
        
    }
    
    
}

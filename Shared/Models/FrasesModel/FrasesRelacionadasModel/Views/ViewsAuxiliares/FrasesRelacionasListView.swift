//
//  FrasesRelacionasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/1/26.
//

//Muestra la lista de frases relacionadas
/*
 Puedes:
     •    agrupar por autor
     •    mostrar badges
     •    navegar al detalle
 */

import SwiftUI



struct FrasesRelacionasListView: View {
    
    @Environment(\.managedObjectContext) var context

    let fraseMain : Frases?
    
    var body: some View {
        
        NavigationStack{
            
            VStack{
                if let frase = fraseMain {
                    if !frase.relacionadasArray.isEmpty  {
                        Section("Frases relacionadas") {
                            ScrollView{
                                ForEach(frase.relacionadasArray) { relacionada in
                                    Text(relacionada.frase ?? "")
                                        .contextMenu{
                                            Button("Eliminar Relación"){
                                                self.context.delete(relacionada)
                                                try? context.save()
                                                /*
                                                 ¿Qué hace Core Data automáticamente?
                                                 ✔️ Quita la frase de todas las relaciones
                                                 ✔️ No deja referencias rotas
                                                 ✔️ No necesitas limpiar nada
                                                 Gracias a Delete Rule = Nullify
                                                 */
                                            }
                                            
                                        }
                                }
                            }
                            
                        }
                    }
                }
            }

        }
        
        
    }
}

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

    @ObservedObject var fraseMain: Frases
    
 
    
    
    var body: some View {
        
        NavigationStack{
            ZStack{
                
                ColorGradientFrasesRelacionas.backgroundGradient
                    .ignoresSafeArea()
                
                VStack{
                    if !fraseMain.relacionadasArray.isEmpty  {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(fraseMain.relacionadasArray) { relacionada in
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(relacionada.localizedText)
                                            .font(.title3)
                                            .bold()
                                            .foregroundStyle(.black)
                                        
                                        Text(relacionada.autor ?? "")
                                            .font(.footnote)
                                            .foregroundStyle(.black)
                                    }
                                    
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(ColorGradientFrasesRelacionas.cardGradient)
                                    .cornerRadius(14)
                                    .shadow(
                                        color: Color.black.opacity(0.15),
                                        radius: 6,
                                        x: 0,
                                        y: 4
                                    )
                                    .contextMenu {
                                        Button("Remover Relación") {
                                            relacionada.desvincularDe(fraseMain)
                                            try? context.save()
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    
                }
                
            }
           

        }
        
        
    }
}

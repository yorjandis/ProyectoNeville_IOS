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
    @State private var showNota : Bool = false
    

    var body: some View {
        
        ZStack{
            ColorGradientFrasesRelacionas.backgroundGradient
                .ignoresSafeArea()
            ScrollView{
                VStack{
                    VStack(alignment: .leading,spacing: 8){
                        Text(self.frase?.frase ?? "").font(.title3).bold().fontDesign(.serif)
                        Text( "\(self.frase?.autor ?? "")") //Muestra el Autor de la Frase
                        
                        if showNota {
                            Text("Nota:\(self.frase?.nota ?? "")")
                        }
                    }
                    .foregroundStyle(.black)
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
                        
                    HStack{
                            Spacer()
                            Button{
                                withAnimation {
                                    self.showNota.toggle()
                                }
                                
                            }label:{
                                Image(systemName:  self.showNota ? "eye.slash.circle" : "eye.circle")
                            }
                            .padding(5)
                            .buttonStyle(.plain)
                            
                        }
                }
                .padding()
            }

            Spacer()
        }
        .contextMenu{
            Button("Remover todas las relaciones"){
                frase?.eliminarTodasLasRelaciones()
            }
        }
        
        
        
    }
    
    
}

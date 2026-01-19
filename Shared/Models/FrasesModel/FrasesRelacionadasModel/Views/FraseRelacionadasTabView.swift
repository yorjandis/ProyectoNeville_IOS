//
//  TabPanelFrases.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/1/26.
//

//Esta vista mostrará un panel con dos tab: Frase actual y Tab: Relaciomadas

import SwiftUI


struct FraseRelacionadasTabView: View {
    
       @ObservedObject var frase: Frases

        @Binding var showTabViewFrasesRelac: Bool //Oculta/muestra el panel de edición de Frases Relacionadas
    
        @Binding var ModoListado: Bool //Oculta/muestra el modo listado en el padre

       @State private var showPanelFraseMain: Bool = true
    
    
    var body: some View {
        
        NavigationStack{
            VStack{
                if showPanelFraseMain{
                    VStack{
                        FraseActualCargadaView(frase: frase )
                    }
                }else{
                    VStack{
                        FrasesRelacionasListView(fraseMain: frase)
                    }
                   
                }
                //Listado de Opciones
                HStack{
                    //Muestra/oculta el listado de frases relacionadas en la pantalla principal de lista de Frases
                    if frase.relacionadas?.count ?? 0 > 0{
                        Button("Listado"){
                            withAnimation {
                                self.showPanelFraseMain = true
                                self.ModoListado = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.primary)
                        .tint(.black.opacity(0.8))
                    }
                    
                    
                    //Muestra La frase Main
                    if !self.ModoListado{
                        Button("Frase"){
                            withAnimation {
                                self.showPanelFraseMain = true
                            }
                        }
                        .foregroundStyle(self.showPanelFraseMain ? Color.blue : .gray )
                        .buttonStyle(.bordered)
                        .tint(.black.opacity(0.8))
                    }
                    
                    //Muestra la lista de frases relacionadas en modo edición
                    if !self.ModoListado {
                        Button("Relaciones(\(frase.relacionadas?.count ?? 0))"){
                            withAnimation {
                                self.showPanelFraseMain = false
                            }
                        }
                        .foregroundStyle(self.showPanelFraseMain ? .gray : Color.blue )
                        .buttonStyle(.bordered)
                        .tint(.black.opacity(0.8))
                    }
                    
                    
                    
                    Spacer()
                    //Botón Atras:
                    Button{
                        if self.ModoListado {
                            withAnimation {
                                self.ModoListado = false
                            }
                            
                        }else{
                            withAnimation {
                                self.showTabViewFrasesRelac = false
                                self.ModoListado = false
                            }
                        }
                        
                       
                    }label:{
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
                .padding(.horizontal, 5)
                Spacer()
            }
            
            
        }
    }
    
    
}



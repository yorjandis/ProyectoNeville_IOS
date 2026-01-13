//
//  TabPanelFrases.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 12/1/26.
//

//Esta vista mostrará un panel con dos tab: Frase actual y Tab: Relaciomadas

import SwiftUI


struct FraseRelacionadasTabView: View {
    
    let frase : Frases?
    
    
    var body: some View {
        
        NavigationStack{
            
            TabView{
                FraseActualCargadaView(frase: frase )
                    .tabItem {
                        Label("Frase actual", systemImage: "text.bubble")
                    }
                
                FrasesRelacionasListView(fraseMain: frase)
                    .tabItem {
                        Label("Frases Relacionadas", systemImage: "arrow.2.circlepath.circle")
                    }
            }
        }
    }
    
    
}



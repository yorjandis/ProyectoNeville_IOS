//
//  FrasesRelacionadasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/1/26.
//

import SwiftUI
import CoreData


struct FrasesMainListRelacionadas : View {
    
    @ObservedObject var fraseMain: Frases
    
    
    var body: some View {
        VStack{
            ScrollView{
                FraseActualCargadaView(frase: self.fraseMain)
            }
            .frame(height: 150)
            
            Divider()
                .padding(5)
            FrasesRelacionasListView(fraseMain: self.fraseMain)
            
            Spacer()
        }
        
        
    }
    
}

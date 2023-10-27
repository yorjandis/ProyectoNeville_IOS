//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

struct optionView: View {

    @State var showNotasSheet = false
    @State var showFavSheet = false
    @State var showFrasesNotes = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.brown, .gray], startPoint: .topLeading, endPoint: .bottomTrailing)
                
                VStack(spacing: 20){
                    HStack(spacing: 20){
                        Button{
                            
                        }label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Setting")
                            }
                        }.modifier(GradientButtonStyle(ancho: 150))
                        
                        Button{
                            showNotasSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Notas")
                            }
                        }.modifier(GradientButtonStyle(ancho: 150))
                        
                    }
                    
                    HStack(spacing: 20){
                        
                        Button{
                        showFavSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "heart")
                                Text("Favoritos")
                            }
                        }.modifier(GradientButtonStyle(ancho: 150))
                        
                        Button{
                            showFrasesNotes = true
                        }label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Notas Frases")
                            }
                        }.modifier(GradientButtonStyle(ancho: 150))
                        
                    }
                    
                    
                    
                }
            }
            .sheet(isPresented: $showNotasSheet) {
                ListNotasViews()
            }
            .sheet(isPresented: $showFavSheet) {
                ListFavView()
            }
            .sheet (isPresented: $showFrasesNotes){
                FrasesNotasListView()
            }
        }
 
    }
    
    
   
}

#Preview {
    optionView()
}

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
                        }.modifier(GradientButtonStyle(ancho: 100))
                        
                        Button{
                            showNotasSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Notas")
                            }
                        }.modifier(GradientButtonStyle(ancho: 100))
                        
                    }
                    HStack(spacing: 20){
                        
                        Button{
                        showFavSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "heart")
                                Text("Favoritos")
                            }
                        }.modifier(GradientButtonStyle(ancho: 100))
                        
                        Button{
                            
                        }label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Otros")
                            }
                        }.modifier(GradientButtonStyle(ancho: 100))
                        
                    }
                    
                    
                    
                }
            }
            .sheet(isPresented: $showNotasSheet) {
                ListNotasViews()
            }
            .sheet(isPresented: $showFavSheet) {
                ListFavView()
            }
        }
 
    }
    
    
   
}

#Preview {
    optionView()
}

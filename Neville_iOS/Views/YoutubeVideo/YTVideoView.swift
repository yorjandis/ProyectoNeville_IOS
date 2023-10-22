//
//  YoutubeVideoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Pantalla que mostrará uno o más Videos de Youtube
    //Acepta un arreglo de estructuras de tipo ItemVideoYoutube

import SwiftUI

struct YTVideoView: View {
    @Environment(\.dismiss) var dimiss
    
    @State var showProgress : Bool = true
   
    
    var items : [ItemVideoYoutube] //array de struct ItemVideoYoutube

    var body: some View {
        VStack {
            List{
                ForEach (items, id: \.self) {item in
                    VStack {
                        VideoViewModel(youtubeID: item.id)
                            .frame(width: 300, height: 200)
                            .cornerRadius(12)
                            .overlay { //Crea una capa superficial con una barra de progreso
                                if showProgress {ProgressView("Cargando...")}
                                
                            }
                            .onAppear{ //Oculta la barra de progreso pasado 1 segundo
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showProgress = false
                                }
                            }
                            
                        Text(item.title)
           
                    }
                    .padding(20)

                }
            }
            Spacer()
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                //Show/Hide the fav button
                Button{
                    dimiss()
                }label: {
                    Text("Volver")
                }
                .padding(.trailing, 25)
                .padding(.top, 10)
                
            }
            
        }
        
    }
}

#Preview {
    ContentView()
}

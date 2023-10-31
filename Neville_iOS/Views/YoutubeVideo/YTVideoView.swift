//
//  YoutubeVideoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Pantalla que mostrará uno o más Videos de Youtube
    //Acepta un arreglo de estructuras de tipo ItemVideoYoutube para mostrar varios videos
//El botón de favorito, conyrolada por la propiedad "isSingleVideo" en esta vista se oculta si se esta mostrando varios videos.

import SwiftUI

struct YTVideoView: View {
    @Environment(\.dismiss) var dimiss
    
    @State private var showProgress : Bool = true
    @State private var  isFav : Bool = false //color del image fav
    @EnvironmentObject var netMonitor : NetworkMonitor
    @State private var showAlert = false
   
    var items : [ItemVideoYoutube] //array de struct ItemVideoYoutube
    
    let showFavIcon : Bool  //true : se esta mostrando 1 video, false se muestra varios videos. esto permite mostrar u ocultar el boton de favorito
    

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
                                if !netMonitor.isConnected {
                                    showAlert = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    showProgress = false
                                }
                            }
                            
                        Text(item.title)
           
                    }
                    .padding(20)

                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Neville"),
                    message: Text("El contenido de esta sección requiere conección a internet")
                )
            }
            Spacer()
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                //Show/Hide the fav button
                if showFavIcon {
                    Button{
                        setFav() //Alterna entre fav/No fav
                        ifFav() //Actualiza el estado de favorito
                    }label: {
                        Image(systemName: "heart.fill")
                            .tint(isFav ? .orange : .gray)
                    }
                    .onAppear { //Leyendo el estado del Fav y ajustando color del icono
                        ifFav()
                    }
                }
                
                //button back:
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
    
    //Alterna entre los estados de fav/NO fav
    private  func setFav(){
       if isFav {
           if !FavModel().DeleteVideos(title: items[0].title, idVideo: items[0].id){print("error delete in FavTxt")}
        }else{
            if !FavModel().Add(title: items[0].title, prefix: "", idvideo: items[0].id){
                print("error add in FavTxt")
            }
        }
    }
    
    //Determina si el video es favorito y ajusta la variable isFav
    private func ifFav(){
        if FavModel().isFavVideos(title: items[0].title, idVideo: items[0].id){
            isFav = true
        }else {
           isFav = false
        }
    }
    
}

#Preview {
    ContentView()
}

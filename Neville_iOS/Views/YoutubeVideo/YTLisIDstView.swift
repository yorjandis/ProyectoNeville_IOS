//
//  IDYoutubeListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Muestra un listado de IDs de videos de youtube y los lanza
//La variable typeContent indica el tipo de contenido a cargar

import SwiftUI

struct YTLisIDstView: View {
    
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    
    var typeContent : TypeOfContent = .NA //Tipo de contenido a cargar
    
    @State private var ListOfVideosID : ([[String]]) = [[String]]()
    
    @State private var ListOfVideosIds : [[String]] = []
    
    
    
    var body: some View {
        
        NavigationStack{
            List(ListOfVideosID, id: \.[0]){ idx in
                HStack{
                    Image(systemName: "video.fill")
                        .padding(.horizontal, 5)
                        .foregroundStyle(FavModel().isFav(nameFile: idx[1], prefix: typeContent.getPrefix) ? .orange : .gray)
                    
                    NavigationLink{
                        YTVideoView(items: ItemVideoYoutube(id: idx[0], title: idx[1], prefix: typeContent).getInfo(), showFavIcon: true)
                    }label: {
                        Text(idx[1].capitalized(with: .autoupdatingCurrent))
                            .bold()
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)       
                    }
                }
                .swipeActions(edge: .trailing){
                    Button("Favorito"){
                        setFav(nameFile: idx[1], prefix: typeContent.getPrefix, idVideo: idx[0])
                        
                        getVideosList()
                    }
                }.tint(.orange)
                
            }
            .onAppear {
                getVideosList()
            }
            
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                
                Button{dimiss()
                }label: {
                    Text("Volver")
                }
                .padding(.trailing, 25)
                .padding(.top, 10)
                
            }
            .navigationTitle(typeContent.getDescription)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    ///Auxiliar: actualiza el estado de favoritos
    private func setFav(nameFile: String , prefix : String, idVideo : String){
        if FavModel().isFav(nameFile: nameFile, prefix: typeContent.getPrefix){
            FavModel().Delete(nameFile: nameFile, prefix: typeContent.getPrefix)
        }else{
            FavModel().Add(nameFile: nameFile, prefix: typeContent.getPrefix, idvideo: idVideo)
        }
    }
    
    ///Auxiliar: Recarga el listado
    private func getVideosList(){
        ListOfVideosID.removeAll()
        ListOfVideosID = UtilFuncs.getListVideoIds(typeContent)
    }

}




#Preview {
    ContentView()
}

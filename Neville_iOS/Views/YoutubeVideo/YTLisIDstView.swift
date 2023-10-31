//
//  IDYoutubeListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Muestra un listado de IDs de videos de youtube y los lanza
//La variable typeContent indica el tipo de contenido a cargar
//La variable ListOfVideosIds Almacena el listado

import SwiftUI

struct YTLisIDstView: View {
    
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    
    var typeContent : TypeIdVideosYoutube = .NA //Tipo de contenido a cargar
    
    @State private var ListOfVideosIds : [(String, String)] = []
    
    @State var fontSizeList : CGFloat = 18
    
    var body: some View {
        
        NavigationStack{
            List(ListOfVideosIds, id: \.0){ idx in
                HStack{
                    Image(systemName: "video.fill")
                        .padding(.horizontal, 5)
                        .foregroundStyle(FavModel().isFavVideos(title: idx.1, idVideo: idx.0) ? .orange : .gray)
                    
                    NavigationLink{
                        YTVideoView(items: [ItemVideoYoutube(id: idx.0, title: idx.1)], showFavIcon: true)
                    }label: {
                        Text(idx.1.capitalized(with: .autoupdatingCurrent))
                            .bold()
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)    
                            .font(.system(size: CGFloat(fontSizeList)))
                    }
                }
                .swipeActions(edge: .trailing){
                    Button("Favorito"){
                       setFav(title: idx.1, prefix: "" , idVideo: idx.0)
                        
                       getVideosList(typecontent: typeContent)
                    }
                }.tint(.orange)
                
            }
            .onAppear {
                getVideosList(typecontent: typeContent)
                fontSizeList = CGFloat(UserDefaults.standard.integer(forKey: Constant.setting_fontListaSize))//setting
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
            .navigationTitle(typeContent.getTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    ///Auxiliar: actualiza el estado de favoritos
    private func setFav(title: String , prefix : String, idVideo : String){
        if FavModel().isFavVideos(title: title, idVideo: idVideo){
            if FavModel().DeleteVideos(title: title, idVideo: idVideo){}
        }else{
            if FavModel().Add(title: title, prefix: "", idvideo: idVideo){}
       }
    }
    
    ///Auxiliar: Recarga el listado
    private func getVideosList(typecontent : TypeIdVideosYoutube){
        ListOfVideosIds.removeAll()
        ListOfVideosIds = UtilFuncs.GetIdVideosFromYoutube(typeContent: typecontent)
    }

}




#Preview {
    ContentView()
}

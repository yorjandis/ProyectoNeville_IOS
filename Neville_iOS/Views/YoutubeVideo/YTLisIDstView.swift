//
//  IDYoutubeListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Muestra un listado de IDs de videos de youtube y los lanza

import SwiftUI

struct YTLisIDstView: View {
    
    @Environment(\.dismiss) var dimiss
    
    var typeContent : TypeOfContent = .NA //Tipo de contenido a cargar
    
    @State private var ListOfVideosID : [[String]] = Array()
    
    
    
    var body: some View {
        
        NavigationStack{
            List(ListOfVideosID, id: \.[0]){ idx in
                HStack{
                    NavigationLink{
                        YTVideoView(items: ItemVideoYoutube(id: idx[0], title: idx[1]).getInfo())
                    }label: {
                        UiViewmaker(nameFile: idx[1], prefix: idx[0])
                    }
                }
                .swipeActions(edge: .trailing){
                    Button("Favorito"){
                        //conmuta entre los estados de fav
                        ListOfVideosID.removeAll()
                        if FavModel().isFav(nameFile: idx[1], prefix: idx[0]) {
                            FavModel().Delete(nameFile: idx[1], prefix: idx[0])
                            
                        }else { // Si no esta en la BD:
                            FavModel().Add(nameFile: idx[1], prefix: idx[0])
                        }
                        //Actualiza el listado
                        
                        ListOfVideosID = UtilFuncs.getListVideoIds2(typeContent)
                    }
                }.tint(.orange)
                
            }
            .onAppear{
                ListOfVideosID = UtilFuncs.getListVideoIds2(typeContent)
            }
            
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                //Show/Hide the fav button
                Button{dimiss()
                }label: {
                    Text("Volver")
                }
                .padding(.trailing, 25)
                .padding(.top, 10)
                
            }
            .navigationTitle(typeContent.getTitleOfContent)
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
}
            
        
        
        //View para Item de video
        struct UiViewmaker : View{
            @Environment(\.colorScheme) var theme
            let nameFile : String
            let prefix : String
            
            
            var body: some View{
                VStack(alignment: .leading){
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundStyle(FavModel().isFav(nameFile: nameFile, prefix: prefix) ? .orange : .gray)
                            .padding(.horizontal, 5)
                        
                        Text(nameFile.lowercased())
                            .bold()
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                        
                    }
                    .padding(10)
                }
                
            }
        }
        
    //}
    



#Preview {
   ContentView()
}

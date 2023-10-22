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
    
    
    
    var body: some View {
        
        NavigationStack{
                    List{
                            ForEach(UtilFuncs.getListVideoIds2(typeContent), id: \.[0]){ idx in
                                HStack{
                                    NavigationLink{
                                        YTVideoView(items: ItemVideoYoutube(id: idx[0], title: idx[1]).getInfo())
                                    }label: {
                                        UiViewmaker(value: idx[1])
                                    }
                                }
                                .swipeActions(edge: .trailing){
                                    Button("Favorito"){
                                        //code: marca/Desmarca fav
                                        //El efecto se ve en el color del icono del item
                                        
                                    }
                                }.tint(.orange)
                                
                            }
                            //.listRowSeparator(.hidden)
  
                        }
                        .background(.ultraThinMaterial)
   
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
                    
                }
                .navigationTitle(typeContent.getTitleOfContent)
                .navigationBarTitleDisplayMode(.inline)
            }
            
            
        
        
        //View para Item de video
        struct UiViewmaker : View{
            @Environment(\.colorScheme) var theme
            let value : String
            
            var body: some View{
                VStack(alignment: .leading){
                    HStack {
                        Image(systemName: "video.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .padding(.horizontal, 5)
                        
                        Text(value.lowercased())
                            .bold()
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                        
                    }
                    .padding(10)
                }
                
            }
        }
        
    }
    



#Preview {
   ContentView()
}

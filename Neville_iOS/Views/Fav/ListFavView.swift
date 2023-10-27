//
//  ListFavView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//
//Listado de favoritos registrados en la tabla FavTxt

import SwiftUI
import CoreData

struct ListFavView: View {
    @Environment(\.dismiss) var dimiss
    @State var ButtonActive: Bool = true //true para frase, false para otros
    
    @State  private var arrayTxt : [FavTxt] = FavModel().getAllFavTxt()
    @State  private var arrayFrases : [Frases] = manageFrases().getFavFrases()
    @State  private  var showSheetContentTxt = false


    var body: some View {
        NavigationStack{     
            VStack{
                HStack(spacing: 40){
                    Button("Frases"){
                        ButtonActive = true //Activa el botón
                    }
                    .modifier(ButtonActive ?  GradientButtonStyle(ancho: 80) : GradientButtonStyle(ancho: 80, colors: [.gray, .brown]) )
                    
                    Button("Otros"){
                        ButtonActive = false //Activa el botón
                    }
                        .modifier(ButtonActive ?  GradientButtonStyle(ancho: 80, colors: [.gray, .brown]) : GradientButtonStyle(ancho: 80) )
                }
                
                Divider()
                
                //
                if (ButtonActive){
                    List(arrayFrases){item in
                        Text(item.frase ?? "")
                            .swipeActions(edge: .trailing){
                                Button("Quitar Favorito"){
                                    manageFrases().updateFavState(fraseID: item.id ?? "", statusFav: false)
                                    withAnimation {
                                        arrayFrases.removeAll()
                                        arrayFrases = manageFrases().getFavFrases()
                                    }
                                    
                                }
                                .tint(.red)
                            }
                        
                    }
                    
                }else{
                    List(arrayTxt){item in
                        RowTxt(item: item, array: $arrayTxt)
                            .swipeActions(edge: .trailing){
                                Button("Quitar Favorito"){
                                    FavModel().Delete(nameFile: item.namefile?.lowercased() ?? "", prefix: item.prefix ?? "")
                                    withAnimation {
                                        arrayTxt.removeAll()
                                        arrayTxt = FavModel().getAllFavTxt()
                                    }       
                                }
                                .tint(.red)
                            }
                            
                    }
                    
                }
                
                Spacer()
                Divider()
                HStack(spacing: 30){
                    Spacer()
                    Button("Volver"){
                        dimiss()
                    }
                    .padding(.trailing, 20)
                }.padding(.bottom, 20)
            }
            .padding(.top,20)
            .navigationTitle("Favoritos")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
    

    
    //Item de fichero txt
    //recibe como parámetros la entity actual y el arreglo de entity totales
    struct RowTxt : View{
        let item : FavTxt //El identity actual
        @Binding var array : [FavTxt]
        
        //Obtiene el valor TypeOfContent a partir del nombre del prefijo (Yor esto debe mejorarse en un futuro)
        private var TypeContent : TypeOfContent{
            switch item.prefix{
            case "conf_" : return .conf
            case "ayud_" : return .ayudas
            case "cita_" : return .citas
            case "preg_" : return .preguntas
                
            case "video Conf" : return .video_Conf
            case "audio Libros" : return .aud_libros
            case "gregg" : return .vide_gregg
                
            default: return .NA
                
            }
            
            
        }

        var body: some View{
                NavigationLink{
                    
                    //Abre un txt o Inicia un video, segun:
                    switch TypeContent {
                    case .conf, .ayudas, .citas, .preguntas:
                        ContentTxtShowView(fileName: item.namefile ?? "", title: item.namefile ?? "", typeContent: TypeContent)
                    default:
                        YTVideoView(items: [ItemVideoYoutube(id: item.idvideo ?? "", title: item.namefile ?? "", prefix: TypeContent )], showFavIcon: true)
                    }
 
                }label: {
                    VStack(alignment: .leading){
                        Text("\(item.namefile ?? "")")
                            .textInputAutocapitalization(.words)
                        Text("\(item.prefix ?? "")")
                            .font(.caption2)
                            .padding(.top, 3)
                    }
                    
                }
        }
    }
}

#Preview {
    ContentView()
}

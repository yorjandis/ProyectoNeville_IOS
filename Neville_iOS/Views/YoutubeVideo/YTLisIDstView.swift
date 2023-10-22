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
    @Environment(\.colorScheme) var theme

    enum TypeContent : String{
        case videoConf      = "listidvideoconf"
        case audioLibros    = "listidaudiolibros"
        case greegg         = "listidgregg"
        
        var description : String{
            switch self {
            case .videoConf: return "Video Conferencias"
            case .audioLibros: return "Audio Libros"
            case .greegg: return "Videos de Gregg Braden"
            }
        }
    }
    
    var typeContent : TypeContent //Tipo de contenido a cargar
    
    var body: some View {
        
        
        VStack{
            ScrollView {
                VStack {
                    ForEach(getList().sorted(by: >), id: \.key) { key, value in
                        NavigationLink{
                            YTVideoView(items: ItemVideoYoutube(id: key, title: value).getInfo())
                        }label: {
                            UiViewmaker(value: value)
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .padding(.top, 15)
            }
                
                
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
        .navigationTitle(typeContent.description)
        
    }
    
 
    
    func UiViewmaker(value : String)-> some View{
        return VStack(alignment: .leading){
            HStack {
                Image(systemName: "video.fill")
                    .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                    .padding(.horizontal, 5)
                
                Text(value.lowercased())
                    .bold()
                    .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                
            }
            Divider()
        }
        .padding(.leading, 20)
        .padding(.vertical, 5)
            
    }

    //Devuelve un diccionario de pares: IDvideo:TitleOfVideo
    func getList()->[String:String]{
        
        var result = [String: String]() //dic
        var temp = [String]() //array linea del txt: "ID::Title"
        var temp2 = [String]() //array contiene cada parte: [0]=ID, [1]=title
        
        
        temp = UtilFunc.ReadFileToArray(typeContent.rawValue)
        for idx in temp {
            temp2 = idx.components(separatedBy: "::")
            result[temp2[0]] = temp2[1]
        }
        
        return result
        
    }
    
    
}

#Preview {
   ContentView()
}

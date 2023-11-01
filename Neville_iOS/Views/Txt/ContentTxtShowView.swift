//
//  ContentTxtShow.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//
//Muestra un contenido txt en pantalla


import SwiftUI
import AVFoundation

struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) var dimiss
    @State  var fileName : String //Nombre del txt a abrir
    @State var  title : String = ""
    var typeContent : TypeOfTxtContent = .NA //tipo de txt (conf, ayuda, etc)
    @State private var isFav = false
    
    @State private var fontSizeContent : CGFloat = 18 // Setting
    

    //Lee un fichero txt y devuelve su contenido
    var getContent : String {
        return FileRead(fileName)
    }

    var body: some View {
        NavigationStack {
            
            VStack {
                ScrollView(showsIndicators: true) {
                    Text(self.getContent)
                        .font(.system(size: fontSizeContent, design: .rounded))
                        .fontDesign(.rounded)
                        .padding(.trailing, 20)
            
                }
                .padding(.horizontal, 10)
                
                Divider()
                
                //Barra Inferior (Permitir volver, favorito, etc)
                HStack( spacing: 30){
                    Spacer()
                    
                        Button{
                            setFav() //Alterna entre fav/No fav
                            ifFav() //Actualiza el estado de favorito
                        }label: {
                            Image(systemName: "heart.fill")
                                .tint(isFav ? .orange : .gray)
                        }
                        

                    Button{
                        
                        dimiss()
                    }label: {
                        Text("Volver")
                    }
                    .padding(.trailing, 30)
                    
 
                }
                .padding(10)
    
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { //Al inicio se actualiza el estado del fav
                ifFav()
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: Constant.setting_fontContentSize))
            }
            
        }
    }//body
    
    //Lee el contenido del TXt
   private func FileRead(_ file : String)->String{
        
        var result = ""
       let temp = "\(typeContent.getPrefix)\(file.lowercased())"
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            
            if let fileContens = try? String(contentsOf: gg){
                result = fileContens
            }
            
        }
        
        return result
        
    }
    
    //Determina si un elemento es fasvorito
    private func ifFav(){
        if FavModel().isFavTxt(title:fileName.lowercased(), prefix: typeContent.getPrefix){
            isFav = true
        }else {
            isFav = false
        }
    }
    
    //Alterna entre los estados de fav/NO fav
   private  func setFav(){
        if isFav {
            if !FavModel().DeleteTXT(title:fileName.lowercased(), prefix: typeContent.getPrefix){print("error delete in FavTxt")}
        }else{
            if !FavModel().Add(title:fileName.lowercased(), prefix: typeContent.getPrefix){
                print("error add in FavTxt")
            }
        }
    }
    
}

#Preview {
    ContentTxtShowView( fileName: String(""))
}

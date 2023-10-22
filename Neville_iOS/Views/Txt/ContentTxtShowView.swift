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
    var typeContent : TypeOfContent = .NA //tipo de txt (conf, ayuda, etc)
    @State private var isFav = false
    
    
    

    //Lee un fichero txt y devuelve su contenido
    var getContent : String {
        return FileRead(fileName)
    }

    var body: some View {
        NavigationView {
            
            VStack {
                ScrollView(showsIndicators: true) {
                    Text(self.getContent)
                        .font(.system(size: 24, design: .rounded))
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
                        .onAppear { //Al inicio se actualiza el estado del fav
                            ifFav()
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
            
        }
    }//body
    
    //Lee el contenido del TXt
   private func FileRead(_ file : String)->String{
        
        var result = ""
       let temp = "\(typeContent.getPrefix)\(file.lowercased())"
       
       print("yor: \(typeContent.getPrefix)\(file.lowercased())")
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            
            if let fileContens = try? String(contentsOf: gg){
                result = fileContens
            }
            
        }
        
        return result
        
    }
    
    //Determina si un elemento es fasvorito
    private func ifFav(){
        if FavModel().isFav(nameFile:fileName.lowercased(), prefix: typeContent.getPrefix){
            isFav = true
        }else {
            isFav = false
        }
    }
    
    //Alterna entre los estados de fav/NO fav
   private  func setFav(){
        if isFav {
            if !FavModel().Delete(nameFile:fileName.lowercased(), prefix: typeContent.getPrefix){print("error delete")}
        }else{
            if !FavModel().Add(nameFile:fileName.lowercased(), prefix: typeContent.getPrefix){
                print("error add")
            }
        }
    }
    
}

#Preview {
    ContentTxtShowView( fileName: String(""))
}

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
    var typeContent : TxtContentModel.TipoDeContenido = .NA
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
                        
                        dimiss()
                    }label: {
                        Text("Atrás")
                    }
                    .padding(.trailing, 30)
                    
 
                }
                .padding(10)
    
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: Constant.UD_setting_fontContentSize))
            }
            
        }
    }//body
    
    //Lee el contenido del TXt
   private func FileRead(_ file : String)->String{
        
        var result = ""
       let temp = "\(typeContent.rawValue)\(file.lowercased())"
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            
            if let fileContens = try? String(contentsOf: gg){
                result = fileContens
            }
            
        }
        
        return result
        
    }
    
    
}

#Preview {
    ContentView()
}

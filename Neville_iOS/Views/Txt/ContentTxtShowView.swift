//
//  ContentTxtShow.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//
//Muestra un contenido txt en pantalla

import Foundation
import SwiftUI
import CoreData
import AVFoundation


struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) var dimiss
    
    @State var synthesizer = AVSpeechSynthesizer()
    
    //Para leer ficheros txt con prefijos
    var entidad : TxtCont = TxtCont(context: CoreDataController.dC.context)
    
    //Si typeContent es .NA se deben de proveer estos campos
    @State  var fileName : String = "" //Nombre del txt a abrir
    @State var  title : String = ""
    
    //Setting: Tamaño de fuente por defecto
    @State private var fontSizeContent : CGFloat = 18

    @AppStorage(Constant.UD_setting_fontContentSize)  var fontSizeContenido  = 18


    

    //Lee un fichero txt que no tenga prefijo. Hay que pasar como typeContent .NA
    //Esto permite mostrar ficheros de texto como biografia o las imágines
    var getContent : String {
        //Yor aqui va el código para leer el contenido del fichero
        if fileName == "" {
            return UtilFuncs.FileRead("\(entidad.type ?? "")" + "\(entidad.namefile ?? "")")
        }else{
            return UtilFuncs.FileRead(fileName)
        }
        
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
                HStack(spacing: 30){
                    Spacer()
                    
                    Button{
                        let texto = self.getContent
                        let utterance = AVSpeechUtterance(string: texto)
                        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
                        //utterance.rate = 0.4

                        synthesizer.speak(utterance)
                    }label: {
                        Image(systemName: "speaker.wave.3")
                    }
                    
                    Slider(value: $fontSizeContent, in: 18...30) { Bool in
                        fontSizeContenido = Int(fontSizeContent)
                    }

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
                fontSizeContenido = Int(self.fontSizeContent)
            }
            .toolbar{
                HStack{
                    Spacer()
                    if self.fileName.isEmpty {
                        Menu{
                            NavigationLink("Añadir nota asociada"){
                                EditNoteTxtContentTxtShow(entidad: self.entidad)
                            }
                        }label: {
                            Image(systemName: "plus")
                        }
                    }
                    
                }
            } 
        }
    }//body
}


//Permite ver y editar el campo notya
struct EditNoteTxtContentTxtShow:View {
    @Environment(\.dismiss) var dimiss
    @State var entidad : TxtCont
    @State private var textfiel = ""

    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.gray, .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(){
                    TextField("Coloque su nota aqui", text: $textfiel, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .font(.title)
                        .foregroundStyle(.black).italic().bold()
                        .onAppear {
                            textfiel = entidad.nota ?? ""
                        }
                    
                    Spacer()
                }
            }
            .navigationTitle("Notas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Button{
                        TxtContentModel().setNota(entity: entidad, nota: textfiel)
                        dimiss()
                    }label: {
                        Text("Guardar")
                            .foregroundStyle(.black).bold()
                    }
                }
            }
            
        }
    }
}



#Preview {
    ContentView()
}

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
import RichText


struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) private var dimiss
    @Environment(\.managedObjectContext) private var context
    
    //Para leer ficheros txt con prefijos
    var entidad : TxtCont?
    
    let type : TxtContentModel.TipoDeContenido
    
    //Si typeContent es .NA se deben de proveer estos campos
    @State  var fileName    : String = "" //Nombre del txt a abrir
    @State  var  title      : String = ""   //Titulo
    
    //Setting: Tamaño de fuente por defecto
    @State private var fontSizeContent : CGFloat = 18

    @AppStorage(AppCons.UD_setting_fontContentSize)  var fontSizeContenido  = 18

    @State private var showSlider = false
    

    //Yor aqui va el código para leer el contenido del fichero
    var getContent : String {
        if self.type != .NA { //se ha pasado un fichero de prefijo
            if let entidadTemp = self.entidad {
                print("Yorj: Entidad: \(entidadTemp.type ?? "")" + "\(entidadTemp.namefile ?? "") ")
                return UtilFuncs.FileRead("\(entidadTemp.type ?? "")" + "\(entidadTemp.namefile ?? "")")
            }
        }else{
            if self.fileName != "" {
                print("Yorj:  Fichero: \(self.fileName)")
                return UtilFuncs.FileRead(fileName)
            }
        }
        return ""
    }

    var body: some View {
        NavigationStack {
            
            VStack {
                ScrollView(showsIndicators: true){
                   
                    RichText(html: self.getContent )
                        .colorScheme(.auto)
                        .fontType(.customName("Arial"))
                        .customCSS("*{font-size: \(self.fontSizeContent)px;}")
                        .padding(.horizontal, 5)
                    
                    /*
                    Text(self.getContent)
                        .font(.system(size: fontSizeContent, design: .rounded))
                        .fontDesign(.rounded)
                        .padding(.trailing, 20)
                        .textSelection(.enabled)
                    */
                }
                .padding(.horizontal, 10)
                
                
                Divider()
                
                //Barra Inferior (Permitir volver, favorito, etc)
                HStack(spacing: 30){
                    Spacer()
                    if showSlider {
                        HStack{
                            Button{
                                withAnimation(.easeInOut) {
                                    showSlider = false
                                }
                                
                            }label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            Slider(value: $fontSizeContent, in: 18...30) { Bool in
                                fontSizeContenido = Int(fontSizeContent)
                            }
                        }
                        .padding(.horizontal, 10)
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
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
                //Quitando la marca isnew
                if let ii = entidad {
                    if ii.isnew {
                        TxtContentModel().RemoveNewFlag(entity: entidad!)
                    }
                }
            }
            .toolbar{
                HStack{
                    Spacer()
                    
                        Menu{
                            if self.fileName.isEmpty {
                                Button("Marcar como Favorita"){
                                    if let enti = self.entidad {
                                        TxtContentModel().setFavState(context: self.context, entity: enti, state: true)
                                    }
                                }
                                NavigationLink("Añadir nota asociada"){
                                    if let enti = self.entidad {
                                        EditNoteTxtContentTxtShow(entidad: enti)
                                    }
                                }
                            }
                            Button("Tamaño de Letra", systemImage: "textformat") {
                                withAnimation(.easeInOut) {
                                    showSlider.toggle()
                                }
                            }
                        }label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(Angle(degrees: 135))
                        }
                    
                    
                }
            } 
        }
    }//body
}


//Permite ver y editar el campo nota
struct EditNoteTxtContentTxtShow:View {
    @Environment(\.dismiss) var dimiss
    @State var entidad : TxtCont
    @State private var textfiel = ""
    @Environment(\.managedObjectContext) var context

    
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
                        TxtContentModel().setNota(context: self.context , entity: entidad, nota: textfiel)
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

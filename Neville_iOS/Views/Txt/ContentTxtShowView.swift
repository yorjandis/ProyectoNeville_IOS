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


struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) private var dimiss
    
    
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
    

    //Lee un fichero txt que no tenga prefijo. Hay que pasar como typeContent .NA
    //Esto permite mostrar ficheros de texto como biografia o las imágines
    var getContent : String {
        //Yor aqui va el código para leer el contenido del fichero
        if fileName == "" {
            if let enti = self.entidad {
                return UtilFuncs.FileRead("\(enti.type ?? "")" + "\(enti.namefile ?? "")")
            }
        }else{
            return UtilFuncs.FileRead(fileName)
        }
        
        return ""
    }

    var body: some View {
        NavigationStack {
            
            VStack {
                ScrollView(showsIndicators: true) {
                    Text(self.getContent)
                        .font(.system(size: fontSizeContent, design: .rounded))
                        .fontDesign(.rounded)
                        .padding(.trailing, 20)
                        .textSelection(.enabled)
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
                    if self.fileName.isEmpty {
                        Menu{
                            Button("Marcar como Favorita"){
                                if let enti = self.entidad {
                                    TxtContentModel().setFavState(entity: enti, state: true)
                                }
                            }
                            NavigationLink("Añadir nota asociada"){
                                if let enti = self.entidad {
                                    EditNoteTxtContentTxtShow(entidad: enti)
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

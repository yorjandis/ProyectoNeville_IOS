//
//  ReflexShowTextView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import SwiftUI
import CoreData

struct ReflexShowTextView: View {
    
    @State var entity : RefType
    
    @State private var fontSizeContent : CGFloat = 18
    @State private var showSlider = false
    
    @EnvironmentObject private var modelReflex : ReflexModel


    @AppStorage(AppCons.UD_setting_fontContentSize)  var fontSizeContenido  = 18
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading){
                
                    VStack(alignment: .leading){
                        Text(entity.title)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                        
                        Text("Autor: \(entity.autor)")
                            .font(.body)
                    }
                    .padding(.horizontal, 10)

                VStack(alignment: .leading){
                    HStack{
                        ScrollView{
                            #if os(macOS)
                            Text(entity.content)
                                .font(.system(size: self.fontSizeContent))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                                .padding(.horizontal, 5)
                            #else
                            SelectableText(entity.content, fontSize: self.fontSizeContent,fonColor: UIColor(Color.primary) ,  alignment: .left)
                            #endif
                            
                        }.scrollIndicators(.automatic)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    }
            }
            
                Divider()
                HStack{
                    Spacer()
                    //Mostrar un control de ajuste para el tamaño de la letra
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
                        .padding(.horizontal, 15)
                    }
                }
                .navigationTitle("Reflexiones")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                #if os(macOS)
                
                ToolbarItem {
                    Button{
                        var favState = modelReflex.getFavState(title: self.entity.title)
                        favState.toggle()
                        if modelReflex.setFavState(title: self.entity.title, state: favState){
                            //Actualizar el listado
                            withAnimation {
                                modelReflex.getArrayReflexOfTxtFile()
                            }
                        }
                    }label: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(modelReflex.getFavState(title: self.entity.title) ? .orange : .gray)
                    }
                }
                
                
                //Añadir un boton para cerrar la ventana modal
                ToolbarItem(placement: .navigation) {
                    Button{
                        if let window = NSApp.keyWindow {
                            window.sheetParent?.endSheet(window)
                        }
                    }label:{
                        Label("Cerrar", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    .help("Cerrar")
                }
                #endif
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
                
                //Opciones de IA
                if #available(iOS 26.0, macOS 26.0, *){
                    if IAModelAppleIntelligence.isAvailable(){
                        ToolbarItem {
                            Menu{
                                NavigationLink{
                                    
                                    RespondView(nameConference: "", texto: entity.content, tipoSalida: .interpretar )
                                   
                                    
                                }label:{
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                                NavigationLink{
                                    RespondView(nameConference: "", texto: entity.content, tipoSalida: .practicaConcreta)
                                }label:{
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                                NavigationLink{
                                    ChatView(textoACargar: entity.content)
                                }label: {
                                    Label("Charlar con IA", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                            }label:{
                                Image(systemName: "sparkles")
                            }
                            .tint(.purple)
                        }
                    }
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
                
                //Ajuste de tamaño de letra
                ToolbarItem {
                    Button("Tamaño de Letra", systemImage: "textformat") {
                        withAnimation(.easeInOut) {
                            showSlider.toggle()
                        }
                    }
                }
                
               
                
            }
            .onAppear {
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
            }
            
        }
    }
}

#Preview {
    ReflexShowTextView( entity: RefType(title: "", content: "", autor: "", isInbuilt: true, isfav: false))
}

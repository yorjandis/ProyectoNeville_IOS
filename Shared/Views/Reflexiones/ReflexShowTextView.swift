//
//  ReflexShowTextView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

//Permite mostrar el contenido de una reflexión

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
            #if os(iOS)
            //Permite actualizar el contenido de una reflexión si se realiza una modificación en la ventana de actualizar la reflexión
            .task {
                //Actualizando los valores de la IU con los de CoreData: Esto es para cuando se actualize la UI en la ventana de edición de la reflexión
                if let entityCoreData = modelReflex.getEntityById(id: self.entity.id) {
                    
                    let entityUpdated = RefType(id: entityCoreData.id ?? UUID().uuidString, title: entityCoreData.title ?? "", content: entityCoreData.texto ?? "", autor: entityCoreData.autor ?? "", isInbuilt: entityCoreData.isInbuilt, isfav: entityCoreData.isfav)
                     
                    self.entity = entityUpdated
                }
                    
           }    
            #endif
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
                if self.entity.isInbuilt == false{
                    ToolbarItem{
                        Button{
                            showWindow(for: AddReflexView(reflexionAActualizar: self.entity),
                                       environmentObjects: [self.modelReflex],
                                       title: "Actualizar Reflexión",
                                       size: AppCons.windows_size_content,
                                       isModal: true) {
                                //Actualizar el contenido de la reflexión en la ventana
                                /*
                                 Yor: esto es para poder actualizar el contenido de la ventana padre (ReflexShowTextView)
                                 cuando la ventana hija (AddReflexView(reflexionAActualizar: self.entity)) modifica la reflexion.
                                */
                                Task{ @MainActor in
                                    if let entity = modelReflex.getEntityById(id: self.entity.id){
                                        //recrea un objeto de tipo Re
                                        let refType = RefType(
                                            id: entity.id!,
                                            title: entity.title!,
                                            content: entity.texto!,
                                            autor: entity.autor!,
                                            isInbuilt: entity.isInbuilt,
                                            isfav: entity.isfav)
                                        //Actualiza el objeto pasado a la ventana
                                        self.entity = refType
                                    }
                                }
                                
                                
                            }
                            
                        }label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
               
                if #available(iOS 26.0, macOS 26.0, *){
                    ToolbarSpacer(.fixed)
                }
                
                
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
                
                
                //Añadir un boton para cerrar la ventana modal (si es modal)
                if ventanaActualEsModal(){
                    ToolbarItem(placement: .navigation) {
                        Button{
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                            }
                        }label:{
                            Label("Cerrar", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .help("Cerrar")
                    }
                }
                
                #else
                
                if self.entity.isInbuilt == false{
                    ToolbarItem{
                        NavigationLink{
                            AddReflexView(reflexionAActualizar: self.entity)
                        }label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
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
                                #if os(macOS)
                                
                                Button{
                                    showWindow(for: RespondView(nameConference: "", texto: entity.content, tipoSalida: .interpretar ),
                                               environmentObjects: [],
                                               title: "\(self.entity.title) - Interpretar",
                                               size: AppCons.windows_size_content,
                                               isModal: true,
                                               isIAWindows: true)
                                }label:{
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                                Button{
                                    showWindow(for:  RespondView(nameConference: "", texto: entity.content, tipoSalida: .practicaConcreta),
                                               environmentObjects: [],
                                               title: "\(self.entity.title) - Aplicación Práctica",
                                               size: AppCons.windows_size_content,
                                               isModal: true,
                                               isIAWindows: true)
                                   
                                }label:{
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                                Button{
                                    showWindow(for:   ChatView(textoACargar: entity.content),
                                               environmentObjects: [],
                                               title: "\(self.entity.title) - Charlar",
                                               size: AppCons.windows_size_content,
                                               isModal: true,
                                               isIAWindows: true)
                                   
                                }label: {
                                    Label("Charlar con IA", systemImage: "sparkles")
                                }
                                .tint(.orange)
                                
                                #else
                                
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
                                
                                
                                #endif
                                
                                
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
                print(self.entity.content)
                //Aplicando
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
            }
            
        }
    }
}



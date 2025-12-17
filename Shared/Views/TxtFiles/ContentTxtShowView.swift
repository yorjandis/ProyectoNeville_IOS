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
import FoundationModels



struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var modeloTxt : TxtContentModel
    @EnvironmentObject private var settingModel : SettingModel
    
    @EnvironmentObject private var clipBoarModel : ClipboardObserver
    
    

    
    let title : String 
    
    let nombreTxt : String //Nombre del fichero txt a abrir, sin el prefijo
    
    let type : TipoDeContenido //define el tipo de contenido a generar por IA

    
    @State private var showSheetIA : Bool = false
  
    
    //Setting: Tamaño de fuente por defecto
    @State private var fontSizeContent : CGFloat = 18

    @AppStorage(AppCons.UD_setting_fontContentSize)   var fontSizeContenido  = 18
    
    //Colores de Texto y fondo
    @State private var textContentdColor    : Color = Color.black
    @State private var backgroundColor      : Color = Color.teal
    

    @State private var showSlider   = false         //Para mostrar el Ajuste de tamaño de fuente
    @State private var showColor    = false         //Para mostrar el Ajuste de Colores de Texto y Fondo
    
    //Para comprobar el valor de desplazamiento del texto: funcion de review:
    @State private var scrollOffset: CGFloat = 0 //Para medir el desplazamiento
    private let threshold: CGFloat = 7000 // Umbrall de hito
    @State private var flagScroll : Bool = false //Si es true se detiene el proceso
    
    
    
     //manejar el texto copiado:
     @State private var showSheetInterpretarTextoCopiadoIA : Bool = false
     @State private var showSheetChatIATextoCopiado : Bool   = false
     @State private var showSheetLienzoTextoCpiado  : Bool   = false
     @State private var showSheetTextoCopiadoAlPortapapelesParaInterpretar   : TextoCopiadoAlPortapapeles? = nil
     @State private var showSheetTtextoCopiadoAlPortapapelesParaChatIA       : TextoCopiadoAlPortapapeles? = nil
     @State private var showSheetTtextoCopiadoAlPortapapelesParaLienzo       : TextoCopiadoAlPortapapeles? = nil
     
    
    
    //Alertas:
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    

    //Yor aqui va el código para leer el contenido del fichero
    var getContent : String {
        if type == .NA {
            //Este es el caso de ficheros como "biografia.txt" que no tienen prefijo
            var texto = UtilFuncs.FileRead(self.nombreTxt)
            //Inserta caracteres ocultos al texto:
            texto = ClipboardHelper.insertarMarcaOculta(en: texto)
            return texto
        }else{
            //Ficheros txt con prefijo
            var texto = modeloTxt.getContentTxt(nombreTxt: self.nombreTxt, type: self.type)
            //Inserta caracteres ocultos al texto:
            texto = ClipboardHelper.insertarMarcaOculta(en: texto)
            return  texto
        }
        
    }
    
    //Obtiene el valor del favorito del elemento actualmente listado(conferencias, citas, ayudas, preguntas, NO Bibliografia)
    private var getFavState : Bool {
        if type != .NA {
            return modeloTxt.getIsFavOfTxt(nombreTxt: self.nombreTxt, type: self.type)
        }else{
            return false
        }
    }
    
    
    @State private var favState : Bool = false
    
    // Función para convertir el color a formato hexadecimal
    func hexStringo(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Convertir a hexadecimal
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }
    
    
    //Muestra/oculta la sección de Notas:
    @State private var showNotesSection: Bool = false
    
    

    var body: some View {
        NavigationStack {
            
            VStack {
                VStack{
                    Divider()
                    .padding(0)
                }
                
                //Mostrar la sección de Notas del contenido:
                if self.showNotesSection {
                    VStack{
                        EditNoteTxt(nameTxt: self.nombreTxt, typeOfContent: self.type )
                            .cornerRadius(20)
                    }
                    .frame(height: 200)
                }
                
                ScrollView(showsIndicators: true){
                    VStack{
                        //Esta Vista es multiplataforma (iOS/macOS) y esta en un fichero independiente
                        SelectableTextShareView(getContent: self.getContent, fontSizeContenido: CGFloat(self.fontSizeContenido), textContentdColor: UIColor(self.textContentdColor))

                    }
                    .background(self.backgroundColor)
                    .cornerRadius(12)
                    .onTapGesture {
                        withAnimation {
                            self.showColor = false
                            self.showSlider = false
                        }
                       
                    }
                    .task {
                        //Se cargan y aplican los colores de fondo y de texto
                        self.backgroundColor = SettingModel.loadColor(forkey: AppCons.UD_setting_color_fondoContent) ?? .black.opacity(0.7)
                        self.textContentdColor = SettingModel.loadColor(forkey: AppCons.UD_setting_color_textContent) ?? .white
                    }
                    .padding(.horizontal, 5)
                    
                }
             
                #if os(iOS)
                //Coloca un boton Atras en la parte inferior
                if(self.showColor == false && self.showSlider == false){
                    HStack{
                        Spacer()
                        Image(systemName: "house")
                            .foregroundStyle(Color.primary.opacity(0.4))
                            .onTapGesture {
                                self.dismiss()
                            }
                            .padding(.trailing, 10)
                    }
                    .padding(5)
                }
                #endif
                
                
                
                Divider()
                
                
    
            }
            #if os(iOS)
            .navigationBarTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
            }
            .toolbar{
                
                #if os(macOS)
                //Coloca un botón de cerrar si la ventana es modal
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
                
                
                
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
                #endif
                
                
                //Menú de acciones con el texto copiado
                ToolbarItem{
                    if let _ = self.clipBoarModel.clipboardText{
                        withAnimation {
                            TextoCopiadoView(clipBoardModel: self.clipBoarModel,
                                             nameTxt: self.nombreTxt,
                                             showAlert: self.$showAlert,
                                             alertMessage: self.$alertMessage,
                                             showSheetTextoCopiadoAlPortapapelesParaInterpretar: self.$showSheetTextoCopiadoAlPortapapelesParaInterpretar,
                                             showSheetTtextoCopiadoAlPortapapelesParaChatIA: self.$showSheetTtextoCopiadoAlPortapapelesParaChatIA,
                                             showSheetTtextoCopiadoAlPortapapelesParaLienzo: self.$showSheetTtextoCopiadoAlPortapapelesParaLienzo)
                        }
                        
                       
                    }
                }
                
                if #available(iOS 26.0, macOS 26.0, *){
                    ToolbarSpacer(.fixed)
                }
                
                
                //Barra de opciones IA para conferencias
                if (self.type == .conf) {

                    if #available(iOS 26.0, macOS 26.0, *){
                        //Verificando si el marco FoundationModels esta disponible en el dispositivo
                        if IAModelAppleIntelligence.isAvailable() {
                            
                            ToolbarItemGroup{
                                Menu{
                                    //Botón que genera un resumen de los puntos claves del contenido
                                    #if os(macOS)
                                    Button{
                                       
                                        showWindow(for: RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .puntosClaves),
                                                   environmentObjects: [],
                                                   title: self.nombreTxt,
                                                   size: AppCons.windows_size_content,
                                                   isModal: true,
                                                   isIAWindows: true
                                        )
                                        
                                    }label: {
                                        Label("Puntos Claves",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA, un resumen de los puntos claves")
                                    
                                    #else
                                    
                                    NavigationLink{
                                        RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .puntosClaves)
                                    }label: {
                                        Label("Puntos Claves",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA, un resumen de los puntos claves")
                                    #endif
                                    
                                    
                                    //Botón que genera un resumen general del contenido
                                    #if os(macOS)
                                    Button{
                                        showWindow(for: RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .resumen),
                                                   environmentObjects: [self.modeloTxt],
                                                   title: self.nombreTxt,
                                                   size: AppCons.windows_size_content,
                                                   isModal: true,
                                                   isIAWindows: true)
                                        
                                    }label: {
                                        Label("Resumen",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA,  un resumen general del contenido")
                                    
                                    #else
                                    NavigationLink{
                                        RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .resumen)
                                    }label: {
                                        Label("Resumen",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA,  un resumen general del contenido")
                                    
                                    #endif
                                    
                                    
                                    
                                    //Genera concejos prácticos:
                                    NavigationLink{
                                        RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .practicas)
                                    }label: {
                                        Label("Aplicación Práctica",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA, una lista de concejos prácticos")
                                    
                                }label: {
                                    Image(systemName: "sparkles")
                                        
                                }
                                .tint(.purple)
                            }
                            
                        }
                    }
                    
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    //Favorito de conferencia
                    ToolbarItem {
                        
                        Button{ //Poner favorito
                            var temp = self.getFavState
                            temp.toggle()
                            if TxtContentModel.shared.setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: temp){
                                self.favState = temp
                             self.modeloTxt.getAllFileTxtOfType(type: self.type) //Actualizando el listado

                            }
                        }label: {
                            Image(systemName:  self.getFavState ? "heart.fill" : "heart")
                                .foregroundStyle(self.getFavState ? .orange : .gray)
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    //Nota Asociada de conferencia
                    ToolbarItem {
                        #if os(macOS)
                        Button{
                            self.showNotesSection.toggle() //Muestra la sección de las notas
                            /*
                             showWindow(for: EditNoteTxt(nameTxt: nombreTxt, typeOfContent: self.type),
                                        environmentObjects: [self.modeloTxt],
                                        title: "Editar nota de Conferencia: \(self.nombreTxt)",
                                        size: AppCons.windows_size_content_small,
                                        isModal: true
                             )
                             */
                            
                            
                        }label: {
                            Label("Nota Asociada", systemImage: self.modeloTxt.isNotaOfTxt(nombreTxt: self.nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(self.modeloTxt.getNotaOfTXT(nombreTxt: nombreTxt, type: type) == "" ? .gray : .green)
                                
                        }
                        .help("Nota Asociada")
                        #else
                        Button{
                            self.showNotesSection.toggle()
                           // EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type)
                        }label: {
                            
                            Label("Nota Asociada", systemImage: self.modeloTxt.isNotaOfTxt(nombreTxt: self.nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                
                        }
                        .tint(self.modeloTxt.getNotaOfTXT(nombreTxt: nombreTxt, type: type) == "" ? .gray : .green)
                        .help("Nota Asociada")
                        
                        #endif
                        
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    //Opciones de Ajuste de tamaño y color de fuente y opciones de tratamiento del texto copiado
                    ToolbarItem {
                        Menu{
                            
                            
                            Button("Tamaño de Letra", systemImage: "textformat") {
                                withAnimation(.easeInOut) {
                                    self.showColor = false
                                    self.showSlider.toggle()
                                }
                            }
                            Button("Color de fondo y letra", systemImage: "paintpalette.fill") {
                                withAnimation(.easeInOut) {
                                    self.showSlider = false
                                    self.showColor.toggle()
                                }
                            }
                            
                            //Menú de acciones con el texto copiado
                            if let _ = self.clipBoarModel.clipboardText{
                                TextoCopiadoView(clipBoardModel: self.clipBoarModel,
                                                 nameTxt: self.nombreTxt,
                                                 showAlert: self.$showAlert,
                                                 alertMessage: self.$alertMessage,
                                                 showSheetTextoCopiadoAlPortapapelesParaInterpretar: self.$showSheetTextoCopiadoAlPortapapelesParaInterpretar,
                                                 showSheetTtextoCopiadoAlPortapapelesParaChatIA: self.$showSheetTtextoCopiadoAlPortapapelesParaChatIA,
                                                 showSheetTtextoCopiadoAlPortapapelesParaLienzo: self.$showSheetTtextoCopiadoAlPortapapelesParaLienzo)
                               
                            }
                            
                            
                            
                            
                            
                        }label: {
                            Image(systemName: "line.3.horizontal")
                            
                           
                                
                        }
                        
                        
                    }
                }
                
                
                
                //Barra de opciones de IA para Citas, Ayudas y Reflexiones:
                if (self.type == .ayud || self.type == .citas ){
                    if #available(iOS 26.0, macOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            ToolbarItem {
                                Menu{
                                    #if os(macOS)
                                    Button{
                                        showWindow(for: RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .interpretar ),
                                                   environmentObjects: [self.modeloTxt],
                                                   title: self.nombreTxt,
                                                   size: AppCons.windows_size_content,
                                                   isModal: true,
                                                   isIAWindows: true)
                                        
                                        
                                        
                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
                                    Button{
                                        showWindow(for: RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .practicaConcreta),
                                                   environmentObjects: [self.modeloTxt],
                                                   title: self.nombreTxt,
                                                   size: AppCons.windows_size_content,
                                                   isModal: true,
                                                   isIAWindows: true)
                                        
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
                                    
                                    #else
                                    NavigationLink{
                                        
                                        RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .interpretar )
                                        
                                        
                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
                                    NavigationLink{
                                        
                                        RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .practicaConcreta)
                                       
                                        
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
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
                    
                    //Favorito para Citas, Ayudas, Reflexiones
                    ToolbarItem {
                        Button{ //Poner favorito
                            var temp = self.getFavState
                            temp.toggle()
                            if TxtContentModel.shared.setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: temp){
                                self.favState = temp
                             self.modeloTxt.getAllFileTxtOfType(type: self.type) //Actualizando el listado

                            }
                        }label: {
                            Image(systemName:  self.getFavState ? "heart.fill" : "heart")
                                .foregroundStyle(self.getFavState ? .orange : .gray)
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem {
                        
                        #if os(macOS)
                        Button{
                            showWindow(for: EditNoteTxt(nameTxt: nombreTxt, typeOfContent: self.type),
                                       environmentObjects: [self.modeloTxt],
                                       title: "Editar Nota de \(self.type.rawValue)",
                                       size: AppCons.windows_size_content_small,
                                       isModal: true
                            )
                            
                        }label: {
                            Image(systemName:  self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? Color.green :  Color.gray)
                        }
                        #else
                        NavigationLink{
                            EditNoteTxt(nameTxt: nombreTxt, typeOfContent: self.type)
                        }label:{
                            Image(systemName:  self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? Color.green :  Color.gray)
                        }
                        #endif
                        
                    }
                    
                    
                    
                }
                
                

                //Ajustar Tamaño de fuente
                if showSlider {
                    #if os(macOS)
                    
                    ToolbarItem(placement: .navigation) {
                        HStack{
                            Slider(value: $fontSizeContent, in: 18...50) { Bool in
                                fontSizeContenido = Int(fontSizeContent)
                            }
                            .frame(width: 250)
                            
                            Button{
                                withAnimation {
                                    self.showSlider = false
                                }
                                
                            }label: {
                                Image(systemName: "xmark.circle")
                            }
                            .padding(.horizontal, 10)
                        }
                        
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    #else
                    ToolbarItem(placement: .bottomBar) {
                        Slider(value: $fontSizeContent, in: 18...50) { Bool in
                            fontSizeContenido = Int(fontSizeContent)
                        }
                    }
                    
                    #endif
                    
                }
                
                
                //Ajustar Color de Fondo
                if showColor{
                    #if os(macOS)
                    ToolbarItem(placement: .navigation) {
                        ColorPicker(selection: self.$backgroundColor) {
                            Label("Fondo", systemImage: "text.page.fill")
                        }
                        .frame(width: 120)
                        .onChange(of: self.backgroundColor) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: newValue)
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    #else
                    ToolbarItem(placement: .bottomBar) {
                        //Color de fondo
                        ColorPicker(selection: self.$backgroundColor) {
                            Label("Fondo", systemImage: "text.page.fill")
                        }
                        .frame(width: 120)
                        .onChange(of: self.backgroundColor) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: newValue)
                        }
                    }
                    
                    #endif
                    
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    #if os(macOS)
                    
                    ToolbarItem(placement: .navigation) {
                        //Color de texto
                        HStack{
                            ColorPicker(selection: self.$textContentdColor) {
                                Label("Letra", systemImage: "text.alignleft")
                                
                            }
                            .frame(width: 120)
                            .onChange(of: self.textContentdColor) { oldValue, newValue in
                                settingModel.saveColor(forkey: AppCons.UD_setting_color_textContent, color: newValue)
                            }
                            
                            Button{
                                withAnimation {
                                    self.showColor = false
                                }
                                
                            }label: {
                                Image(systemName: "xmark.circle")
                            }
                            .padding(.horizontal, 10)
                            
                        }
                        
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    #else
                    ToolbarItem(placement: .bottomBar) {
                        //Color de texto
                        ColorPicker(selection: self.$textContentdColor) {
                            Label("Letra", systemImage: "text.alignleft")
                            
                        }
                        .frame(width: 120)
                        .onChange(of: self.textContentdColor) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_textContent, color: newValue)
                        }
                    }
                    #endif

                    
                }
              
            }
            .sheet(item: $showSheetTextoCopiadoAlPortapapelesParaInterpretar){ text in
                if #available(iOS 26.0, macOS 26.0, *){
                    RespondView(nameConference: "", texto: text.texto, tipoSalida: .interpretar)
                }else{
                    EmptyView()
                }
            }
            .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaChatIA){ text in
                if #available(iOS 26.0, macOS 26.0, *){
                    ChatView(textoACargar: text.texto)
                }else{
                    EmptyView()
                }
            }
            .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaLienzo){ text in
                if #available(iOS 26.0, macOS 26.0, *){
                    LienzoMain(texto : text.texto)
                }else{
                    EmptyView()
                }
            }
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("La Ley"), message: Text(self.alertMessage))
            }
        }
    }//body
}





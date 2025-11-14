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
    @State private var sheetShowFeedBackReview : Bool = false
    
    //Almacenar la última posición del desplazamiento:
    
    

    //Yor aqui va el código para leer el contenido del fichero
    var getContent : String {
        if type == .NA {
            //Este es el caso de ficheros como "biografia.txt" que no tienen prefijo
            return UtilFuncs.FileRead(self.nombreTxt)
        }else{
            //Ficheros txt con prefijo
            return  modeloTxt.getContentTxt(nombreTxt: self.nombreTxt, type: self.type)
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
    func hexString(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Convertir a hexadecimal
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }

    var body: some View {
        NavigationStack {
            
            VStack {
                VStack{
                    Divider()
                    .padding(0)
                }
                ScrollView(showsIndicators: true){
                    VStack{
                        #if os(macOS)
                        Text(self.getContent)
                            .font(.system(size: CGFloat(self.fontSizeContent)) )
                            .foregroundStyle(self.textContentdColor)
                            .textSelection(.enabled)
                            .padding(.horizontal, 5)
                            
                        #else
                        SelectableText(self.getContent, fontSize: CGFloat(self.fontSizeContenido), fonColor: UIColor(self.textContentdColor) , alignment: .left)
                            .padding(.horizontal, 5)
                        #endif
                        
                            
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
             
                #if os(macOS)
                
                #else
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
                
                
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
                #endif
                
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
                                        print(self.getContent)
                                        showWindow(for: RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .puntosClaves),
                                                   environmentObjects: [],
                                                   title: self.nombreTxt,
                                                   size: CGSize(width: 550, height: 400),
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
                                                   size: CGSize(width: 550, height: 400),
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
                            if TxtContentModel().setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: temp){
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
                            showWindow(for: EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type),
                                       environmentObjects: [self.modeloTxt],
                                       title: "Editar nota de Conferencia: \(self.nombreTxt)",
                                       size: CGSize(width: 550, height: 400),
                                       isModal: true
                            )
                            
                        }label: {
                            Label("Nota Asociada", systemImage: self.modeloTxt.isNotaOfTxt(nombreTxt: self.nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(self.modeloTxt.getNotaOfTXT(nombreTxt: nombreTxt, type: type) == "" ? .gray : .green)
                                
                        }
                        .help("Nota Asociada")
                        #else
                        NavigationLink{
                            EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type)
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
                    
                    //Opciones de Ajuste de tamaño y color de fuente
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
                            if TxtContentModel().setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: temp){
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
                            showWindow(for: EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type),
                                       environmentObjects: [self.modeloTxt],
                                       title: "Editar Nota de \(self.type.rawValue)",
                                       size: CGSize(width: 550, height: 400),
                                       isModal: true
                            )
                            
                        }label: {
                            Image(systemName:  self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(self.modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: self.type) ? Color.green :  Color.gray)
                        }
                        #else
                        NavigationLink{
                            EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type)
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
            
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                
               // FeedbackView(showTextBotton: true)
            }
           
        }
    }//body
}





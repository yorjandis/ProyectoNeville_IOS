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
import FoundationModels

struct ContentTxtShowView: View {
    
    @Environment(\.dismiss) private var dimiss
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
                        RichText(html: self.getContent )
                            .colorScheme(.auto)
                            .fontType(.customName("Arial"))
                            .customCSS("*{font-size: \(self.fontSizeContent)px; background-color: \(self.hexString(for: backgroundColor)); color: \(self.hexString(for: self.textContentdColor)) !important; }")
                            .padding(.horizontal, 5)
                            .task {
                                //Se cargan y aplican los colores de fondo y de texto
                                self.backgroundColor = SettingModel.loadColor(forkey: AppCons.UD_setting_color_fondoContent)
                                self.textContentdColor = SettingModel.loadColor(forkey: AppCons.UD_setting_color_textContent)
                            }
                    }
                    .padding(.horizontal, 5)
                    
                }
             
                
                
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
                    
                    if self.showColor {
                        //Color de fondo
                        ColorPicker(selection: self.$backgroundColor) {
                            HStack{
                                Text("fondo")
                                Image(systemName: "text.page.fill")
                                    .foregroundStyle(self.backgroundColor)
                            }
                            
                        }
                        .onChange(of: self.backgroundColor) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: newValue)
                        }
                        
                        
                        //Color de texto
                        ColorPicker(selection: self.$textContentdColor) {
                            HStack(spacing: 0){
                                Text("letra")
                                Image(systemName: "text.alignleft")
                                    .foregroundStyle(self.textContentdColor)
                                    
                            }
                            
                        }
                        .onChange(of: self.textContentdColor) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_textContent, color: newValue)
                        }
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
            }
            .toolbar{
                
                //Barra de opciones para conferencias
                if (self.type == .conf) {

                    if #available(iOS 26.0, *){
                        //Verificando si el marco FoundationModels esta disponible en el dispositivo
                        if IAModelAppleIntelligence.isAvailable() {
                            
                            ToolbarItemGroup{
                                Menu{
                                    //Botón que genera un resumen de los puntos claves del contenido
                                    NavigationLink{
                                        RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .puntosClaves)
                                    }label: {
                                        Label("Puntos Claves",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA,  un resumen de los puntos claves")
                                    
                                    //Botón que genera un resumen general del contenido
                                    NavigationLink{
                                        RespondView(nameConference: self.nombreTxt, texto: self.getContent, tipoSalida: .resumen)
                                    }label: {
                                        Label("Resumen",systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    .help("Genera, por IA,  un resumen general del contenido")
                                    
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
                    
                    
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem {
                        if modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: type) == true{
                            Button{
                                if TxtContentModel().setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: false){
                                    
                                    self.modeloTxt.getAllFileTxtOfType(type: self.type) //Actualizando el listado
                                    
                                }
                            }label:{
                                Label("Quitar Favorita", systemImage: "heart.fill")
                                    
                            }
                            .tint(.orange)
                        }else{
                            Button{
                                if TxtContentModel().setIsFavOfTxt(nombreTxt: nombreTxt, type: self.type, isFav: true){
                                    
                                    self.modeloTxt.getAllFileTxtOfType(type: self.type) //Actualizando el listado
                                    
                                }
                            }label:{
                                Label("Poner Favorita", systemImage: "heart")
                            }
                        }
                    }
                    
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    //Nota Asociada
                    ToolbarItem {
                        NavigationLink{
                            EditNoteTxt(entidad: nombreTxt, typeOfContent: self.type)
                        }label: {
                            
                            Label("Nota Asociada", systemImage: "note.text")
                                
                        }
                        .tint(self.modeloTxt.getNotaOfTXT(nombreTxt: nombreTxt, type: type) == "" ? .gray : .green)
                        .help("Nota Asociada")
                    }
                    
                    if #available(iOS 26.0, *) {
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
                
                
                
                //Barra de opciones de IA para Ayudas y Citas:
                if (self.type == .ayud || self.type == .citas ){
                    if #available(iOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            ToolbarItem {
                                Menu{
                                    NavigationLink{
                                        
                                        RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .interpretar )
                                        
                                        
                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                    NavigationLink{
                                        
                                        RespondView(nameConference: "", texto: self.getContent.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .practicaConcreta)
                                       
                                        
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                }label:{
                                    Image(systemName: "sparkles")
                                }
                                .tint(.purple)
                            }
                            
                           
                        }
                    }
                }
                
 
            }
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                FeedbackView(showTextBotton: true)
            }
           
        }
    }//body
}





#Preview {
    ContentView()
}

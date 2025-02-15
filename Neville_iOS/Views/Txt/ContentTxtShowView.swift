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
    @EnvironmentObject private var modeloTxt : TxtContentModel
    
    let title : String 
    
    let nombreTxt : String //Nombre del fichero txt a abrir, sin el prefijo
    
    let type : TipoDeContenido
    
  
    
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
                                self.backgroundColor = SettingModel().loadColor(forkey: AppCons.UD_setting_color_fondoContent)
                                self.textContentdColor = SettingModel().loadColor(forkey: AppCons.UD_setting_color_textContent)
                                
                            }
                    }
                    .padding(.horizontal, 3)
                    .background(GeometryReader { proxy -> Color in //Para lazar ventana FeedBackRevie
                        if self.flagScroll == false {
                            let offset = -proxy.frame(in: .global).minY
                            DispatchQueue.main.async {
                                self.scrollOffset = offset
                                if offset >= threshold {
                                    if FeedBackModel.checkReviewRequest() {
                                        self.sheetShowFeedBackReview = true
                                    }
                                    self.flagScroll = true //Desactiva el lanzamiento de la func
                                }
                            }
                        }
                        return Color.clear
                    })
                    
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
                            SettingModel().saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: newValue)
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
                            print(self.hexString(for: newValue)) // Verifica el valor hexadecimal que se está pasando
                            SettingModel().saveColor(forkey: AppCons.UD_setting_color_textContent, color: newValue)
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
                HStack{
                    Spacer()
                    
                        Menu{
                            
                                Button("Marcar como Favorita"){
                                    /*
                                    if let enti = self.entidad {
                                        TxtContentModel().setFavState(context: self.context, entity: enti, state: true)
                                    }
                                    */
                                }
                                NavigationLink("Añadir nota asociada"){
                                    /*
                                    if let enti = self.entidad {
                                        EditNoteTxtContentTxtShow(entidad: enti)
                                    }
                                    */
                                }
                            
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
                            Image(systemName: "ellipsis")
                                .rotationEffect(Angle(degrees: 135))
                        }
                }
            }
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                FeedbackView(showTextBotton: true)
            }
        }
    }//body
}


/*
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

*/


#Preview {
    ContentView()
}

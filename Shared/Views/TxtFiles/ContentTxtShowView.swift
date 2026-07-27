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
    
    //Funciones premium
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false

    
    let title : String 
    
    let nombreTxt : String //Nombre del fichero txt a abrir, sin el prefijo
    
    let type : TipoDeContenido //define el tipo de contenido a generar por IA
    
    var blocks : [ContentBlock] = []

    /// Las conferencias pueden cargarse después de presentar la vista para que
    /// la transición y la barra de navegación no compitan con la lectura del TXT.
    @State private var deferredConferenceBlocks: [ContentBlock]? = nil
    
    var  checkPremium : Bool = false

    @State private var content: String = "" //Contenido del fichero TXT: se llena en un OnApper para que se haga una sola vez
    
    @State private var showSheetIA : Bool = false

  
    
    // Apariencia compartida del lector.
    @State private var fontSizeContentSliderTemp: CGFloat = 18
    @AppStorage(AppCons.UD_setting_fontContentSize) var UserDefaultFontSizeContenido = 18
    
    //Colores de Texto y fondo
    @State private var textContentdColor    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_textContent) ?? .white
    @State private var backgroundColor      : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_fondoContent) ?? .black.opacity(0.7)
    

    @State private var showAppearanceSettings = false
    
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
    
 
    
    
    //Obtiene el valor del favorito del elemento actualmente listado(conferencias, citas, ayudas, preguntas, NO Bibliografia)
    private var getFavState : Bool {
        if type != .NA {
            return modeloTxt.getIsFavOfTxt(nombreTxt: self.nombreTxt, type: self.type)
        }else{
            return false
        }
    }
    
    
    @State private var favState : Bool = false
    
    
    //Muestra/oculta la sección de Notas:
    @State private var showNotesSection: Bool = false
    
    @State private var showSheetPremium: Bool = false
    
    

    var body: some View {
        NavigationStack {
            ZStack{
                
              LinearGradient(colors: [self.backgroundColor], startPoint: .top, endPoint: .bottom)
              .ignoresSafeArea()
                if self.checkPremium{
                    if (self.purchaseStatus || self.yorjPremium) {
                        Content()
                    }else{
                        PremiumPreviewContent()
                    }
                    
                    
                }else{
                    Content()
                }
                
            }
            
            #if os(iOS)
            .navigationBarTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .onAppear {
                self.fontSizeContentSliderTemp = min(
                    42,
                    max(13, CGFloat(UserDefaultFontSizeContenido))
                )
            }
            .task(id: self.readerDocumentID) {
                await self.loadConferenceIfNeeded()
            }
            .onChange(of: self.fontSizeContentSliderTemp) { _, newValue in
                self.UserDefaultFontSizeContenido = Int(newValue)
            }
            .onChange(of: self.backgroundColor) { _, newValue in
                self.settingModel.saveColor(
                    forkey: AppCons.UD_setting_color_fondoContent,
                    color: newValue
                )
            }
            .onChange(of: self.textContentdColor) { _, newValue in
                self.settingModel.saveColor(
                    forkey: AppCons.UD_setting_color_textContent,
                    color: newValue
                )
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
                         TextoCopiadoView(clipBoardModel: self.clipBoarModel,
                                          nameTxt: self.nombreTxt,
                                          showAlert: self.$showAlert,
                                          alertMessage: self.$alertMessage,
                                          showSheetTextoCopiadoAlPortapapelesParaInterpretar: self.$showSheetTextoCopiadoAlPortapapelesParaInterpretar,
                                          showSheetTtextoCopiadoAlPortapapelesParaChatIA: self.$showSheetTtextoCopiadoAlPortapapelesParaChatIA,
                                          showSheetTtextoCopiadoAlPortapapelesParaLienzo: self.$showSheetTtextoCopiadoAlPortapapelesParaLienzo)
                     }else{
                         EmptyView()
                     }
                 }

                 ToolbarItem {
                     Button {
                         self.showAppearanceSettings = true
                     } label: {
                         Label("Apariencia", systemImage: "textformat")
                     }
                     .help("Cambiar tamaño y colores del lector")
                 }
                 
                 
                
                
                if #available(iOS 26.0, macOS 26.0, *){
                    ToolbarSpacer(.fixed)
                }
                
               
                 //Barra de opciones IA para conferencias
                 if (self.type == .conf) {

                     if #available(iOS 26.0, macOS 26.0, *){
                         //Verificando si el marco FoundationModels esta disponible en el dispositivo
                         if IAModelAppleIntelligence.hasAvailableContentProvider() {
                             
                             ToolbarItemGroup{
                                 Menu{
                                     //Botón que genera un resumen de los puntos claves del contenido
                                     #if os(macOS)
                                     Button{
                                        
                                         showWindow(for: RespondView(nameConference: self.nombreTxt, texto: self.content, tipoSalida: .puntosClaves),
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
                                         RespondView(nameConference: self.nombreTxt, texto: self.content, tipoSalida: .puntosClaves, autorRespuesta: "nev")
                                     }label: {
                                         Label("Puntos Claves",systemImage: "sparkles")
                                     }
                                     .tint(.orange)
                                     .help("Genera, por IA, un resumen de los puntos claves")
                                     #endif
                                     
                                     
                                     //Botón que genera un resumen general del contenido
                                     #if os(macOS)
                                     Button{
                                         showWindow(for: RespondView(nameConference: self.nombreTxt, texto: self.content, tipoSalida: .resumen),
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
                                         RespondView(nameConference: self.nombreTxt, texto: self.content, tipoSalida: .resumen)
                                     }label: {
                                         Label("Resumen",systemImage: "sparkles")
                                     }
                                     .tint(.orange)
                                     .help("Genera, por IA,  un resumen general del contenido")
                                     
                                     #endif
                                     
                                     
                                     
                                     //Genera concejos prácticos:
                                     NavigationLink{
                                         RespondView(nameConference: self.nombreTxt, texto: self.content, tipoSalida: .practicas, autorRespuesta: "nev")
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
                     
                 }
                
               
                
                
                
                 //Barra de opciones de IA para Citas, Ayudas y Reflexiones:
                 if (self.type == .ayud || self.type == .citas ){
                     if #available(iOS 26.0, macOS 26.0, *){
                         if IAModelAppleIntelligence.hasAvailableContentProvider(){
                             
                             ToolbarItem {
                                 Menu{
                                     #if os(macOS)
                                     Button{
                                         showWindow(for: RespondView(nameConference: "", texto: self.content.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .interpretar, autorRespuesta: "nev" ),
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
                                         showWindow(for: RespondView(nameConference: "", texto: self.content.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .practicaConcreta, autorRespuesta: "nev"),
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
                                         
                                         RespondView(nameConference: "", texto: self.content.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .interpretar, autorRespuesta: "nev" )
                                         
                                         
                                     }label:{
                                         Label("Interpretar", systemImage: "sparkles")
                                     }
                                     .tint(.orange)
                                     
                                     NavigationLink{
                                         
                                         RespondView(nameConference: "", texto: self.content.replacingOccurrences(of: "<br>", with: ""), tipoSalida: .practicaConcreta, autorRespuesta: "nev")
                                        
                                         
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
                 
                
                
                

            }
            .sheet(isPresented: self.$showAppearanceSettings) {
                appearanceSettingsSheet
            }
            .sheet(item: $showSheetTextoCopiadoAlPortapapelesParaInterpretar){ text in
                if #available(iOS 26.0, macOS 26.0, *){
                    RespondView(nameConference: "", texto: text.texto, tipoSalida: .interpretar, autorRespuesta: "nev")
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
                    LienzoMain(texto : text.texto, imagenPrimariaACargar: nil)
                }else{
                    EmptyView()
                }
            }
            .sheet(isPresented: self.$showSheetPremium, content: {
                PurchaseView()
            })
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("La Ley"), message: Text(self.alertMessage))
            }
        }
    }//body

    @ViewBuilder
    private var appearanceSettingsSheet: some View {
        #if os(iOS)
        ReaderAppearanceSettingsView(
            fontSize: self.$fontSizeContentSliderTemp,
            textColor: self.$textContentdColor,
            backgroundColor: self.$backgroundColor
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        #else
        ReaderAppearanceSettingsView(
            fontSize: self.$fontSizeContentSliderTemp,
            textColor: self.$textContentdColor,
            backgroundColor: self.$backgroundColor
        )
        .frame(width: 420, height: 330)
        #endif
    }

    private var readerDocumentID: String {
        "\(self.type.rawValue)|\(self.nombreTxt)|\(self.title)"
    }

    private var shouldLoadConferenceDeferred: Bool {
        self.type == .conf && self.blocks.isEmpty && !self.nombreTxt.isEmpty
    }

    private var readerBlocks: [ContentBlock] {
        self.deferredConferenceBlocks ?? self.blocks
    }

    @MainActor
    private func loadConferenceIfNeeded() async {
        guard self.shouldLoadConferenceDeferred,
              self.deferredConferenceBlocks == nil else {
            return
        }

        let resourceName = "\(self.type.rawValue)\(self.nombreTxt)"
        let loadingTask = Task.detached(priority: .userInitiated) {
            autoreleasepool {
                UtilFuncs.FileRead(resourceName)
            }
        }

        // Deja que SwiftUI presente primero la navegación y sus controles,
        // mientras el archivo ya se prepara fuera del hilo principal.
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(120))
        guard !Task.isCancelled else {
            loadingTask.cancel()
            return
        }

        let loadedText = await loadingTask.value

        guard !Task.isCancelled else { return }
        self.content = loadedText
        self.deferredConferenceBlocks = [ContentBlock(content: .text(loadedText))]
    }
    
    
    //Obtiene el texto del TXT
    private func getContent(NameTxt : String) -> String{
        //Carga el contenido del fichero una única vez:
        if content.isEmpty {
            var texto: String
            if type == .NA {
                texto = UtilFuncs.FileRead(NameTxt)
            } else {
                texto = modeloTxt.getContentTxt(nombreTxt: NameTxt, type: type)
            }
            return texto

        }
        return ""
    }
    
    private var premiumPreviewText: String {
        let plainText = self.readerBlocks.compactMap { block -> String? in
            switch block.content {
            case .text(let value), .markdown(let value), .quote(let value), .code(let value):
                return value
            case .attributed(let value):
                return String(value.characters)
            case .bulletList(let items):
                return items.joined(separator: " ")
            case .link(let title, _):
                return title
            default:
                return nil
            }
        }
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !plainText.isEmpty else {
            return "Disponible en la Versión Extendida"
        }
        
        let preview = String(plainText.prefix(400))
        return "\(preview)... \n\n[ Contenido Disponible en la Versión Extendida ]"
    }
    
    @ViewBuilder
    func PremiumPreviewContent() -> some View {
        ScrollView {
            Text(self.premiumPreviewText)
                .font(.system(size: self.fontSizeContentSliderTemp))
                .foregroundStyle(self.textContentdColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            Button("Acceder a la Versión Extendida"){
                
                
                #if os(macOS)
                showWindow(for: PurchaseView(),
                environmentObjects: [],
                title: "Versión Extendida",
                size: WindowSize.absolute(CGSize(width: 500, height: 600)),
                isModal: false)
                #else
                self.showSheetPremium = true
                #endif
            }
            .tint(.black)
            .foregroundStyle(.white)
            .buttonStyle(.bordered)
            
        }
    }
    
    @ViewBuilder
    func Content() -> some View{
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
            
            if self.shouldLoadConferenceDeferred,
               self.deferredConferenceBlocks == nil {
                ProgressView("Preparando lectura…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel("Preparando contenido de la conferencia")
            } else {
                DynamicContentView(
                    blocks: self.readerBlocks,
                    fontSize: self.fontSizeContentSliderTemp,
                    fontColor: self.textContentdColor,
                    backgroundColor: self.backgroundColor,
                    documentID: self.readerDocumentID
                )
            }
         
            #if os(iOS)
            //Coloca un boton Atras en la parte inferior
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
            #endif
            
            
            
            Divider()
            
            

        }
    }
    
    
}

private struct ReaderAppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var fontSize: CGFloat
    @Binding var textColor: Color
    @Binding var backgroundColor: Color

    var body: some View {
        NavigationStack {
            Form {
                Section("Tamaño de fuente · \(Int(fontSize)) pt") {
                    Slider(value: self.$fontSize, in: 13...42, step: 1) {
                        Text("Tamaño de fuente")
                    } minimumValueLabel: {
                        Image(systemName: "textformat.size.smaller")
                    } maximumValueLabel: {
                        Image(systemName: "textformat.size.larger")
                    }
                }

                Section("Colores") {
                    ColorPicker("Color del texto", selection: self.$textColor, supportsOpacity: false)
                    ColorPicker("Color del fondo", selection: self.$backgroundColor, supportsOpacity: false)
                }

                Section {
                    Button("Restablecer apariencia", systemImage: "arrow.counterclockwise") {
                        self.fontSize = 20
                        self.textColor = .primary
                        #if os(macOS)
                        self.backgroundColor = Color(nsColor: .windowBackgroundColor)
                        #else
                        self.backgroundColor = Color(uiColor: .systemBackground)
                        #endif
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Apariencia")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        self.dismiss()
                    }
                }
            }
        }
    }
}

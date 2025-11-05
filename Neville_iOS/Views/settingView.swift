//
//  settingView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 28/10/23.
//

import SwiftUI
import LocalAuthentication
import CoreData

struct settingView: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var modelTxt : TxtContentModel
    @EnvironmentObject private var modelFrases : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    
     private let context2 = CoreDataController.shared.context
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)     var fontSizeFrases      : Int = 24
    @AppStorage(AppCons.UD_setting_fontContentSize)    var fontSizeContenido   : Int = 18
    @AppStorage(AppCons.UD_setting_fontMenuSize)       var fontSizeMenu        : Int = 18
    @AppStorage(AppCons.UD_setting_fontListaSize)      var fontSizeLista       : Int = 18
    @AppStorage(AppCons.UD_setting_NotasFaceID)        var setting_NotasFaceID : Bool = false
    @AppStorage(AppCons.UD_setting_fontChatIASize)     var fontSizeChatIA : Int = 20
    
    
    //Tipo de chat de IA
    @AppStorage(AppCons.UD_setting_AceptacionDescargoIA)    var DescargoDeIA : Bool = false // Si es true se permite utilizar la IA.
    

    //Almacena internamente los colores de configuración. Al inicio se cargan los valores almacenados
    @State var ColorFrase       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_frases) ?? .black
    @State var ColorPrimario    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .orange
    @State var ColorSecundario  : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)

    
    //Colores de IA chat:
    @State var ColorChatIAPrimario         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.5)
    @State var ColorChatIASecundario       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorChatIAFuente           : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textContent) ?? .black

    //Autenti
    private let contextLA = LAContext()
    @State var canOpenToggleButton = false
    @State var showAlert = false
    @State var alertMessage = ""
    
    //Habilitar un botón en Ajustes para actualizar el nuevo contenido (importarlo a las BD)
    @State var showButtonUpdate = true // muestra/oculta el boton para actualizar nuevo contenido añadido al bundle
    
    
    //Otros
    @State private var showSheet : Int? = nil
    
    //Contadores de elementos:
    @State private var frasesCount          : Int = 0
    @State private var ayudasCount          : Int = 0
    @State private var preguntasCount       : Int = 0
    @State private var citasCount           : Int = 0
    @State private var conferenciasCount    : Int = 0
    

    var body: some View {
        
        NavigationStack{
            Form{
                Section("Tamaño de letra"){
                    HStack{
                        Text("Frases:")
                            .font(.system(size:CGFloat(fontSizeFrases)))
                        Spacer()
                        Stepper(String(fontSizeFrases), value: $fontSizeFrases)
                        
                    }
                    
                    HStack{
                        Text("Contenido:")
                            .font(.system(size:CGFloat(fontSizeContenido)))
                        Spacer()
                        Stepper(String(fontSizeContenido), value: $fontSizeContenido)
                        
                    }
                    
                    HStack{
                        Text("Menu:")
                            .font(.system(size:CGFloat(fontSizeMenu)))
                        Spacer()
                        Stepper(String(fontSizeMenu), value: $fontSizeMenu)
                        
                    }
                    
                    HStack{
                        Text("Listas:")
                            .font(.system(size:CGFloat(fontSizeLista)))
                        Spacer()
                        Stepper(String(fontSizeLista), value: $fontSizeLista)
                        
                    }
                    if #available(iOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            HStack{
                                Text("Chat IA:")
                                    .font(.system(size:CGFloat(fontSizeChatIA)))
                                Spacer()
                                Stepper(String(fontSizeChatIA), value: $fontSizeChatIA)
                                
                            }
                        }
                    }
                    
                    
                    
                }.padding(2)
                
                
                
                Section("Colores Home"){
                    
                    ColorPicker("Color de frases", selection: $ColorFrase)
                        .bold()
                        .onChange(of: ColorFrase, initial: true) { oldValue, newValue in
                            settingModel.saveColor(forkey: AppCons.UD_setting_color_frases, color: newValue)
                        }
                    
                    VStack(alignment: .center){
                        ColorPicker("Color Degradado Superior", selection: $ColorPrimario)
                            .onChange(of: ColorPrimario, initial: true) { oldValue, newValue in
                                settingModel.saveColor(forkey: AppCons.UD_setting_color_main_a, color: newValue)
                            }
                            .padding(.bottom, 10)
                        ColorPicker("Color Degradado Inferior", selection: $ColorSecundario)
                            .onChange(of: ColorSecundario, initial: true) { oldValue, newValue in
                                settingModel.saveColor(forkey: AppCons.UD_setting_color_main_b, color: newValue)
                                
                            }
                        
                        HStack{
                            Text("Muestra:").font(.footnote)
                            Spacer()
                            Text("")
                                .frame(width: 200 ,  height: 60)
                                .background(LinearGradient(colors: [ColorPrimario, ColorSecundario], startPoint: .top, endPoint: .bottom))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        
                        
                        
                    }
                }
                
                if #available(iOS 26.0, macOS 26.0, *){
                    if IAModelAppleIntelligence.isAvailable(){
                        Section("Colores Chat IA"){
                            
                            ColorPicker("Color de Texto", selection: $ColorChatIAFuente)
                                .bold()
                                .onChange(of: ColorChatIAFuente, initial: true) { oldValue, newValue in
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: newValue)
                                }
                            
                            VStack(alignment: .center){
                                ColorPicker("Color Degradado Superior", selection: $ColorChatIAPrimario)
                                    .onChange(of: ColorChatIAPrimario, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: newValue)
                                    }
                                    .padding(.bottom, 10)
                                ColorPicker("Color Degradado Inferior", selection: $ColorChatIASecundario)
                                    .onChange(of: ColorChatIASecundario, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: newValue)
                                        
                                    }
                                
                                HStack{
                                    Text("Muestra:").font(.footnote)
                                    Spacer()
                                    Text("")
                                        .frame(width: 200 ,  height: 60)
                                        .background(LinearGradient(colors: [ColorChatIAPrimario, ColorChatIASecundario], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }

                            }
                            
                            Button("Aplicar Colores Por Defecto"){
                                self.ColorChatIAFuente      = .black
                                self.ColorChatIAPrimario    = .orange.opacity(0.5)
                                self.ColorChatIASecundario  = .brown
                                settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: self.ColorChatIAFuente)
                                settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: self.ColorChatIAPrimario)
                                settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: self.ColorChatIASecundario) 
                            }
                        }
                    }
                }
                
                
                if #available(iOS 26.0, *){
                    if IAModelAppleIntelligence.isAvailable(){
                        
                        Section("Utilización de la IA"){
                            VStack(spacing: 10){
                                HStack{
                                    Text("(\(self.DescargoDeIA ? "Aceptado" : "No aceptado")) ")
                                        .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                    NavigationLink("Acceder al Descargo de responsabilidad"){DescargoResponsabilidadIA(VentanaEnSetting: true)}.foregroundStyle(.orange)
                                }
                                Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero el Descargo de R esponsabilidad.").font(Font.footnote.bold())
                            }
                        }
                    }
                }
                
                
                
                Section("Notas Generales"){
                     
                        
                        if canOpenToggleButton {
                            Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                        }else{
                            
                            //Chequeando si existe soporte biométrico:
                            if BiometryCheckerSupport.checkBiometricSupport() == .available{

                                Button{
                                    UtilFuncs.autent(HabilitarContenido: self.$canOpenToggleButton)
                                }label: {
                                    Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                                }
                            }else{ //NO existe biometría en el dispositivo
                                 //Si existe una contraseña guardada se intenta acceder por contraseña
                                if KeychainHelper.shared.getPassword() != nil {
                                    NavigationLink("Acceder por contraseña"){
                                        LogginView(ente: "Notas",canOpen: self.$canOpenToggleButton)
                                    }
                                }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                    NavigationLink("Crear una nueva Contraseña de Acceso"){
                                        CreatePasswordView()
                                    }
                                }
                            }
                        }
  
                }
                
                //Habilita una sección para recuperar la contraseña. Esta sección solo esta disponible en dispositivos con biometria y si ya previamente han almacenado una contraseña
                if BiometryCheckerSupport.checkBiometricSupport() == .available {
                    //Si existe una contraseña guardada; sino no, no se muestra el botón para recuperar contraseña
                    if KeychainHelper.shared.getPassword() != nil {
                        Section("Contraseña Maestra"){
                            Button("Recupera Contraseña Para Acceder al Diario y Notas"){
                                //Intentando obtener la clave
                                if let clave = KeychainHelper.shared.getPassword() {
                                    self.alertMessage = "La clave es: \(clave)" //Almacena la clave
                                    UtilFuncs.autent(HabilitarContenido: self.$showAlert)
                                }
                            }
                            .tint(.green)
                            
                            VStack(alignment: .leading){
                               NavigationLink(destination: ChangePasswordView()){
                                    Text("Cambiar La Contraseña")
                                }
                                Text("Permite modificar la contraseña para proteger el acceso al Diario y a Notas Protegidas").font(.footnote)
                            }
                            
                        }
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("La contraseña es:"), message: Text(self.alertMessage), dismissButton: .cancel())
                        }
                    }
                }
                
                
                
                

                Section("Contacto & Información"){
                    NavigationLink{
                        Form{
                            HStack{
                                Text("Versión")
                                Spacer()
                                Text("\(AppCons.appVersion ?? "")")
                                    .foregroundStyle(.orange).bold()
                            }
                            HStack{
                                Text("Frases")
                                Spacer()
                                Text("\(self.frasesCount)")
                            }.onTapGesture {self.showSheet = 1}
                            HStack{
                                Text("Conferencias")
                                Spacer()
                                Text("\(self.conferenciasCount)")
                            }.onTapGesture {self.showSheet = 2}
                            HStack{
                                Text("Citas")
                                Spacer()
                               Text("\(citasCount)")
                            }.onTapGesture {self.showSheet = 3}
                            HStack{
                                Text("Preguntas")
                                Spacer()
                                Text("\(self.preguntasCount)")
                            }.onTapGesture {self.showSheet = 4}
                            HStack{
                                Text("Ayudas")
                                Spacer()
                                Text("\(self.ayudasCount)")
                                    
                            }.onTapGesture {self.showSheet = 5}

                            HStack{
                                Text("Reflexiones")
                                Spacer()
                                Text("\(ReflexModel.shared.getArrayReflexOfTxtFileGET().count)")
                            }.onTapGesture {self.showSheet = 6}
                            
                            HStack{
                                Text("Cuestionario")
                                Spacer()
                                Text("\(UtilFuncs.FileReadToArray("cuestionario").count)")
                            }.onTapGesture {self.showSheet = 7}
                            
                        }
                        .task{
                            self.frasesCount    = modelFrases.listfrases.count
                            self.conferenciasCount = modelTxt.getArrayOfAllFileTxtOfType(type: .conf).count
                            self.citasCount     = modelTxt.getArrayOfAllFileTxtOfType(type: .citas).count
                            self.preguntasCount = modelTxt.getArrayOfAllFileTxtOfType(type: .preg).count
                            self.ayudasCount    = modelTxt.getArrayOfAllFileTxtOfType(type: .ayud).count
                        }
                        .navigationTitle("Información")
                    }label: {
                        Label("Información", systemImage: "info.circle.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                    }
                    
                    NavigationLink{
                        NavigationStack{
                            ScrollView{
                                SelectableText(UtilFuncs.FileRead("privacy"),fontSize: 22, fonColor: UIColor(Color.primary))
                            }.navigationTitle("Ajustes - Privacy")
                        }
                    }label:{
                        Label("Política de Privacidad", systemImage: "square.and.pencil.circle")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696")!) {
                        HStack {
                            Image("Icon-29")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24) // Ajusta el tamaño según sea necesario
                            
                            Text("Compartir la App")
                                .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                .bold()
                                .font(.headline)
                        }
                        
                    }
                    NavigationLink{
                        FeedbackView(showTextBotton: false)
                    }label:{
                       Label("Deja una reseña!", systemImage:"bolt.heart.fill" )
                    }
                    
                    Link(destination: URL(string: "mailto:info@ypgcode.es")!) {
                        Label("Enviar Email", systemImage: "envelope.fill")
                    }
                    .font(.headline)
                    
                    Link(destination: URL(string:  "https://ypgcode.es/la-ley-neville-goddard/")!) {
                        Label("Abrir página del proyecto", systemImage: "swiftdata")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    Link(destination: URL(string:  "https://paypal.me/Yorpg?country.x=ES&locale.x=es_ES")!) {
                        Label("Donar para este proyecto", systemImage: "dollarsign.circle.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                }
                
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Configuración"), message: Text(alertMessage))
                }
                
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .sheet(item: $showSheet) { details in
            switch details {
            case 1:
                FrasesListView()
            case 2:
                TxtListView( typeOfContent: .conf, title: "Lecturas")
            case 3:
                TxtListView( typeOfContent: .citas, title: "Citas")
            case 4:
                TxtListView( typeOfContent: .preg, title: "Preguntas")
            case 5:
                TxtListView( typeOfContent: .ayud, title: "Ayudas")
            case 6:
                ReflexListView()
            case 7:
                GamePLay()
            default :
                EmptyView()
            }
        }

        
            
            
            
        
    }
    
   

    
    
}

extension Int: @retroactive Identifiable {
    public var id: Int { return self }
}



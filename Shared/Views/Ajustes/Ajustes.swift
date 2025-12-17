//
//  settingView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 28/10/23.
//

import SwiftUI
import LocalAuthentication
import CoreData

struct Ajustes: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var modelTxt : TxtContentModel
    @EnvironmentObject private var modelFrases : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    @EnvironmentObject private var securityModel : SecurityModel
    @StateObject private var purchasePremium : PurchaseManager = .shared //Para las funciones Premium
    
    private let context2 = CoreDataController.shared.context
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)          var fontSizeFrases       : Int = 24
    @AppStorage(AppCons.UD_setting_fontContentSize)         var fontSizeContenido    : Int = 18
    @AppStorage(AppCons.UD_setting_fontMenuSize)            var fontSizeMenu         : Int = 18
    @AppStorage(AppCons.UD_setting_fontListaSize)           var fontSizeLista        : Int = 18
    @AppStorage(AppCons.UD_setting_NotasFaceID)             var setting_NotasFaceID  : Bool = false
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)          var fontSizeChatIA       : Int = 24 //Tamaño de letra del chat de IA
    
    //Acceso al Diario Siempre Activo:
    //Acceso a la opción de en Ajustes
    @AppStorage(AppCons.UD_setting_DiarioAccesoAjustes) var setting_DiarioAccesoAjustes  : Bool = false
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false
    
    
    @AppStorage(AppCons.UD_setting_theme) var setting_theme  : Theme = .auto 
    
    
    //Determina si el contenido de las ventanas modales se muestren en Details
    @AppStorage(AppCons.UD_setting_showEnDetails_diario)        var showEnDetails_diario            : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_evaluacion)    var showEnDetails_evaluacion        : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_ajustes)       var showEnDetails_ajustes           : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_chat_ia)       var showEnDetails_chat_ia           : Bool  = false
    
    
    //Tipo de chat de IA
    @AppStorage(AppCons.UD_setting_IA_AceptacionDescargo)       var DescargoDeIA : Bool = false // Si es true se permite utilizar la IA.
    @AppStorage(AppCons.UD_setting_IA_TratamientoPersonal)      var TratamientoDeIA : Bool = true // true: Representa a Neville, false: Tratamiento impersonal
    
    
    //Almacena internamente los colores de configuración. Al inicio se cargan los valores almacenados
    @State var ColorFrase       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_frases) ?? .black
    @State var ColorPrimario    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .purple
    @State var ColorSecundario  : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)
    
    
    //Colores de IA chat:
    @State var ColorChatIAPrimario         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.5)
    @State var ColorChatIASecundario       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorChatIAFuente           : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textContent) ?? .white
    @State var ColorRespondIAFuente        : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textRespond) ?? .black
    
    //Autenti
    private let contextLA = LAContext()
    //@State var canOpenToggleButton = false
    @State var showAlert = false
    @State var alertMessage = ""
    
    
    
    //Otros
    @State private var showSheet : Int? = nil
    
    //Devuelve la cantidad de elementos:
    private func getElementCount(element: String) -> Int {
        switch element {
        case "frases": modelFrases.listfrases.count
        case "conferencias": modelTxt.getArrayOfAllFileTxtOfType(type: .conf).count
        case "citas": modelTxt.getArrayOfAllFileTxtOfType(type: .citas).count
        case "preguntas": modelTxt.getArrayOfAllFileTxtOfType(type: .preg).count
        case "ayudas": modelTxt.getArrayOfAllFileTxtOfType(type: .ayud).count
        default: 0
        }
    }

    
    var body: some View {
        
        NavigationStack{
            
            
            #if os(macOS)
            ScrollView{
                VStack(alignment: .leading){
                    Group{
                        //Tamaños de Fuente
                        VStack(alignment: .leading){
                            Text("Tamaño de letra").font(.system(size: 22)).foregroundStyle(.orange)
                            HStack{
                                Text("Frases:")
                                    .font(.system(size:22))
                                Spacer()
                                Stepper(String(fontSizeFrases), value: $fontSizeFrases)
                                
                            }
                            
                            HStack{
                                Text("Contenido:")
                                    .font(.system(size:22))
                                Spacer()
                                Stepper(String(fontSizeContenido), value: $fontSizeContenido)
                                
                            }
                            
                            HStack{
                                Text("Menu:")
                                    .font(.system(size:22))
                                Spacer()
                                Stepper(String(fontSizeMenu), value: $fontSizeMenu)
                                
                            }
                            
                            HStack{
                                Text("Listas:")
                                    .font(.system(size:22))
                                Spacer()
                                Stepper(String(fontSizeLista), value: $fontSizeLista)
                                
                            }
                            if #available(iOS 26.0, macOS 26.0, *){
                                if IAModelAppleIntelligence.isAvailable(){
                                    HStack{
                                        Text("Chat IA:")
                                            .font(.system(size:22))
                                        Spacer()
                                        Stepper(String(fontSizeChatIA), value: $fontSizeChatIA)
                                        
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        VStack(alignment: .leading){
                            Text("Tema General").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            Picker("Elige el Tema:", selection: self.$setting_theme) {
                                ForEach(Theme.allCases, id:\.self){item in
                                    Text(item.rawValue).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        //Colores en Home
                        VStack(alignment: .leading){
                            
                            Text("Colores en Home").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            ColorPicker("Color de frases", selection: $ColorFrase)
                                .bold()
                                .onChange(of: ColorFrase, initial: true) { oldValue, newValue in
                                    settingModel.saveColor(forkey: AppCons.UD_setting_color_frases, color: newValue)
                                }
                                .frame(width: 240, alignment: .leading)
                            
                            HStack{
                                VStack(alignment: .leading, spacing: 10){
                                    ColorPicker("Color Degradado Superior", selection: $ColorPrimario)
                                        .onChange(of: ColorPrimario, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_color_main_a, color: newValue)
                                        }
                                        .frame(width: 240, alignment: .leading)
                                    
                                    ColorPicker("Color Degradado Inferior  ", selection: $ColorSecundario)
                                        .onChange(of: ColorSecundario, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_color_main_b, color: newValue)
                                        }
                                        .frame(width: 240, alignment: .leading)
                                }
                                
                                Spacer()
                                
                                VStack{
                                    Text("Muestra:").font(.footnote)
                                    Spacer()
                                    Text("")
                                        .frame(width: 200 ,  height: 60)
                                        .background(LinearGradient(colors: [ColorPrimario, ColorSecundario], startPoint: .top, endPoint: .bottom))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        //Colores del contenido IA
                        if #available(macOS 26.0, *){
                            if IAModelAppleIntelligence.isAvailable(){
                                
                                VStack(alignment: .leading){
                                    
                                    Text("Colores del Contenido IA").font(.system(size: 22)).foregroundStyle(.orange)
                                    
                                    ColorPicker("Color de Texto Chat IA          ", selection: $ColorChatIAFuente)
                                        .bold()
                                        .onChange(of: ColorChatIAFuente, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: newValue)
                                        }
                                    
                                    ColorPicker("Color de Texto Respuesta IA", selection: $ColorRespondIAFuente)
                                        .bold()
                                        .onChange(of: ColorRespondIAFuente, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: newValue)
                                        }
                                    
                                    HStack{
                                        VStack(alignment: .leading){
                                            ColorPicker("Color Degradado Superior", selection: $ColorChatIAPrimario)
                                                .frame(width: 220)
                                                .onChange(of: ColorChatIAPrimario, initial: true) { oldValue, newValue in
                                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: newValue)
                                                }
                                            
                                            ColorPicker("Color Degradado Inferior ", selection: $ColorChatIASecundario)
                                                .frame(width: 220)
                                                .onChange(of: ColorChatIASecundario, initial: true) { oldValue, newValue in
                                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: newValue)
                                                    
                                                }
                                        }
                                        Spacer()
                                        VStack{
                                            Text("Muestra:").font(.footnote)
                                            Spacer()
                                            Text("")
                                                .frame(width: 200 ,  height: 60)
                                                .background(LinearGradient(colors: [ColorChatIAPrimario, ColorChatIASecundario], startPoint: .top, endPoint: .bottom))
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                        }
                                        
                                    }
                                    
                                    Button("Aplicar Colores Por Defecto"){
                                        self.ColorChatIAFuente      = .white
                                        self.ColorChatIAPrimario    = .orange.opacity(0.5)
                                        self.ColorChatIASecundario  = .brown
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: self.ColorChatIAFuente)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: self.ColorChatIAPrimario)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: self.ColorChatIASecundario)
                                    }
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20)
                            }
                        }
                        
                        
                        //Utilización de la IA
                        
                        if #available(macOS 26.0, *){
                            if IAModelAppleIntelligence.isAvailable(){
                                
                                VStack(alignment: .leading, spacing: 10){
                                    Text("Utilización de la IA").font(.system(size: 22)).foregroundStyle(.orange)
                                    
                                    VStack(alignment: .leading ,spacing: 10){
                                        Text("Descargo de Responsabilidad")
                                            .font(.system(size: 20))
                                        HStack{
                                            Text("(\(self.DescargoDeIA ? "Aceptado" : "No aceptado")) ")
                                                .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Button("Acceder al Descargo de responsabilidad"){
                                                showWindow(for: DescargoResponsabilidadIA(VentanaEnSetting: true).foregroundStyle(.orange),
                                                           environmentObjects: [],
                                                           title: "Descargo de Responsabilidad",
                                                           size: AppCons.windows_size_content,
                                                           isModal: true
                                                           
                                                )
                                            }
                                            
                                        }
                                        Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero el Descargo de Responsabilidad.").font(.system(size: 15))
                                    }
                                    
                                    //Permitir Ajustar el tratamiento de la IA
                                    VStack(alignment: .leading, spacing: 10){
                                            Text("Papel interpretado por la IA:")
                                            .font(.system(size: 20))
                                        HStack{
                                            Text("\(self.TratamientoDeIA ? "La IA representa al Maestro, como si nos hablara en persona" : "La IA se muestra de manera impersonal y despectiva")")
                                                .font(.system(size: 15))
                                            Spacer()
                                            Toggle(isOn: self.$TratamientoDeIA) {
                                                Text(self.TratamientoDeIA ? "Personal" : "Impersonal")
                                                    .foregroundStyle(self.TratamientoDeIA ? .green : .primary)
                                            }
                                        }
                                        
                                    }
                                    .padding(.top, 10)
                                    
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20)
                            }
                        }
                        
                        
                        //Protección de Notas
                        VStack(alignment: .leading){
                            
                            Text("Protección de Notas").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            if self.securityModel.canOpenNotas {
                                if self.purchasePremium.isPremium{
                                    Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                                }else{
                                    Button("Se requiere Premium"){
                                        showWindow(for: PurchaseView(),
                                                   environmentObjects: [],
                                        title: "Habilitar Premium",
                                                   size: .percentage(width: 0.50, height: 0.50),
                                        isModal: false)
                                    }
                                }
                                
                            }else{
                                
                                //Chequeando si existe soporte biométrico:
                                if BiometryCheckerSupport.checkBiometricSupport() == .available{
                                    
                                    Button{
                                        UtilFuncs.autent(HabilitarContenido: self.$securityModel.canOpenToggleButtonNotas)
                                    }label: {
                                        Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                                    }
                                }else{ //NO existe biometría en el dispositivo
                                    //Si existe una contraseña guardada se intenta acceder por contraseña
                                    if KeychainHelper.shared.getPassword() != nil {
                                        
                                        Button("Acceder por contraseña"){
                                            showWindow(for: LogginView(ente: .Notas),
                                                       environmentObjects: [self.securityModel],
                                                       title: "Acceder por contraseña",
                                                       size: AppCons.windows_size_content_small,
                                                       isModal: true
                                                       
                                            )
                                            
                                        }
                                    }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                        Button("Crear una nueva Contraseña de Acceso"){
                                            showWindow(for: CreatePasswordView(),
                                                       environmentObjects: [],
                                                       title: "Crear una nueva Contraseña de Acceso",
                                                       size: AppCons.windows_size_content_small,
                                                       isModal: true
                                                       
                                            )
                                        }
                                    }
                                }
                            }
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        //Ventana del Diario siempre abierta, después del primer acceso
                        VStack(alignment: .leading){
                            Text("Ventana Diario Siempre Abierta").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            VStack(alignment: .leading, spacing: 15){
                                if self.setting_DiarioAccesoAjustes {
                                    Toggle("Diario Permanece Abierto", isOn: $setting_DiarioSiempreOpenFaceID)
                                }else{
                                    
                                    //Chequeando si existe soporte biométrico:
                                    if BiometryCheckerSupport.checkBiometricSupport() == .available{
                                        
                                        Button{
                                            UtilFuncs.autent(HabilitarContenido: self.$setting_DiarioAccesoAjustes)
                                        }label: {
                                            Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                                        }
                                    }else{ //NO existe biometría en el dispositivo
                                        //Si existe una contraseña guardada se intenta acceder por contraseña
                                        if KeychainHelper.shared.getPassword() != nil {
                                            Button("Acceder por contraseña"){
                                                showWindow(for: LogginView(ente: .AccesoADiarioAjustes),
                                                           environmentObjects: [self.securityModel],
                                                           title: "Acceder por contraseña",
                                                           size: AppCons.windows_size_content_small,
                                                           isModal: true
                                                           
                                                )
                                                
                                            }
                                        }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                            Button("Crear una nueva Contraseña de Acceso"){
                                                showWindow(for: CreatePasswordView(),
                                                           environmentObjects: [],
                                                           title: "Crear una nueva Contraseña de Acceso",
                                                           size: AppCons.windows_size_content_small,
                                                           isModal: true
                                                           
                                                )
                                            }
                                        }
                                    }
                                }
                                Text("Nota: Si se activa, el Diario permanece abierto una vez que se ha autentificado la primerá vez. Esto evita tener que loguearse en cada acceso al Diario. Al cerrarse la app el acceso al Diario se bloquea")
                                    .font(.system(size: 15))
                                    .frame(width: 600)
                            }
                            
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        
                        //Habilita una sección para recuperar la contraseña. Esta sección solo esta disponible en dispositivos con biometria y si ya previamente han almacenado una contraseña
                        if BiometryCheckerSupport.checkBiometricSupport() == .available {
                            //Si existe una contraseña guardada; sino no, no se muestra el botón para recuperar contraseña
                            if KeychainHelper.shared.getPassword() != nil {
                                VStack(alignment: .leading){
                                    
                                    Text("Contraseña Maestra").font(.system(size: 22)).foregroundStyle(.orange)
                                    
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
                                        Text("Nota: Permite modificar la contraseña para proteger el acceso al Diario y a Notas Protegidas").font(.system(size: 18))
                                    }
                                    
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20)
                                .alert(isPresented: $showAlert) {
                                    Alert(title: Text("La contraseña es:"), message: Text(self.alertMessage), dismissButton: .cancel())
                                }
                            }
                        }
                        
                        
                        //Sección de interruptores para mostrar contenido en la ventana Details
                        #if os(macOS)
                        VStack(alignment: .leading, spacing: 15){
                            Text("Incrustar estas ventanas:").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            Toggle("Chat IA", isOn: self.$showEnDetails_chat_ia)
                            Toggle("Diario", isOn: self.$showEnDetails_diario)
                            Toggle("Evaluación", isOn: self.$showEnDetails_evaluacion)
                            Toggle("Ajustes", isOn: self.$showEnDetails_ajustes)
                            
                            Text("Nota: Si marca una casilla, la ventana asociada se abrirá dentro de la aplicación principal").font(.system(size: 18))
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        #endif
                        
                        
                        
                        //Contacto e información
                        VStack(alignment: .leading, spacing: 15){
                            
                            Text("Contacto & Información").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            Button{
                                showWindow(for:
                                            VStack{
                                    Form{
                                        VStack(alignment: .leading, spacing: 10){
                                            HStack{
                                                Text("Versión")
                                                Spacer()
                                                Text("\(AppCons.appVersion ?? "")")
                                                    .foregroundStyle(.orange).bold()
                                            }
                                            HStack{
                                                Text("Frases")
                                                Spacer()
                                                Text("\(self.getElementCount(element: "frases"))")
                                            }
                                            HStack{
                                                Text("Conferencias")
                                                Spacer()
                                                Text("\(self.getElementCount(element: "conferencias"))")
                                            }
                                            HStack{
                                                Text("Citas")
                                                Spacer()
                                                Text("\(self.getElementCount(element: "citas"))")
                                            }
                                            HStack{
                                                Text("Preguntas")
                                                Spacer()
                                                Text("\(self.getElementCount(element: "preguntas"))")
                                            }
                                            HStack{
                                                Text("Ayudas")
                                                Spacer()
                                                Text("\(self.getElementCount(element: "ayudas"))")
                                                
                                            }
                                            
                                            HStack{
                                                Text("Reflexiones")
                                                Spacer()
                                                Text("\(ReflexModel.shared.getArrayReflexOfTxtFileGET().count)")
                                            }
                                            
                                            HStack{
                                                Text("Cuestionario")
                                                Spacer()
                                                Text("\(UtilFuncs.FileReadToArray("cuestionario").count)")
                                            }
                                        }
                                        
                                        
                                    }
                                    Spacer()
                                    Button("Cerrar"){
                                        if let window = NSApp.keyWindow {
                                            closeWindow(window)
                                        }
                                    }
                                }
                                    .padding(15) ,
                                           environmentObjects: [self.modelTxt, self.settingModel, self.modelFrases],
                                           title: "Información",
                                           size: AppCons.windows_size_content_small,
                                           isModal: true
                                           
                                )
                                
                            }label: {
                                Label("Información", systemImage: "info.circle.fill")
                                    .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            
                            Button{
                                showWindow(for: Novedades(),
                                           environmentObjects: [],
                                           title: "Novedades",
                                           size: AppCons.windows_size_content_small,
                                           isModal: false
                                )
                            }label:{
                                Label("Novedades en esta versión", systemImage: "info.circle.text.page.fill")
                                    .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                    .bold()
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button{
                                showWindow(for: ScrollView{
                                    Text(UtilFuncs.FileRead("privacy"))
                                        .font(.system(size: 22))
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                        .padding(10)
                                },
                                           environmentObjects: [],
                                           title: "Política de Privacidad",
                                           size: AppCons.windows_size_content,
                                           isModal: false
                                )
                                
                                
                            }label:{
                                Label("Política de Privacidad", systemImage: "square.and.pencil.circle")
                                    .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                    .bold()
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            ShareLink(item: URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696")!) {
                                HStack {
                                    Image("Logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24) // Ajusta el tamaño según sea necesario
                                    
                                    Text("Compartir la App")
                                        .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                        .bold()
                                        .font(.headline)
                                }
                                
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button{
                                showWindow(for: FeedbackView(showTextBotton: false),
                                           environmentObjects: [],
                                           title: "Enviar una Reseña a la App Store",
                                           size: AppCons.windows_size_content_small,
                                           isModal: true
                                )
                                
                            }label:{
                                Label("Deja una reseña!", systemImage:"bolt.heart.fill" )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
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
                            
                            NavigationLink{
                                PurchaseView()
                            }label: {
                                Label("Obtener funciones Premium", systemImage: "sparkles")
                                    .foregroundStyle(.orange)
                                    .bold()
                                    .font(.headline)
                            }
                            
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        
                    }
                    
                    
                }
            }
            .navigationTitle("Ajustes")
            #else //iOS,ipadOS.... NO macOS
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
                        if #available(iOS 26.0, macOS 26.0, *){
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
                    
                    Section("Tema General"){
                        
                        Picker("Elige el Tema:", selection: self.$setting_theme) {
                            ForEach(Theme.allCases, id:\.self){item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    
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
                                
                                ColorPicker("Color de Texto Chat IA", selection: $ColorChatIAFuente)
                                    .bold()
                                    .onChange(of: ColorChatIAFuente, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: newValue)
                                    }
                                
                                ColorPicker("Color de Texto Respuesta IA", selection: $ColorRespondIAFuente)
                                    .bold()
                                    .onChange(of: ColorRespondIAFuente, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: newValue)
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
                                    self.ColorChatIAFuente      = .white
                                    self.ColorChatIAPrimario    = .orange.opacity(0.5)
                                    self.ColorChatIASecundario  = .brown
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: self.ColorChatIAFuente)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: self.ColorChatIAPrimario)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: self.ColorChatIASecundario)
                                }
                            }
                        }
                    }
                    
                    
                    if #available(iOS 26.0, macOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            Section("Utilización de la IA"){
                                VStack(spacing: 10){
                                    HStack{
                                        Text("(\(self.DescargoDeIA ? "Aceptado" : "No aceptado")) ")
                                            .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                        NavigationLink("Acceder al Descargo de responsabilidad"){DescargoResponsabilidadIA(VentanaEnSetting: true)}.foregroundStyle(.orange)
                                    }
                                    Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero el Descargo de Responsabilidad.").font(Font.footnote.bold())
                                }
                                
                                //Permitir Ajustar el tratamiento de la IA
                                VStack(alignment: .leading){
                                        Text("Papel interpretado por la IA:")
                                    Toggle(isOn: self.$TratamientoDeIA) {
                                        Text(self.TratamientoDeIA ? "Personal" : "Impersonal")
                                            .foregroundStyle(self.TratamientoDeIA ? .green : .primary)
                                    }
                                    Text("\(self.TratamientoDeIA ? "La IA representa al Maestro, como si nos hablara en persona." : "La IA se muestra de manera impersonal y despectiva.")")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                    
                    
                    
                    Section("Proteger Acceso a Notas"){
                        if self.securityModel.canOpenNotas {
                            Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                        }else{
                            
                            //Chequeando si existe soporte biométrico:
                            if BiometryCheckerSupport.checkBiometricSupport() == .available{
                                
                                Button{
                                    UtilFuncs.autent(HabilitarContenido: self.$securityModel.canOpenNotas)
                                }label: {
                                    Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                                }
                            }else{ //NO existe biometría en el dispositivo
                                //Si existe una contraseña guardada se intenta acceder por contraseña
                                if KeychainHelper.shared.getPassword() != nil {
                                    NavigationLink("Acceder por contraseña"){
                                        LogginView(ente: .Notas)
                                    }
                                }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                    NavigationLink("Crear una nueva Contraseña de Acceso"){
                                        CreatePasswordView()
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    Section("Ventana Diario Siempre Abierta"){
                        VStack(alignment: .leading, spacing: 15){
                            if self.setting_DiarioAccesoAjustes {
                                Toggle("Diario Permanece Abierto", isOn: $setting_DiarioSiempreOpenFaceID)
                            }else{
                                
                                //Chequeando si existe soporte biométrico:
                                if BiometryCheckerSupport.checkBiometricSupport() == .available{
                                    
                                    Button{
                                        UtilFuncs.autent(HabilitarContenido: self.$setting_DiarioAccesoAjustes)
                                    }label: {
                                        Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                                    }
                                }else{ //NO existe biometría en el dispositivo
                                    //Si existe una contraseña guardada se intenta acceder por contraseña
                                    if KeychainHelper.shared.getPassword() != nil {
                                        NavigationLink("Acceder por contraseña"){
                                            LogginView(ente: .AccesoADiarioAjustes)
                                        }
                                    }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                        NavigationLink("Crear una nueva Contraseña de Acceso"){
                                            CreatePasswordView()
                                        }
                                    }
                                }
                            }
                            Text("Nota: Si se activa, el Diario permanece abierto una vez que se ha autentificado la primerá vez. Esto evita tener que loguearse en cada acceso al Diario. Al cerrarse la app el acceso al Diario se bloquea.")
                                .font(.subheadline)
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
                                    Text("\(self.getElementCount(element: "frases"))")
                                }.onTapGesture {self.showSheet = 1}
                                HStack{
                                    Text("Conferencias")
                                    Spacer()
                                    Text("\(self.getElementCount(element: "conferencias"))")
                                }.onTapGesture {self.showSheet = 2}
                                HStack{
                                    Text("Citas")
                                    Spacer()
                                    Text("\(self.getElementCount(element: "citas"))")
                                }.onTapGesture {self.showSheet = 3}
                                HStack{
                                    Text("Preguntas")
                                    Spacer()
                                    Text("\(self.getElementCount(element: "preguntas"))")
                                }.onTapGesture {self.showSheet = 4}
                                HStack{
                                    Text("Ayudas")
                                    Spacer()
                                    Text("\(self.getElementCount(element: "ayudas"))")
                                    
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
                            .navigationTitle("Información")
                        }label: {
                            Label("Información", systemImage: "info.circle.fill")
                                .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                        }
                        
                        NavigationLink{
                            Novedades()
                        }label:{
                            Label("Novedades en esta versión", systemImage: "info.circle.text.page.fill")
                                .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                .bold()
                                .font(.headline)
                        }
                        NavigationLink{
                            Features()
                        }label:{
                            Label("Caraterísticas de la App", systemImage: "info.circle.text.page.fill")
                                .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                .bold()
                                .font(.headline)
                        }
                        .tint(.green)
                        
                        NavigationLink{
                            NavigationStack{
                                ScrollView{
                                    SelectableText(UtilFuncs.FileRead("privacy"),fontSize: 22, fonColor: UIColor(Color.primary))
                                        .padding()
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
                        
                        NavigationLink{
                            PurchaseView()
                        }label: {
                            Label("Obtener funciones Premium", systemImage: "sparkles")
                                .foregroundStyle(.orange)
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
            #endif
            
        }
        .onDisappear(perform: {
            //Restablecer el acceso a la opción segura del Diario
            self.setting_DiarioAccesoAjustes = false
        })
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Configuración"), message: Text(alertMessage))
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



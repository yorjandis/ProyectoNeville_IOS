//
//  settingView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 28/10/23.
//

import SwiftUI
import LocalAuthentication
import CoreData
import UniformTypeIdentifiers
#if os(iOS)
import CoreLocation
#endif

struct Ajustes: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var modelTxt : TxtContentModel
    @EnvironmentObject private var modelFrases : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    @EnvironmentObject private var securityModel : SecurityModel
    
    //Funciones compras en la Aplicación
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    //Permite mostrar/Ocultar Metas en Home
    @AppStorage("MostrarMetasEnHome") var MostrarMetasEnHome: Bool = false
    @AppStorage("Home_ShowAgendaButton") var showAgendaButtonInHome: Bool = true

    @State private var showSheetPremiumView: Bool = false
    @State private var showCardioMusicImporter: Bool = false
    @State private var cardioMusicImportErrorMessage: String?
#if os(iOS)
    @StateObject private var notesLocationPermission = NotesLocationPermissionManager()
#endif
    
    private let context2 = CoreDataController.shared.context
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)          var fontSizeFrases       : Int = 24
    @AppStorage(AppCons.UD_setting_fontContentSize)         var fontSizeContenido    : Int = 18
    @AppStorage(AppCons.UD_setting_fontMenuSize)            var fontSizeMenu         : Int = 18
    @AppStorage(AppCons.UD_setting_fontListaSize)           var fontSizeLista        : Int = 18
    @AppStorage(AppCons.UD_setting_fontReminder)            var fontReminder         : Int = 18
    @AppStorage(AppCons.UD_setting_NotasFaceID)             var setting_NotasFaceID  : Bool = false
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)          var fontSizeChatIA       : Int = 24 //Tamaño de letra del chat de IA
    
    //Acceso al Diario Siempre Activo:
    //Acceso a la opción de en Ajustes
    @AppStorage(AppCons.UD_setting_DiarioAccesoAjustes) var setting_DiarioAccesoAjustes  : Bool = false
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false
    @AppStorage(AppCons.UD_setting_preferredMapApp) var preferredMapApp: String = LocationMapApp.appleMaps.rawValue
    
    
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
    /*
      Color(red: 1.00, green: 0.55, blue: 0.30), // naranja
      Color(red: 1.00, green: 0.80, blue: 0.45)  // amarillo suave
      */
    
    
    //Colores de IA chat:
    @State var ColorChatIAPrimario         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.5)
    @State var ColorChatIASecundario       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorChatIAFuente           : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textContent) ?? .white
    @State var ColorRespondIAFuente        : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textRespond) ?? .black
    
    //Opciones de Frases
    @AppStorage(AppCons.UD_setting_showHide_autor_in_frases) var showHideAutorInFrases : Bool = true // Muestra / oculta el aurtor en las frases del Home
    @AppStorage(CardioCoherenceConstants.Audio.useCustomMusicInSessionKey) private var useCustomCoherenceMusicInSession: Bool = false
    
    
    //Autenti
    private let contextLA = LAContext()
    //@State var canOpenToggleButton = false
    @State var showAlert = false
    @State var alertMessage = ""
    
    
    //Mostrar foto desarrollador:
    @State private var showSheetYorj = false
    
    
    
    //Otros
    @State private var showSheet : Int? = nil
    
    
    
    //Para Filtrar Frases en el Home
    @State private var filtroFrasesHome : CriterioFraseHome = .neville
    
    @State private var listFiltroFrasesHome: [CriterioFraseHome] = {
        let rawValues = UserDefaults.standard.stringArray(
            forKey: AppCons.UD_FiltroFrasesHome
        ) ?? []

        let criterios = rawValues.compactMap { CriterioFraseHome(rawValue: $0) }

        return criterios.isEmpty ? [.neville] : criterios
    }()
    
                                                                          
    
    //Devuelve la cantidad de elementos, para Información:
    private func getElementCount(element: String) -> Int {
        switch element {
        case "frases": modelFrases.getAllFrasesGet().count
        case "conferencias": modelTxt.getArrayOfAllFileTxtOfType(type: .conf).count
        case "citas": modelTxt.getArrayOfAllFileTxtOfType(type: .citas).count
        case "preguntas": modelTxt.getArrayOfAllFileTxtOfType(type: .preg).count
        case "ayudas": modelTxt.getArrayOfAllFileTxtOfType(type: .ayud).count
        default: 0
        }
    }
    
    //Tonos:
    @State private var selectedSound: NotificationSound = NotificationSound.selected

    private var settingsPrimaryTextColor: Color {
        #if os(macOS)
        return .white
        #else
        return theme == .dark ? .white : .black
        #endif
    }
    
    var body: some View {
        
        NavigationStack{
            
            //🔶🔶🔶🔶🔶🔶
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
                            
                            HStack{
                                Text("Recordatorios:")
                                    .font(.system(size:CGFloat(fontReminder)))
                                Spacer()
                                Stepper(String(fontReminder), value: $fontReminder)
                                
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
                        
                        //Thema
                        VStack(alignment: .leading){
                            Text("Tema General").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            Picker("Elige el Tema:", selection: self.$setting_theme) {
                                ForEach(Theme.allCases, id:\.self){item in
                                    Text(item.rawValue).tag(item)
                                        
                                }
                            }
                            .foregroundStyle(.orange)
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
                        
                        //Frases
                        VStack(alignment: .leading){
                            
                            Text("Frases").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            Toggle("Mostrar Autor en Frases del Home", isOn: self.$showHideAutorInFrases)
                                .padding(.vertical)

                            VStack(alignment: .leading, spacing: 8) {

                                    Text("Filtro de Frases en Home:")
                                HStack{
                                    
                                    Spacer()
                                    
                                        Menu("Añadir al Filtro:"){
                                            ForEach(CriterioFraseHome.allCases, id: \.self) { opcion in
                                                Button(opcion.getName){
                                                    if (self.purchaseStatus || self.yorjPremium){
                                                        toggleFiltro(opcion)
                                                    }else{
                                                        if opcion.rawValue != "neville"{
                                                            self.alertMessage = "Disponible en Versión Extendida"
                                                            self.showAlert = true
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                }

                                    if !listFiltroFrasesHome.isEmpty {
                                        VStack(alignment: .leading, spacing: 6) {
                                            ForEach(listFiltroFrasesHome, id: \.self) { criterio in
                                                HStack(spacing: 25){
                                                    Button {
                                                        removeFiltro(criterio)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundStyle(.red)
                                                    }
                                                    .buttonStyle(.plain)
                                                    .padding(.horizontal, 5)
                                                    
                                                    Text(criterio.getName)
                                                        .font(.footnote)

                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
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
                                        Text("Condiciones de Uso de la IA")
                                            .font(.system(size: 20))
                                        HStack{
                                            Text("(\(self.DescargoDeIA ? "Aceptado" : "No aceptado")) ")
                                                .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Button("Acceder a las Condiciones de Uso de la IA"){
                                                showWindow(for: DescargoResponsabilidadIA(VentanaEnSetting: true).foregroundStyle(.orange),
                                                           environmentObjects: [],
                                                           title: "Condiciones de Uso de la IA",
                                                           size: AppCons.windows_size_content,
                                                           isModal: true
                                                           
                                                )
                                            }
                                            
                                        }
                                        Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero las Condiciones de Uso de la IA.").font(.system(size: 15))
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
                                                    .foregroundStyle(self.TratamientoDeIA ? .green : settingsPrimaryTextColor)
                                            }
                                        }
                                        
                                    }
                                    .padding(.top, 10)
                                    
                                }
                                .padding(.horizontal, 30)
                                .padding(.bottom, 20)
                            }
                        }
                        
                        
                        //Notas
                        VStack(alignment: .leading){
                            
                            Text("Notas").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            if self.securityModel.canOpenNotas {
                                if (self.purchaseStatus || self.yorjPremium){
                                    Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                                }else{
                                    Button("Se requiere Versión Extendida"){
                                        showWindow(for: PurchaseView(),
                                                   environmentObjects: [],
                                        title: "Habilitar Versión Extendida",
                                                   size: .percentage(width: 0.50, height: 0.50),
                                        isModal: true)
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
                        
                        
                        //Recordatorios(Versión Extendida):
                        VStack(alignment: .leading){
                            
                            Text("Recordatorios").font(.system(size: 22)).foregroundStyle(.orange)
                            
                            HStack{
                                NotificationSoundPicker(selection: $selectedSound) //Selector de tonos
                            }
                            .padding()
                            .onChange(of: selectedSound) { _, newValue in
                                NotificationSound.selected = newValue
                            }
                            //Reproducir el sonido del tono
                            HStack{
                               
                                Button {
                                    NotificationSoundPreview.shared.play(selectedSound)
                                } label: {
                                    Label("Reproducir sonido", systemImage: "speaker.wave.2")
                                }
                                .disabled(selectedSound == .default)
                                
                                Spacer()
                            }
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        VStack(alignment: .leading){
                            Text("Metas").font(.system(size: 22)).foregroundStyle(.orange)
                            Toggle("Mostrar Las Metas en Home", isOn: self.$MostrarMetasEnHome)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)

                        VStack(alignment: .leading){
                            Text("Agenda").font(.system(size: 22)).foregroundStyle(.orange)
                            Toggle("Mostrar botón Agenda en Home", isOn: self.$showAgendaButtonInHome)
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
                                                Text("Desarrollador")
                                                Spacer()
                                                Text("Yorjandi PG")
                                                    .foregroundStyle(.orange).bold()
                                                    .onTapGesture(count: 2) {
                                                        #if os(macOS)
                                                        showWindow(for: VStack{
                                                            Image("yorj")
                                                                .resizable()
                                                                .scaledToFit()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 250, height: 250)
                                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                                .shadow(radius: 8, y: 4)
                                                                .padding()
                                                            
                                                            Text("Yorjandi PG")
                                                                .padding()
                                                            
                                                            Button("Cerrar"){
                                                                if let window = NSApp.keyWindow {
                                                                    closeWindow(window)
                                                                    }
                                                            }
                                                            .padding()
                                                            
                                                                
                                                        },
                                                                   environmentObjects: [],
                                                                   title: "Desarrollador",
                                                                   size: AppCons.windows_size_content_small,
                                                                   isModal: true)
                                                        
                                                        #else
                                                        self.showSheetYorj = true
                                                        #endif
                                                        
                                                    }
                                            }
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
                                    .foregroundStyle(settingsPrimaryTextColor)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            
                            Button{
                                showWindow(for: Features(),
                                           environmentObjects: [],
                                           title: "Novedades",
                                           size: AppCons.windows_size_content_small,
                                           isModal: false
                                )
                            }label:{
                                Label("Caraterísticas de la App", systemImage: "info.circle.text.page.fill")
                                    .foregroundStyle(settingsPrimaryTextColor)
                                    .bold()
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button{
                                showWindow(for: ScrollView{
                                    Text(UtilFuncs.FileRead("neville-ios-privacy-policy"))
                                        .font(.system(size: 22))
                                        .foregroundStyle(settingsPrimaryTextColor)
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
                                    .foregroundStyle(settingsPrimaryTextColor)
                                    .bold()
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button{
                                showWindow(for: ScrollView{
                                    Text(UtilFuncs.FileRead("neville-ios-terms-of-use"))
                                        .font(.system(size: 22))
                                        .foregroundStyle(settingsPrimaryTextColor)
                                        .textSelection(.enabled)
                                        .padding(10)
                                },
                                           environmentObjects: [],
                                           title: "Política de Privacidad",
                                           size: AppCons.windows_size_content,
                                           isModal: false
                                )
                                
                                
                            }label:{
                                Label("Términos de uso", systemImage: "square.and.pencil.circle")
                                    .foregroundStyle(settingsPrimaryTextColor)
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
                                        .foregroundStyle(settingsPrimaryTextColor)
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
                                    .foregroundStyle(settingsPrimaryTextColor)
                                    .bold()
                                    .font(.headline)
                            }
                       
                            if !self.purchaseStatus{
                                NavigationLink{
                                    PurchaseView()
                                }label: {
                                    Label("Obtener Versión Extendida", systemImage: "sparkles")
                                        .foregroundStyle(.orange)
                                        .bold()
                                        .font(.headline)
                                }
                            }
                            
                            
                            
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        
                        
                        
                    }
                    
                    
                }
                .foregroundStyle(settingsPrimaryTextColor)
            }
            .navigationTitle("Ajustes")
            //🔶🔶🔶🔶🔶🔶
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
                        
                        HStack{
                            Text("Recordatorios:")
                                .font(.system(size:CGFloat(fontReminder)))
                            Spacer()
                            Stepper(String(fontReminder), value: $fontReminder)
                            
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
                                    .frame(width: 200 ,  height: 120)
                                    .background(LinearGradient(colors: [ColorPrimario, ColorSecundario], startPoint: .top, endPoint: .bottom))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            Button("Yorj"){
                                print(self.ColorPrimario)
                                print(self.ColorSecundario)
                            }
                            
                        }
                    }
                    
                    
                    //Colores del Chat IA
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
                    
                    //Opciones de Frases
                    Section("Frases"){
                        Toggle("Mostrar Autor en Frases del Home", isOn: self.$showHideAutorInFrases)
                        
                        VStack(alignment: .leading, spacing: 8) {

                                Text("Filtro de Frases en Home:")
                            HStack{
                                
                                Spacer()
                                
                                 Menu("Añadir al Filtro:"){
                                     ForEach(CriterioFraseHome.allCases, id: \.self) { opcion in
                                         Button(opcion.getName){
                                             if (self.purchaseStatus || self.yorjPremium){
                                                 toggleFiltro(opcion)
                                             }else{
                                                 if opcion.rawValue != "neville"{
                                                     self.alertMessage = "Disponible en Versión Extendida"
                                                     self.showAlert = true
                                                 }
                                             }
                                             
                                         }
                                     }
                                 }
                                 .buttonStyle(.bordered)
                            }

                                if !listFiltroFrasesHome.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        ForEach(listFiltroFrasesHome, id: \.self) { criterio in
                                            HStack(spacing: 25){
                                                Button {
                                                    removeFiltro(criterio)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundStyle(.red)
                                                }
                                                .buttonStyle(.plain)
                                                .padding(.horizontal, 5)
                                                
                                                Text(criterio.getName)
                                                    .font(.footnote)

                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                         
                        
                    }
                    
                    //Utilización de la IA:
                    if #available(iOS 26.0, macOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            Section("Utilización de la IA"){
                                VStack(spacing: 10){
                                    HStack{
                                        Text("(\(self.DescargoDeIA ? "Aceptado" : "No aceptado")) ")
                                            .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                        NavigationLink("Acceder a las Condiciones de Uso de la IA"){DescargoResponsabilidadIA(VentanaEnSetting: true)}.foregroundStyle(.orange)
                                    }
                                    Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero las Condiciones de Uso de la IA.").font(Font.footnote.bold())
                                }
                                
                                //Permitir Ajustar el tratamiento de la IA
                                VStack(alignment: .leading){
                                        Text("Papel interpretado por la IA:")
                                    Toggle(isOn: self.$TratamientoDeIA) {
                                        Text(self.TratamientoDeIA ? "Personal" : "Impersonal")
                                            .foregroundStyle(self.TratamientoDeIA ? .green : settingsPrimaryTextColor)
                                    }
                                    Text("\(self.TratamientoDeIA ? "La IA representa al Maestro, como si nos hablara en persona." : "La IA se muestra de manera impersonal y despectiva.")")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
                    
                    
                    //Notas
                    Section("Notas"){
                        if self.securityModel.canOpenNotas {
                            if (self.purchaseStatus || self.yorjPremium) {
                                Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                            }else{
                                Text("Acceso a Versión Extendida")
                                    .foregroundStyle(.orange).bold()
                                    .onTapGesture {
                                        self.showSheetPremiumView = true
                                    }
                            }
                            
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

                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                notesLocationPermission.requestWhenInUsePermission()
                            } label: {
                                Label(notesLocationPermission.buttonTitle, systemImage: "location.fill")
                            }
                            .disabled(!notesLocationPermission.canRequestPermission)

                            Text(notesLocationPermission.statusDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        
                    }
                    
                    //Ventana del Diario siempre abierte, después del primer uso:
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
                    
                    //Recordatorios(Premium):
                    Section("Recordatorios"){
                        HStack{
                            NotificationSoundPicker(selection: $selectedSound) //Selector de tonos
                        }
                        .padding()
                        //Reproducir el sonido del tono
                        HStack{
                            Spacer()
                            Button {
                                NotificationSoundPreview.shared.play(selectedSound)
                            } label: {
                                Label("Reproducir sonido", systemImage: "speaker.wave.2")
                            }
                            .disabled(selectedSound == .default)
                        }
                        .onChange(of: selectedSound) { _, newValue in
                            NotificationSound.selected = newValue
                        }
                        
                    }

                    Section("Espacio Calma") {
                        if (self.purchaseStatus || self.yorjPremium) {
                            NavigationLink {
                                CalmResourcesManagerView()
                            } label: {
                                Label("Agrega tus propios fondos y música", systemImage: "photo.on.rectangle.angled")
                            }

                            NavigationLink {
                                CalmPhraseManagerView()
                            } label: {
                                Label("Gestiona tus frases personalizadas", systemImage: "quote.bubble")
                            }
                        } else {
                            Button {
                                self.showSheetPremiumView = true
                            } label: {
                                Label("Disponible en Versión Extendida", systemImage: "sparkles")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Section("Abrir Ubicación en Mapas") {
                        Picker("Aplicación", selection: $preferredMapApp) {
                            ForEach(LocationMapApp.allCases) { option in
                                Text(option.title).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Coherencia Cardio-Cerebral") {
                        Button {
                            showCardioMusicImporter = true
                        } label: {
                            Label("Seleccionar música personal", systemImage: "music.note")
                        }

                        if let selectedURL = CardioCoherenceCustomMusicStore.currentCustomMusicURL() {
                            HStack {
                                Label(selectedURL.lastPathComponent, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Spacer()
                                Button(role: .destructive) {
                                    CardioCoherenceCustomMusicStore.clearMusic()
                                    useCustomCoherenceMusicInSession = false
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                            }
                        } else {
                            Label("No has seleccionado música personal", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.secondary)
                        }

                        Toggle("Usar música personal en sesión", isOn: $useCustomCoherenceMusicInSession)
                            .disabled(CardioCoherenceCustomMusicStore.currentCustomMusicURL() == nil)
                    }

                    Section("Agenda") {
                        Toggle("Mostrar botón Agenda en Home", isOn: self.$showAgendaButtonInHome)
                    }
                    
                    //Metas
                    Section("Metas"){
                        HStack{
                            Toggle(isOn: self.$MostrarMetasEnHome) {
                             Text("Mostrar Metas en Home")
                            }
                        }
                    }
                    
                    
                    //Sección:  recuperar la contraseña. Esta sección solo esta disponible en dispositivos con biometria y si ya previamente han almacenado una contraseña
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
                                    Text("Desarrollador")
                                    Spacer()
                                    Text("Yorjandi PG")
                                        .foregroundStyle(.orange).bold()
                                        .onTapGesture(count: 2) {
                                            self.showSheetYorj = true
                                        }
                                }
                                HStack{
                                    Text("Versión")
                                    Spacer()
                                    Text("\(AppCons.appVersion ?? "")")
                                        
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
                                .foregroundStyle(settingsPrimaryTextColor)
                        }
                        /*
                         NavigationLink{
                             Novedades()
                         }label:{
                             Label("Novedades en esta versión", systemImage: "info.circle.text.page.fill")
                                 .foregroundStyle(settingsPrimaryTextColor)
                                 .bold()
                                 .font(.headline)
                         }
                         */
                        
                        NavigationLink{
                            Features()
                        }label:{
                            Label("Caraterísticas de la App", systemImage: "info.circle.text.page.fill")
                                .foregroundStyle(settingsPrimaryTextColor)
                                .bold()
                                .font(.headline)
                        }
                        .tint(.green)

                        NavigationLink {
                            TutorialVideosListView()
                        } label: {
                            Label("Videos de demostración", systemImage: "play.rectangle.fill")
                                .foregroundStyle(settingsPrimaryTextColor)
                                .bold()
                                .font(.headline)
                        }
                        .tint(.red)
                        
                        NavigationLink{
                            NavigationStack{
                                ScrollView{
                                    SelectableText(text : UtilFuncs.FileRead("neville-ios-privacy-policy"),fontSize: 22, fonColor: UIColor(Color.primary))
                                        .padding()
                                }.navigationTitle("Ajustes - Privacy")
                            }
                        }label:{
                            Label("Política de Privacidad", systemImage: "square.and.pencil.circle")
                                .foregroundStyle(settingsPrimaryTextColor)
                                .bold()
                                .font(.headline)
                        }
                        
                        NavigationLink{
                            NavigationStack{
                                ScrollView{
                                    SelectableText(text : UtilFuncs.FileRead("neville-ios-terms-of-use"),fontSize: 22, fonColor: UIColor(Color.primary))
                                        .padding()
                                }.navigationTitle("Ajustes - Privacy")
                            }
                        }label:{
                            Label("Términos de uso", systemImage: "square.and.pencil.circle")
                                .foregroundStyle(settingsPrimaryTextColor)
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
                                    .foregroundStyle(settingsPrimaryTextColor)
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
                                .foregroundStyle(settingsPrimaryTextColor)
                                .bold()
                                .font(.headline)
                        }

                        if !self.purchaseStatus {
                            NavigationLink{
                                PurchaseView()
                            }label: {
                                Label("Obtener funciones Extendidas", systemImage: "sparkles")
                                    .foregroundStyle(.orange)
                                    .bold()
                                    .font(.headline)
                            }
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
        .onChange(of: yorjPremium) { _, _ in
            PurchaseManager.shared.syncPremiumFlags()
        }
#if os(iOS)
        .onAppear {
            notesLocationPermission.refreshStatus()
        }
#endif
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
        .sheet(isPresented: self.$showSheetPremiumView) {
            PurchaseView()
        }
        .sheet(isPresented: self.$showSheetYorj) {
            VStack{
                Image("yorj")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 250, height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(radius: 8, y: 4)
                    .padding()
                
                Text("Yorjandi PG")
                    .padding()
                
                    
            }
            .presentationDetents([.medium])
        }
        .fileImporter(
            isPresented: $showCardioMusicImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let sourceURL = urls.first else { return }
                do {
                    try CardioCoherenceCustomMusicStore.replaceMusic(with: sourceURL)
                    useCustomCoherenceMusicInSession = true
                } catch {
                    cardioMusicImportErrorMessage = "No se pudo importar el archivo de música."
                }
            case .failure:
                cardioMusicImportErrorMessage = "No se pudo abrir el selector de archivos."
            }
        }
        .alert("Coherencia Cardio-Cerebral", isPresented: Binding(
            get: { cardioMusicImportErrorMessage != nil },
            set: { value in
                if !value { cardioMusicImportErrorMessage = nil }
            }
        )) {
            Button("Aceptar", role: .cancel) {
                cardioMusicImportErrorMessage = nil
            }
        } message: {
            Text(cardioMusicImportErrorMessage ?? "")
        }
    }
    
  //Funciones para el filtro de Frases en el Home:
    private func toggleFiltro(_ criterio: CriterioFraseHome) {

        if criterio == .todasFrases {
            listFiltroFrasesHome = [.todasFrases]
        } else {
            listFiltroFrasesHome.removeAll { $0 == .todasFrases }

            if !listFiltroFrasesHome.contains(criterio) {
                listFiltroFrasesHome.append(criterio)
            }
        }

        guardarFiltros()
    }
    
    private func removeFiltro(_ criterio: CriterioFraseHome) {

        listFiltroFrasesHome.removeAll { $0 == criterio }

        if listFiltroFrasesHome.isEmpty {
            listFiltroFrasesHome = [.neville]
        }

        guardarFiltros()
    }
    
    private func guardarFiltros() {
        let values = listFiltroFrasesHome.map { $0.rawValue }

        UserDefaults.standard.set(values, forKey: AppCons.UD_FiltroFrasesHome)
        UserDefaults(suiteName: AppCons.AppGroupName)?.set(values, forKey: AppCons.UD_FiltroFrasesHome)
        NSUbiquitousKeyValueStore.default.set(values, forKey: AppCons.UD_FiltroFrasesHome)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
}

extension Int: @retroactive Identifiable {
    public var id: Int { return self }
}

#if os(iOS)
@MainActor
final class NotesLocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        refreshStatus()
    }

    var canRequestPermission: Bool {
        authorizationStatus == .notDetermined
    }

    var buttonTitle: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Solicitar permiso de ubicación"
        case .authorizedWhenInUse, .authorizedAlways:
            return "Permiso de ubicación concedido"
        case .denied, .restricted:
            return "Permiso de ubicación no disponible"
        @unknown default:
            return "Estado de ubicación no reconocido"
        }
    }

    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Permite guardar la dirección actual al crear o editar una nota."
        case .authorizedWhenInUse, .authorizedAlways:
            return "Las notas pueden guardar la ubicación actual cuando uses esta opción."
        case .denied:
            return "El permiso fue denegado. Puedes activarlo desde Ajustes del sistema."
        case .restricted:
            return "El acceso a la ubicación está restringido en este dispositivo."
        @unknown default:
            return "No se pudo determinar el estado del permiso de ubicación."
        }
    }

    func refreshStatus() {
        authorizationStatus = manager.authorizationStatus
    }

    func requestWhenInUsePermission() {
        refreshStatus()

        guard CLLocationManager.locationServicesEnabled() else {
            authorizationStatus = .restricted
            return
        }

        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }
}
#endif

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
    @AppStorage("Home_ShowMyDayButton") private var showMyDayButtonInHome: Bool = true
    @AppStorage("Home_ShowAgendaButton") var showAgendaButtonInHome: Bool = true
    @AppStorage(PetSettings.isEnabledKey) private var petsEnabled = true
    @AppStorage(PetSettings.selectedPetKey) private var selectedPetAssetName = PetSettings.defaultPetAssetName
    #if os(iOS)
    @AppStorage("Home_ShowPresenceButton") private var showPresenceButtonInHome: Bool = true
    @AppStorage(PresenciaSettings.customCelebrationPhraseKey) private var presenciaCelebrationPhrase = PresenciaSettings.defaultCelebrationPhrase
    @AppStorage(AppCons.UD_setting_HomeProductividadPresenciaTotal) private var homeProductividadPresenciaTotal: Int = 5
    @AppStorage(AppCons.UD_setting_HomeProductividadMetasTotal) private var homeProductividadMetasTotal: Int = 1
    @AppStorage(AppCons.UD_setting_HomeAlternativoShowHealingCenterCard) private var showHealingCenterCardInHomeAlternativo: Bool = true
    #endif

    @State private var showSheetPremiumView: Bool = false
    @State private var showCardioMusicImporter: Bool = false
    @State private var cardioMusicImportErrorMessage: String?
#if os(iOS)
    @StateObject private var locationPermission = LocationPermissionManager()
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
    @AppStorage(AppCons.UD_setting_WeeklyReviewWeekday) private var weeklyReviewWeekday: Int = WeeklyReviewDay.sunday.rawValue
    @AppStorage(AppCons.UD_setting_WeeklyReviewNotificationsEnabled) private var weeklyReviewNotificationsEnabled = false
    @AppStorage(AppCons.UD_setting_WeeklyReviewRecordsToKeep) private var weeklyReviewRecordsToKeep = WeeklyReviewRetentionPolicy.defaultRecordsToKeep
    
    
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
    @State var ColorChatIAPrimario: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_main_a
    ) ?? AppCons.defaultColorIA_main_a
    @State var ColorChatIASecundario: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_main_b
    ) ?? AppCons.defaultColorIA_main_b
    @State var ColorChatIAFuente: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_textContent
    ) ?? AppCons.defaultColorIA_promptText
    @State var ColorRespondIAFuente: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_textRespond
    ) ?? AppCons.defaultColorIA_responseText
    @State var ColorRespondIABurbuja: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_responseBubble
    ) ?? AppCons.defaultColorIA_responseBubble
    
    //Opciones de Frases
    @AppStorage(AppCons.UD_setting_showHide_autor_in_frases) var showHideAutorInFrases : Bool = true // Muestra / oculta el aurtor en las frases del Home
    @AppStorage(CardioCoherenceConstants.Audio.useCustomMusicInSessionKey) private var useCustomCoherenceMusicInSession: Bool = false
    
    
    //Autenti
    private let contextLA = LAContext()
    //@State var canOpenToggleButton = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State private var showWeeklyReviewRetentionConfirmation = false
    
    
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

    private func localizedThemeTitle(_ theme: Theme) -> String {
        switch theme {
        case .auto:
            return L10n.exact("Automático")
        case .light:
            return L10n.exact("Claro")
        case .dark:
            return L10n.exact("Oscuro")
        }
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
                                    Text(localizedThemeTitle(item)).tag(item)
                                        
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
                                                Button(L10n.exact(opcion.getName)){
                                                    toggleFiltro(opcion)
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
                                                    
                                                    Text(L10n.exact(criterio.getName))
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
                                    
                                    ColorPicker("Color del texto del prompt", selection: $ColorChatIAFuente)
                                        .bold()
                                        .onChange(of: ColorChatIAFuente, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: newValue)
                                        }
                                    
                                    ColorPicker("Color del texto de las respuestas", selection: $ColorRespondIAFuente)
                                        .bold()
                                        .onChange(of: ColorRespondIAFuente, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: newValue)
                                        }

                                    ColorPicker("Fondo de las burbujas de respuesta", selection: $ColorRespondIABurbuja)
                                        .bold()
                                        .onChange(of: ColorRespondIABurbuja, initial: true) { oldValue, newValue in
                                            settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_responseBubble, color: newValue)
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
                                        self.ColorChatIAFuente = AppCons.defaultColorIA_promptText
                                        self.ColorRespondIAFuente = AppCons.defaultColorIA_responseText
                                        self.ColorChatIAPrimario = AppCons.defaultColorIA_main_a
                                        self.ColorChatIASecundario = AppCons.defaultColorIA_main_b
                                        self.ColorRespondIABurbuja = AppCons.defaultColorIA_responseBubble
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: self.ColorChatIAFuente)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: self.ColorRespondIAFuente)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: self.ColorChatIAPrimario)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: self.ColorChatIASecundario)
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_responseBubble, color: self.ColorRespondIABurbuja)
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
                                            Text(L10n.format(
                                                "settings.ai_acceptance_status",
                                                fallback: "({0})",
                                                L10n.exact(self.DescargoDeIA ? "Aceptado" : "No aceptado")
                                            ))
                                                .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Button("Acceder a las Condiciones de Uso de la IA"){
                                                showWindow(for: DescargoResponsabilidadIA(VentanaEnSetting: true).foregroundStyle(.orange),
                                                           environmentObjects: [],
                                                           title: L10n.exact("Condiciones de Uso de la IA"),
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
                                            Text(L10n.exact(
                                                self.TratamientoDeIA
                                                    ? "La IA representa al Maestro, como si nos hablara en persona"
                                                    : "La IA se muestra de manera impersonal y neutral"
                                            ))
                                                .font(.system(size: 15))
                                            Spacer()
                                            Toggle(isOn: self.$TratamientoDeIA) {
                                                Text(L10n.exact(self.TratamientoDeIA ? "Personal" : "Impersonal"))
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
                                        title: L10n.exact("Habilitar Versión Extendida"),
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
                                                       title: L10n.exact("Acceder por contraseña"),
                                                       size: AppCons.windows_size_content_small,
                                                       isModal: true
                                                       
                                            )
                                            
                                        }
                                    }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                        Button("Crear una nueva Contraseña de Acceso"){
                                            showWindow(for: CreatePasswordView(),
                                                       environmentObjects: [],
                                                       title: L10n.exact("Crear una nueva Contraseña de Acceso"),
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
                                                           title: L10n.exact("Acceder por contraseña"),
                                                           size: AppCons.windows_size_content_small,
                                                           isModal: true
                                                           
                                                )
                                                
                                            }
                                        }else{ //No existe contraseña guardada. Permitir crear una contraseña
                                            Button("Crear una nueva Contraseña de Acceso"){
                                                showWindow(for: CreatePasswordView(),
                                                           environmentObjects: [],
                                                           title: L10n.exact("Crear una nueva Contraseña de Acceso"),
                                                           size: AppCons.windows_size_content_small,
                                                           isModal: true
                                                           
                                                )
                                            }
                                        }
                                    }
                                }
                                Text("Nota: Si se activa, el Diario permanece abierto una vez que se ha autentificado la primera vez. Esto evita tener que iniciar sesión en cada acceso al Diario. Al cerrarse la app, el acceso al Diario se bloquea.")
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
                            Text("Ritual Matutino").font(.system(size: 22)).foregroundStyle(.orange)
                            Toggle("Mostrar botón Mi día en Home", isOn: self.$showMyDayButtonInHome)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)

                        VStack(alignment: .leading){
                            Text("Agenda").font(.system(size: 22)).foregroundStyle(.orange)
                            Toggle("Mostrar botón Agenda en Home", isOn: self.$showAgendaButtonInHome)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Revisión semanal").font(.system(size: 22)).foregroundStyle(.orange)
                            Picker("Día del resumen", selection: $weeklyReviewWeekday) {
                                ForEach(WeeklyReviewDay.allCases) { day in
                                    Text(day.title).tag(day.rawValue)
                                }
                            }
                            .frame(width: 280)
                            .onChange(of: weeklyReviewWeekday) { _, newValue in
                                WeeklyReviewNotificationManager.update(
                                    enabled: weeklyReviewNotificationsEnabled,
                                    weekday: newValue
                                )
                            }

                            Toggle("Recordatorio semanal a las 6:00", isOn: $weeklyReviewNotificationsEnabled)
                                .onChange(of: weeklyReviewNotificationsEnabled) { _, newValue in
                                    WeeklyReviewNotificationManager.update(
                                        enabled: newValue,
                                        weekday: weeklyReviewWeekday
                                    )
                                }

                            Text(weeklyReviewShortAvailabilityDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Divider()
                                .padding(.vertical, 4)

                            Stepper(
                                weeklyReviewRetentionLabel,
                                value: $weeklyReviewRecordsToKeep,
                                in: WeeklyReviewRetentionPolicy.minimumRecordsToKeep...WeeklyReviewRetentionPolicy.maximumRecordsToKeep,
                                step: WeeklyReviewRetentionPolicy.recordStep
                            )
                            .onChange(of: weeklyReviewRecordsToKeep) { _, newValue in
                                weeklyReviewRecordsToKeep = WeeklyReviewRetentionPolicy.normalizedRecordsToKeep(newValue)
                            }

                            Button(role: .destructive) {
                                showWeeklyReviewRetentionConfirmation = true
                            } label: {
                                Label("Eliminar revisiones antiguas", systemImage: "trash")
                            }

                            Text(weeklyReviewCleanupDescription)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)
                        .onAppear {
                            WeeklyReviewNotificationManager.update(
                                enabled: weeklyReviewNotificationsEnabled,
                                weekday: weeklyReviewWeekday
                            )
                        }
                        
                        //Habilita una sección para recuperar la contraseña. Esta sección solo esta disponible en dispositivos con biometria y si ya previamente han almacenado una contraseña
                        if BiometryCheckerSupport.checkBiometricSupport() == .available {
                            //Si existe una contraseña guardada; sino no, no se muestra el botón para recuperar contraseña
                            if KeychainHelper.shared.getPassword() != nil {
                                VStack(alignment: .leading){
                                    
                                    Text("Contraseña Maestra").font(.system(size: 22)).foregroundStyle(.orange)
                                    
                                    Button("Recupera Contraseña Para Acceder al Diario y Notas"){
                                        //Intentando obtener la clave
                                        if let clave = KeychainHelper.shared.getPassword() {
                                            self.alertMessage = L10n.format(
                                                "settings.master_password_value",
                                                fallback: "La clave es: {0}",
                                                clave
                                            ) //Almacena la clave
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
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Migración iOS / Android")
                                .font(.system(size: 22))
                                .foregroundStyle(.orange)

                            Button {
                                showWindow(for: NavigationStack {
                                    MigrationIOSAndroidView()
                                },
                                           environmentObjects: [],
                                           title: L10n.exact("Migración iOS / Android"),
                                           size: .percentage(width: 0.50, height: 0.70),
                                           isModal: false)
                            } label: {
                                Label("Exportar a Android / Importar desde Android", systemImage: "arrow.left.arrow.right.circle")
                                    .foregroundStyle(settingsPrimaryTextColor)
                                    .bold()
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text("Crea o lee archivos .ypgexp cifrados y compatibles con Android.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 20)

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
                                                                   title: L10n.exact("Desarrollador"),
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
                                           title: L10n.exact("Información"),
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
                                           title: L10n.exact("Novedades"),
                                           size: AppCons.windows_size_content_small,
                                           isModal: false
                                )
                            }label:{
                                Label("Características de la App", systemImage: "info.circle.text.page.fill")
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
                                           title: L10n.exact("Política de Privacidad"),
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
                                           title: L10n.exact("Términos de uso"),
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
                                           title: L10n.exact("Enviar una Reseña a la App Store"),
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
                    Section("Salud y HealthKit") {
                        NavigationLink {
                            StressHistoryView(monitor: StressMonitor.shared)
                        } label: {
                            Label("Estrés fisiológico con HealthKit", systemImage: "heart.text.square.fill")
                        }

                        Text("Con tu permiso, La Ley usa HealthKit para leer pulso, VFC, respiración, pasos y entrenamientos guardados por Apple Watch y la app Salud. Los datos se procesan en este dispositivo y La Ley no añade ni modifica datos de Salud.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
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
                                Text(localizedThemeTitle(item)).tag(item)
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
                           
                            
                        }
                    }
                    
                    
                    //Colores del Chat IA
                    if #available(iOS 26.0, macOS 26.0, *){
                        if IAModelAppleIntelligence.isAvailable(){
                            Section("Colores Chat IA"){
                                
                                ColorPicker("Color del texto del prompt", selection: $ColorChatIAFuente)
                                    .bold()
                                    .onChange(of: ColorChatIAFuente, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: newValue)
                                    }
                                
                                ColorPicker("Color del texto de las respuestas", selection: $ColorRespondIAFuente)
                                    .bold()
                                    .onChange(of: ColorRespondIAFuente, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: newValue)
                                    }

                                ColorPicker("Fondo de las burbujas de respuesta", selection: $ColorRespondIABurbuja)
                                    .bold()
                                    .onChange(of: ColorRespondIABurbuja, initial: true) { oldValue, newValue in
                                        settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_responseBubble, color: newValue)
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
                                    self.ColorChatIAFuente = AppCons.defaultColorIA_promptText
                                    self.ColorRespondIAFuente = AppCons.defaultColorIA_responseText
                                    self.ColorChatIAPrimario = AppCons.defaultColorIA_main_a
                                    self.ColorChatIASecundario = AppCons.defaultColorIA_main_b
                                    self.ColorRespondIABurbuja = AppCons.defaultColorIA_responseBubble
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textContent, color: self.ColorChatIAFuente)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_textRespond, color: self.ColorRespondIAFuente)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_a, color: self.ColorChatIAPrimario)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_main_b, color: self.ColorChatIASecundario)
                                    settingModel.saveColor(forkey: AppCons.UD_setting_colorIA_responseBubble, color: self.ColorRespondIABurbuja)
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
                                         Button(L10n.exact(opcion.getName)){
                                             toggleFiltro(opcion)
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
                                                
                                                Text(L10n.exact(criterio.getName))
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
                                        Text(L10n.format(
                                            "settings.ai_acceptance_status",
                                            fallback: "({0})",
                                            L10n.exact(self.DescargoDeIA ? "Aceptado" : "No aceptado")
                                        ))
                                            .foregroundStyle(self.DescargoDeIA ? .green : .red).bold().font(.subheadline)
                                        NavigationLink("Acceder a las Condiciones de Uso de la IA"){DescargoResponsabilidadIA(VentanaEnSetting: true)}.foregroundStyle(.orange)
                                    }
                                    Text("Nota: Para utilizar la IA generativa en el dispositivo, debe leer y aceptar primero las Condiciones de Uso de la IA.").font(Font.footnote.bold())
                                }
                                
                                //Permitir Ajustar el tratamiento de la IA
                                VStack(alignment: .leading){
                                        Text("Papel interpretado por la IA:")
                                    Toggle(isOn: self.$TratamientoDeIA) {
                                        Text(L10n.exact(self.TratamientoDeIA ? "Personal" : "Impersonal"))
                                            .foregroundStyle(self.TratamientoDeIA ? .green : settingsPrimaryTextColor)
                                    }
                                    Text(L10n.exact(
                                        self.TratamientoDeIA
                                            ? "La IA representa al Maestro, como si nos hablara en persona."
                                            : "La IA se muestra de manera impersonal y neutral."
                                    ))
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

                    }

                    Section("Ubicación") {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                locationPermission.requestWhenInUsePermission()
                            } label: {
                                Label(locationPermission.buttonTitle, systemImage: "location.fill")
                            }
                            .disabled(!locationPermission.canRequestPermission)

                            Text(locationPermission.statusDescription)
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
                            Text("Nota: Si se activa, el Diario permanece abierto una vez que se ha autentificado la primera vez. Esto evita tener que iniciar sesión en cada acceso al Diario. Al cerrarse la app, el acceso al Diario se bloquea.")
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
                        NavigationLink {
                            CardioCoherencePhraseSettingsView()
                        } label: {
                            Label("Frases durante la respiración", systemImage: "quote.bubble")
                        }

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

                    Section("Ritual Matutino") {
                        Toggle("Mostrar botón Mi día en Home", isOn: self.$showMyDayButtonInHome)
                    }

                    Section("Mascotas") {
                        Toggle("Mostrar mascotas en las vistas compatibles", isOn: $petsEnabled)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(PetSettings.availablePetAssetNames, id: \.self) { assetName in
                                    Button {
                                        selectedPetAssetName = assetName
                                    } label: {
                                        VStack(spacing: 4) {
                                            PetImage(assetName: assetName)
                                                .frame(
                                                    width: PetSettings.settingsCarouselPetSize,
                                                    height: PetSettings.settingsCarouselPetSize
                                                )
                                                .clipped()
                                            Text(PetSettings.displayName(for: assetName))
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        .frame(width: 64, height: 58)
                                        .background(
                                            selectedPetAssetName == assetName
                                                ? Color.accentColor.opacity(0.22)
                                                : Color.secondary.opacity(0.08),
                                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(PetSettings.displayName(for: assetName))
                                    .accessibilityAddTraits(selectedPetAssetName == assetName ? .isSelected : [])
                                }
                            }
                        }
                        .disabled(!petsEnabled)
                    }
                    .onAppear {
                        let availablePets = PetSettings.availablePetAssetNames
                        if !availablePets.contains(selectedPetAssetName) {
                            selectedPetAssetName = availablePets.first ?? PetSettings.defaultPetAssetName
                        }
                    }

                    Section("Centro Sanador") {
                        Toggle("Mostrar tarjeta destacada en Home", isOn: $showHealingCenterCardInHomeAlternativo)

                        Text("Aunque ocultes esta tarjeta, puedes añadir Centro Sanador a la cuadrícula desde «Editar cuadrícula» en Home.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Section("Vista Home Productividad") {
                        Text("Valores totales usados como referencia para completar los indicadores de progreso de Presencia y Metas en Home. El indicador de estrés se calcula automáticamente leyendo datos de Salud, utilizando HealthKit em modo lectura.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Stepper(
                            L10n.format(
                                "settings.productivity_presence_total",
                                fallback: "Presencia: {0}",
                                String(homeProductividadPresenciaTotal)
                            ),
                            value: $homeProductividadPresenciaTotal,
                            in: 5...100
                        )
                        Stepper(
                            L10n.format(
                                "settings.productivity_goals_total",
                                fallback: "Metas: {0}",
                                String(homeProductividadMetasTotal)
                            ),
                            value: $homeProductividadMetasTotal,
                            in: 1...100
                        )
                    }

                    Section("Revisión semanal") {
                        Picker("Día del resumen", selection: $weeklyReviewWeekday) {
                            ForEach(WeeklyReviewDay.allCases) { day in
                                Text(day.title).tag(day.rawValue)
                            }
                        }
                        .onChange(of: weeklyReviewWeekday) { _, newValue in
                            WeeklyReviewNotificationManager.update(
                                enabled: weeklyReviewNotificationsEnabled,
                                weekday: newValue
                            )
                        }

                        Toggle("Recordatorio semanal a las 6:00", isOn: $weeklyReviewNotificationsEnabled)
                            .onChange(of: weeklyReviewNotificationsEnabled) { _, newValue in
                                WeeklyReviewNotificationManager.update(
                                    enabled: newValue,
                                    weekday: weeklyReviewWeekday
                                )
                            }

                        Text(weeklyReviewAvailabilityDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Stepper(
                            weeklyReviewRetentionLabel,
                            value: $weeklyReviewRecordsToKeep,
                            in: WeeklyReviewRetentionPolicy.minimumRecordsToKeep...WeeklyReviewRetentionPolicy.maximumRecordsToKeep,
                            step: WeeklyReviewRetentionPolicy.recordStep
                        )
                        .onChange(of: weeklyReviewRecordsToKeep) { _, newValue in
                            weeklyReviewRecordsToKeep = WeeklyReviewRetentionPolicy.normalizedRecordsToKeep(newValue)
                        }

                        Button("Eliminar revisiones antiguas", role: .destructive) {
                            showWeeklyReviewRetentionConfirmation = true
                        }

                        Text(weeklyReviewCleanupDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .onAppear {
                        WeeklyReviewNotificationManager.update(
                            enabled: weeklyReviewNotificationsEnabled,
                            weekday: weeklyReviewWeekday
                        )
                    }

                    Section("Presencia") {
                        Toggle("Mostrar botón Presencia en Home", isOn: self.$showPresenceButtonInHome)

                        TextField("Frase breve", text: $presenciaCelebrationPhrase, axis: .vertical)
                            .lineLimit(2)
                            .onChange(of: presenciaCelebrationPhrase) { _, newValue in
                                if newValue.count > 80 {
                                    presenciaCelebrationPhrase = String(newValue.prefix(80))
                                }
                            }

                        Text("Se mostrará al registrar un evento de Presencia.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button("Usar frase por defecto") {
                            presenciaCelebrationPhrase = PresenciaSettings.defaultCelebrationPhrase
                        }
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
                                        self.alertMessage = L10n.format(
                                            "settings.master_password_value",
                                            fallback: "La clave es: {0}",
                                            clave
                                        ) //Almacena la clave
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
                    
                    Section("Migración iOS / Android") {
                        NavigationLink {
                            MigrationIOSAndroidView()
                        } label: {
                            Label("Exportar a Android / Importar desde Android", systemImage: "arrow.left.arrow.right.circle")
                        }

                        Text("Crea o lee archivos .ypgexp cifrados y compatibles con Android.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
                            Label("Características de la App", systemImage: "info.circle.text.page.fill")
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
            locationPermission.refreshStatus()
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
                TxtListView( typeOfContent: .conf, title: L10n.exact("Lecturas"))
            case 3:
                TxtListView( typeOfContent: .citas, title: L10n.exact("Citas"))
            case 4:
                TxtListView( typeOfContent: .preg, title: L10n.exact("Preguntas"))
            case 5:
                TxtListView( typeOfContent: .ayud, title: L10n.exact("Ayudas"))
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
                    cardioMusicImportErrorMessage = L10n.exact("No se pudo importar el archivo de música.")
                }
            case .failure:
                cardioMusicImportErrorMessage = L10n.exact("No se pudo abrir el selector de archivos.")
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
        .confirmationDialog(
            "¿Eliminar las revisiones semanales antiguas?",
            isPresented: $showWeeklyReviewRetentionConfirmation,
            titleVisibility: .visible
        ) {
            Button("Eliminar registros antiguos", role: .destructive) {
                pruneWeeklyReviewRecords()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text(weeklyReviewConfirmationDescription)
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

    private var weeklyReviewDayName: String {
        WeeklyReviewSchedule.selectedDay(from: weeklyReviewWeekday).title.lowercased()
    }

    private var weeklyReviewShortAvailabilityDescription: String {
        L10n.format(
            "settings.weekly_review_short_availability",
            fallback: "Disponible cada {0} a partir de las 6:00.",
            weeklyReviewDayName
        )
    }

    private var weeklyReviewAvailabilityDescription: String {
        L10n.format(
            "settings.weekly_review_availability",
            fallback: "La revisión estará disponible cada {0} a partir de las 6:00. Al activar el recordatorio, la app solicitará permiso de notificaciones si hace falta.",
            weeklyReviewDayName
        )
    }

    private var weeklyReviewRetentionLabel: String {
        L10n.format(
            "settings.weekly_review_retention_label",
            fallback: "Conservar {0} registros",
            String(weeklyReviewRecordsToKeep)
        )
    }

    private var weeklyReviewCleanupDescription: String {
        L10n.format(
            "settings.weekly_review_cleanup_description",
            fallback: "Al limpiar, se conservarán las últimas {0} revisiones semanales y se eliminarán los registros anteriores.",
            String(weeklyReviewRecordsToKeep)
        )
    }

    private var weeklyReviewConfirmationDescription: String {
        L10n.format(
            "settings.weekly_review_confirmation_description",
            fallback: "Se conservarán las últimas {0} revisiones. Las anteriores se eliminarán también de CloudKit al sincronizar.",
            String(weeklyReviewRecordsToKeep)
        )
    }

    private func pruneWeeklyReviewRecords() {
        do {
            let recordsToKeep = WeeklyReviewRetentionPolicy.normalizedRecordsToKeep(weeklyReviewRecordsToKeep)
            weeklyReviewRecordsToKeep = recordsToKeep
            let deletedCount = try WeeklyReviewRetentionPolicy.deleteOldRecords(context: context, keeping: recordsToKeep)
            if deletedCount == 0 {
                alertMessage = L10n.format(
                    "settings.weekly_review_prune_none",
                    fallback: "No había revisiones antiguas que eliminar. Se conservan las últimas {0}.",
                    String(recordsToKeep)
                )
            } else if deletedCount == 1 {
                alertMessage = L10n.format(
                    "settings.weekly_review_prune_one",
                    fallback: "Se eliminó una revisión semanal antigua. Se conservan las últimas {0}.",
                    String(recordsToKeep)
                )
            } else {
                alertMessage = L10n.format(
                    "settings.weekly_review_prune_other",
                    fallback: "Se eliminaron {0} revisiones semanales antiguas. Se conservan las últimas {1}.",
                    String(deletedCount),
                    String(recordsToKeep)
                )
            }
        } catch {
            alertMessage = error.localizedDescription
        }
        showAlert = true
    }
    
}

private struct CardioCoherencePhraseSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var phrases = CardioCoherenceConstants.SessionPhrases.load()
    @State private var showResetConfirmation = false

    var body: some View {
        Form {
            ForEach(
                Array(CardioCoherenceConstants.SessionPhrases.phaseTitles.enumerated()),
                id: \.offset
            ) { phaseIndex, phaseTitle in
                Section(phaseTitle) {
                    phraseField(index: phaseIndex * 2, label: "Frase 1")
                    phraseField(index: (phaseIndex * 2) + 1, label: "Frase 2")
                }
            }

            Section {
                Button("Restaurar frases predeterminadas", role: .destructive) {
                    showResetConfirmation = true
                }
            }
        }
        .navigationTitle("Frases de coherencia")
        .settingsInlineNavigationTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    CardioCoherenceConstants.SessionPhrases.save(phrases)
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            "¿Restaurar las ocho frases predeterminadas?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Restaurar", role: .destructive) {
                CardioCoherenceConstants.SessionPhrases.reset()
                phrases = CardioCoherenceConstants.SessionPhrases.defaults
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private func phraseField(index: Int, label: String) -> some View {
        TextField(L10n.exact(label), text: binding(for: index), axis: .vertical)
            .lineLimit(2...3)
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                phrases.indices.contains(index) ? phrases[index] : ""
            },
            set: { value in
                guard phrases.indices.contains(index) else { return }
                phrases[index] = String(
                    value.prefix(CardioCoherenceConstants.SessionPhrases.maximumLength)
                )
            }
        )
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { return self }
}

#if os(iOS)
@MainActor
final class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
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
            return L10n.exact("Solicitar permiso de ubicación")
        case .authorizedWhenInUse, .authorizedAlways:
            return L10n.exact("Permiso de ubicación concedido")
        case .denied, .restricted:
            return L10n.exact("Permiso de ubicación no disponible")
        @unknown default:
            return L10n.exact("Estado de ubicación no reconocido")
        }
    }

    var statusDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return L10n.exact("Permite guardar la dirección actual en Notas, Agenda y Diario cuando uses esta opción.")
        case .authorizedWhenInUse, .authorizedAlways:
            return L10n.exact("Notas, Agenda y Diario pueden guardar la ubicación actual cuando uses esta opción.")
        case .denied:
            return L10n.exact("El permiso fue denegado. Puedes activarlo desde Ajustes del sistema.")
        case .restricted:
            return L10n.exact("El acceso a la ubicación está restringido en este dispositivo.")
        @unknown default:
            return L10n.exact("No se pudo determinar el estado del permiso de ubicación.")
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

private extension View {
    @ViewBuilder
    func settingsInlineNavigationTitleDisplayMode() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

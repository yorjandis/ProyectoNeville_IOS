//
//  RespondView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 20/10/25.
//

import SwiftUI



@available(iOS 26.0, macOS 26.0, *)
struct RespondView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model : IAModelAppleIntelligence = IAModelAppleIntelligence()
    @State private var notasModel : NotasModel = NotasModel()
    @StateObject private var clipBoarModel : ClipboardObserver = ClipboardObserver() //Para observar cambios en el portapapales
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @State private var isloading : Bool = false //Indica que se esta procesando una solicitud
    
    
    @AppStorage(AppCons.UD_setting_fontContentSize)    var fontSizeContenido : Int = 24
    @AppStorage(AppCons.UD_setting_IA_AceptacionDescargo)    var DescargoDeIA : Bool = false // Si es true se permite utilizar la IA.

    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    
    //Parámetros
    let nameConference  : String? //Nombre de la conferencia / fichero txt
    let texto           : String //Texto a procesar por la IA
    @State var tipoSalida      : TiposSalida //Especifica el tipo de salida desea: Puntos Claves / Resumen General, etc
    @State var autorRespuesta : String = "nev"  //El autor que procesará la respuesta: Por defecto es "nev"
    @State private var autorOriginal : String = ""
    
    //Prepara el contenido para compartir:
    private var creatorContentToShare : String{
        
        switch tipoSalida {
        case .puntosClaves:
            return  self.model.puntosClaves.joined(separator: "\n")
        case .resumen:
            return self.model.resumenGeneral
        case .practicas:
            return  self.model.practicas.joined(separator: "\n")
        case .practicaConcreta:
            return self.model.practicaConcreta
        case .interpretar:
            return self.model.interpretacion
        }
    }

    
    //Colores de IA chat:
    @State var ColorChatIAPrimario: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_main_a
    ) ?? AppCons.defaultColorIA_main_a
    @State var ColorChatIASecundario: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_main_b
    ) ?? AppCons.defaultColorIA_main_b
    @State var ColorRespondIAFuente: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_textRespond
    ) ?? AppCons.defaultColorIA_responseText
    @State var ColorRespondIABurbuja: Color = SettingModel.loadColor(
        forkey: AppCons.UD_setting_colorIA_responseBubble
    ) ?? AppCons.defaultColorIA_responseBubble
    @AppStorage(AppCons.UD_setting_fontChatIASize)     var fontSizeChatIA : Int = 20
    
    
    //manejar el texto copiado:
    @State private var showSheetInterpretarTextoCopiadoIA : Bool = false
    @State private var showSheetChatIATextoCopiado : Bool   = false
    @State private var showSheetLienzoTextoCpiado  : Bool   = false
    @State private var showSheetTextoCopiadoAlPortapapelesParaInterpretar   : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaChatIA       : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaLienzo       : TextoCopiadoAlPortapapeles? = nil
    
    
    @State private var showSheetInfo : Bool = false
    @State private var generationTask: Task<Void, Never>?
    @State private var generationRequestID: UUID?
    @State private var hasStartedGeneration = false
    @State private var selectedProvider: AIChatProviderKind = .apple
    @State private var hasExplicitlySelectedAuthor = false
    @State private var hasOpenRouterAPIKey = false
    @State private var hasOpenRouterConsent = OpenRouterConfiguration
        .hasPrivacyConsent
    @State private var showOpenRouterSettings = false
    @State private var showOpenRouterConsent = false
    @State private var showAppearanceSettings = false

    private let credentialStore = OpenRouterCredentialStore.shared
    
    //Obtiene el nombre completo del autor
    private func getNameAutor(autorRaw: String) -> String{
        switch autorRaw {
        case "nev": return "Neville Goddard"
        case "jd": return "Dr. Joe Dispenza"
        case "bruceL": return "Dr. Bruce H. Lipton"
        case "gregg": return "Gregg Braden"
        default: return "Desconocido"
        }
    }
    
    //Obtiene el nombre del fichero de imagen del autor en Assets
    private func getImageAutor(autorRaw: String) -> String{
        switch autorRaw {
        case "nev": return "nev-min"
        case "jd": return "jd"
        case "bruceL": return "bruce"
        case "gregg": return "gregg"
        default: return "salud"
        }
    }
    
    
    var body: some View {
        ZStack{
            LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
            
            if (self.purchaseStatus || self.yorjPremium){
                
                if self.DescargoDeIA{
                    
                    VStack {
                        if !hasStartedGeneration {
                            initialConfigurationView()
                        } else {
                            resultConfigurationHeader()

                            if self.isloading {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 14) {
                                        VistaDeProcesamiento()

                                        if !model.streamingResponse.isEmpty {
                                            Label(
                                                "Respuesta en curso",
                                                systemImage: "text.cursor"
                                            )
                                            .font(.caption.bold())
                                            .foregroundStyle(.secondary)

                                            ContenidoView(
                                                respuestaIA: model.streamingResponse
                                            )
                                            .transition(.opacity)
                                        }
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .padding()
                                }
                            } else {
                                ScrollView {
                                    switch self.tipoSalida {
                                    case .puntosClaves:
                                        VistaPuntosClaves()
                                    case .resumen:
                                        VistaDeResumenGeneral()
                                    case .practicas:
                                        VistaPracticas()
                                    case .practicaConcreta:
                                        VistaPracticaConcreta()
                                    case .interpretar:
                                        VistaInterpretacion()
                                    }
                                }
                            }
                        }
                    }
                    
                    
                }else{
                    DescargoResponsabilidadIA(VentanaEnSetting: false)
                }
            }else{
                PurchaseView(mostrarLogo: true, mostrarBotonCerrarMacOS: true)
            }
            
            
        }
        .onAppear {
            reloadAppearanceColors()
            refreshOpenRouterState()
            if !IAModelAppleIntelligence.isAvailable(),
               hasOpenRouterAPIKey {
                selectedProvider = .openRouter
            }
        }
        .onDisappear {
            cancelGeneration()
        }
        .toolbar{
            if (!self.isloading && self.DescargoDeIA) {
                #if os(macOS)
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
                ToolbarSpacer(.fixed)
                #endif
                
                ToolbarSpacer(.fixed)
                
                ToolbarItem{
                    Button{
                        self.showSheetInfo = true
                    }label: {
                        Label("", systemImage: "info.circle")
                    }
                }

                ToolbarSpacer(.fixed)

                ToolbarItem {
                    Menu {
                        Button {
                            reloadAppearanceColors()
                            showAppearanceSettings = true
                        } label: {
                            Label(
                                "Ajustar visualización",
                                systemImage: "paintpalette"
                            )
                        }

                        Button {
                            restoreAppearanceDefaults()
                        } label: {
                            Label(
                                "Restaurar colores",
                                systemImage: "arrow.counterclockwise"
                            )
                        }
                    } label: {
                        Label(
                            "Visualización",
                            systemImage: "paintpalette"
                        )
                    }
                    .help("Ajustar la apariencia de esta vista")
                }
                
                ToolbarSpacer(.fixed)
                
                ToolbarItem{
                    if let _ = self.clipBoarModel.clipboardText{
                         TextoCopiadoView(clipBoardModel: self.clipBoarModel,
                                          nameTxt: nil,
                                          showAlert: self.$showAlert,
                                          alertMessage: self.$alertMessage,
                                          showSheetTextoCopiadoAlPortapapelesParaInterpretar: self.$showSheetTextoCopiadoAlPortapapelesParaInterpretar,
                                          showSheetTtextoCopiadoAlPortapapelesParaChatIA: self.$showSheetTtextoCopiadoAlPortapapelesParaChatIA,
                                          showSheetTtextoCopiadoAlPortapapelesParaLienzo: self.$showSheetTtextoCopiadoAlPortapapelesParaLienzo)
                    }
                }
                
                
                ToolbarSpacer(.fixed)
                
                
                //Share the text
                ToolbarItem {
                    ShareLink(item: self.creatorContentToShare){
                        Label("", systemImage: "square.and.arrow.up")
                    }
                     
                }
                
            }
            
        }
        .sheet(item: $showSheetTextoCopiadoAlPortapapelesParaInterpretar){ text in
                RespondView(nameConference: "", texto: text.texto, tipoSalida: .interpretar, autorRespuesta: "nev")
        }
        .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaChatIA){ text in
                ChatView(textoACargar: text.texto)
        }
        .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaLienzo){ text in
                LienzoMain(texto : text.texto, imagenPrimariaACargar: nil)
        }
        .sheet(isPresented: $showOpenRouterSettings) {
            OpenRouterSettingsView {
                refreshOpenRouterState()
            }
        }
        .sheet(isPresented: $showAppearanceSettings) {
            RespondAppearanceSettingsView(
                responseTextColor: $ColorRespondIAFuente,
                backgroundPrimary: $ColorChatIAPrimario,
                backgroundSecondary: $ColorChatIASecundario,
                responseBackground: $ColorRespondIABurbuja
            )
        }
        .sheet(
            isPresented: $showOpenRouterConsent,
            onDismiss: refreshOpenRouterState
        ) {
            OpenRouterPrivacyConsentView {
                hasOpenRouterConsent = true
            }
        }
        .sheet(isPresented: self.$showSheetInfo){
            ZStack{
                LinearGradient.FondoGrizAzulMate()
                    .ignoresSafeArea()
                VStack{
                    ScrollView{
                        Text(aiInformationText)
                        .foregroundStyle(.black)
                        .bold()
                        .font(.title2)
                    }
                   
                   
                }
                .padding()
            }
            
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("Chat"), message: Text(self.alertMessage))
        }
    }

    private var aiInformationText: String {
        let processing = selectedProvider == .apple
            ? "Apple Intelligence procesa la solicitud localmente en el dispositivo."
            : "OpenRouter procesa la solicitud online mediante el modelo gratuito seleccionado y la clave personal del usuario. El texto se envía a OpenRouter y al proveedor que ejecuta ese modelo."
        let authorContext = tipoSalida.requiresAuthor
            ? "La interpretación o aplicación práctica se enmarca en el campo de conocimiento del autor seleccionado."
            : "El resumen y los puntos clave se elaboran únicamente desde el contenido original, sin aplicar el marco de un autor."
        return """
        ☘️ Información sobre la IA utilizada:

        \(processing)

        \(authorContext)

        La respuesta puede contener errores. Revisa siempre el resultado antes de utilizarlo.

        Esta herramienta ofrece contenido educativo y de reflexión. No sustituye asesoramiento médico, psicológico, legal ni financiero.
        """
    }

    @ViewBuilder
    private func initialConfigurationView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label(tipoSalida.displayName, systemImage: "sparkles")
                    .font(.title2.bold())

                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Selecciona el modelo")
                        .font(.headline)
                    Picker("Modelo", selection: $selectedProvider) {
                        ForEach(AIChatProviderKind.allCases) { provider in
                            Label(
                                provider.shortDisplayName,
                                systemImage: provider.systemImage
                            )
                            .tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedProvider) { _, _ in
                        refreshOpenRouterState()
                    }

                    providerStatusView()
                }

                if tipoSalida.requiresAuthor {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("2. Selecciona el autor")
                            .font(.headline)
                        Text("La respuesta se generará dentro del campo de conocimiento y las enseñanzas del autor elegido.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 12
                        ) {
                            authorSelectionButton(
                                rawValue: "nev",
                                name: "Neville Goddard",
                                imageName: "nev-min"
                            )
                            authorSelectionButton(
                                rawValue: "jd",
                                name: "Joe Dispenza",
                                imageName: "jd"
                            )
                            authorSelectionButton(
                                rawValue: "bruceL",
                                name: "Bruce Lipton",
                                imageName: "bruce"
                            )
                            authorSelectionButton(
                                rawValue: "gregg",
                                name: "Gregg Braden",
                                imageName: "gregg"
                            )
                        }
                    }
                } else {
                    Text("Esta operación depende exclusivamente del contenido original y no utiliza el marco de ningún autor.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Button {
                    generarTexto(tipoSalida: tipoSalida)
                } label: {
                    Label(
                        "Generar \(tipoSalida.displayName.lowercased())",
                        systemImage: selectedProvider.systemImage
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!canStartConfiguredGeneration)
            }
            .padding()
        }
    }

    @ViewBuilder
    private func providerStatusView() -> some View {
        switch selectedProvider {
        case .apple:
            if IAModelAppleIntelligence.isAvailable() {
                Label(
                    "Procesamiento privado en el dispositivo",
                    systemImage: "checkmark.shield"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            } else {
                Label(
                    "Apple Intelligence no está disponible en este dispositivo.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        case .openRouter:
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    "Modelo gratuito: \(OpenRouterConfiguration.selectedModelIdentifier)"
                )
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

                OpenRouterFreeLimitNotice(
                    modelIdentifier: OpenRouterConfiguration
                        .selectedModelIdentifier
                )

                if !hasOpenRouterAPIKey {
                    Button {
                        showOpenRouterSettings = true
                    } label: {
                        Label(
                            "Añadir clave de OpenRouter",
                            systemImage: "key"
                        )
                    }
                } else if !hasOpenRouterConsent {
                    Button {
                        showOpenRouterConsent = true
                    } label: {
                        Label(
                            "Autorizar el envío del texto",
                            systemImage: "hand.raised"
                        )
                    }
                } else {
                    Label(
                        "Se enviará el texto al modelo gratuito seleccionado.",
                        systemImage: "network"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Button {
                    showOpenRouterSettings = true
                } label: {
                    Label(
                        "Configurar modelo gratuito",
                        systemImage: "gearshape"
                    )
                }
                .font(.footnote)
            }
        }
    }

    @ViewBuilder
    private func authorSelectionButton(
        rawValue: String,
        name: String,
        imageName: String
    ) -> some View {
        let isSelected = hasExplicitlySelectedAuthor
            && autorRespuesta == rawValue
        Button {
            autorRespuesta = rawValue
            hasExplicitlySelectedAuthor = true
        } label: {
            VStack(spacing: 8) {
                authorAvatar(imageName: imageName, size: 48)
                Text(name)
                    .font(.caption.bold())
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(isSelected ? .green : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(
                isSelected
                    ? Color.green.opacity(0.14)
                    : Color.white.opacity(0.12),
                in: RoundedRectangle(cornerRadius: 14)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func resultConfigurationHeader() -> some View {
        HStack(spacing: 12) {
            Menu {
                Button {
                    selectProviderAndRegenerate(.apple)
                } label: {
                    Label(
                        "Apple Intelligence",
                        systemImage: selectedProvider == .apple
                            ? "checkmark"
                            : "apple.intelligence"
                    )
                }
                Button {
                    selectProviderAndRegenerate(.openRouter)
                } label: {
                    Label(
                        "OpenRouter",
                        systemImage: selectedProvider == .openRouter
                            ? "checkmark"
                            : "sparkles"
                    )
                }
            } label: {
                Label(
                    selectedProvider.shortDisplayName,
                    systemImage: selectedProvider.systemImage
                )
            }
            .disabled(isloading)

            Spacer()

            if tipoSalida.requiresAuthor {
                Menu {
                    resultAuthorButton("Neville Goddard", rawValue: "nev")
                    resultAuthorButton("Joe Dispenza", rawValue: "jd")
                    resultAuthorButton("Bruce Lipton", rawValue: "bruceL")
                    resultAuthorButton("Gregg Braden", rawValue: "gregg")
                } label: {
                    HStack(spacing: 6) {
                        authorAvatar(
                            imageName: getImageAutor(
                                autorRaw: autorRespuesta
                            ),
                            size: 24
                        )
                        Text(
                            getNameAutor(autorRaw: autorRespuesta)
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: 170, alignment: .trailing)
                }
                .disabled(isloading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func authorAvatar(
        imageName: String,
        size: CGFloat
    ) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .contentShape(Circle())
            .clipped()
    }

    @ViewBuilder
    private func resultAuthorButton(
        _ name: String,
        rawValue: String
    ) -> some View {
        Button {
            hasExplicitlySelectedAuthor = true
            generarTexto(tipoSalida: tipoSalida, autor: rawValue)
        } label: {
            Label(
                name,
                systemImage: autorRespuesta == rawValue
                    ? "checkmark"
                    : "person"
            )
        }
    }

    private var canStartConfiguredGeneration: Bool {
        if tipoSalida.requiresAuthor && !hasExplicitlySelectedAuthor {
            return false
        }
        switch selectedProvider {
        case .apple:
            return IAModelAppleIntelligence.isAvailable()
        case .openRouter:
            return hasOpenRouterAPIKey && hasOpenRouterConsent
        }
    }

    private func selectProviderAndRegenerate(
        _ provider: AIChatProviderKind
    ) {
        selectedProvider = provider
        refreshOpenRouterState()
        guard providerReady(provider) else {
            hasStartedGeneration = false
            return
        }
        generarTexto(tipoSalida: tipoSalida)
    }

    private func providerReady(_ provider: AIChatProviderKind) -> Bool {
        switch provider {
        case .apple:
            return IAModelAppleIntelligence.isAvailable()
        case .openRouter:
            return hasOpenRouterAPIKey && hasOpenRouterConsent
        }
    }

    private func refreshOpenRouterState() {
        hasOpenRouterAPIKey = (
            try? credentialStore.readAPIKey()
        ) != nil
        hasOpenRouterConsent = OpenRouterConfiguration.hasPrivacyConsent
    }
    
    
//Vista que se muestra mientras se procesa la información
@ViewBuilder
    private func VistaDeProcesamiento() -> some View{
        VStack{
            VStack{
                
                 Image(systemName: "sparkles")
                             .padding()
                             .font(.system(size: 30))
                             .foregroundStyle(.black)
  

                switch self.tipoSalida {
                    
                case .puntosClaves:
                    VStack(alignment: .center){
                        Text("Generando Puntos Claves").bold()
                        //Text("Procesando: \(self.model.fragmentoActual) \\ \(self.model.noFragmentos)").bold()
                        LinearProgressBar(actual: self.model.fragmentoActual, total: self.model.noFragmentos)
                            .padding()
                    }
                    
                    
                case .resumen:
                    VStack(alignment: .center, spacing: 10){
                        Text("Creando Resumen").bold()
                        //Text("Procesando: \(self.model.fragmentoActual) \\ \(self.model.noFragmentos)").bold()
                        LinearProgressBar(actual: self.model.fragmentoActual, total: self.model.noFragmentos)
                            .padding()
                    }
                    
                    
                case .practicas:
                    VStack(alignment: .center, spacing: 10){
                        Text("Generando Consejos Prácticos").bold()
                        //Text("Procesando: \(self.model.fragmentoActual) \\ \(self.model.noFragmentos)").bold()
                        LinearProgressBar(actual: self.model.fragmentoActual, total: self.model.noFragmentos)
                            .padding()
                    }
                    
                    
                case .practicaConcreta:
                    Text("Generando Aplicación Práctica \nSegún las enseñanzas de: \n \(self.getNameAutor(autorRaw: self.autorRespuesta))")
                    
                case .interpretar:
                    Text("Interpretando Texto \nSegún las enseñanzas de: \n \(self.getNameAutor(autorRaw: self.autorRespuesta))")
                }
                
                //Mostrando indicador de progreso solo si el texto a procesar excede de 4000 caracteres
                if self.texto.count > 4000{
                    Text("Completado: \(self.model.fragmentoActual)/\(self.model.noFragmentos)")
                    //Barra de Progreso
                    ProgressView(value: Double(self.model.fragmentoActual),
                                 total: max(Double(self.model.noFragmentos), 1))
                    .progressViewStyle(.linear)
                    .tint(.black)
                    .frame(maxWidth: 300)
                }
                
                VStack{
                    Button("Cancelar"){
                        cancelGeneration()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .tint(.black).bold()
                }.padding()
                
                #if os(macOS)
                //Mostrando el texto en la interfaz: Solor función de intepretar que se supone que el texto sea corto
                if self.tipoSalida == .interpretar{
                    VStack(alignment: .center){
                        Text(self.texto)
                            .foregroundStyle(.black.adaptiveTextColor())
                            .font(.title3)
                    }
                    .padding(.vertical, 20)
                }
                
                
                
                #endif
            }
            
        }
        .font(.system(size: 24))
    }
    
    
    
//Para mostrar un listado de los puntos claves de una conferencia (solo conferencia)
@ViewBuilder
    private func VistaPuntosClaves() -> some View{
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach (self.model.puntosClaves, id: \.self){ idea in
                ContenidoView(respuestaIA: idea)
            }
            
            buttomOpcionesViewContent()
            
        }
        .padding()
    }
    
    
//Para mostrar un resumen General de la conferencia (solo conferencia)
@ViewBuilder
    private func VistaDeResumenGeneral() -> some View{
        VStack{
            ContenidoView(respuestaIA: self.model.resumenGeneral)
            buttomOpcionesViewContent()
        }
        .padding()

    }
    

//Para mostrar un listado de acciones prácticas (solo Conferencia)
@ViewBuilder
    private func VistaPracticas() -> some View{
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach (self.model.practicas, id: \.self){ idea in
                ContenidoView(respuestaIA: idea)

            }
            
            buttomOpcionesViewContent()
        }
        .padding()
    }


// Mostrar una aplicación práctica de una frase, cita, nota, reflexion (no conferencia)
@ViewBuilder
    private func VistaPracticaConcreta() -> some View {
        if !model.practicaConcreta.isEmpty{
            VStack{
                
                ContenidoView(respuestaIA: self.model.practicaConcreta)
                
                buttomOpcionesViewContent()
                
                Spacer()
                
                VStack{
                    TextoReferenciaView()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
           
        }else{
            EmptyView()
        }
    }
   
    
//Interpretar una frase, cita, nota, reflexión (No conferencia)
@ViewBuilder
    private func VistaInterpretacion() -> some View {
        
            VStack{
                ContenidoView(respuestaIA: self.model.interpretacion)
                
                buttomOpcionesViewContent()
                
                Spacer()
                
                VStack(alignment: .leading){
                    
                    TextoReferenciaView()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
            }
            .padding()

        
    }

    
    
    
//-----  Componentes visuales del cuadro de Contenido que se presenta al usuario
    
//Vista de contenido
    @ViewBuilder
    private func ContenidoView(respuestaIA: String) -> some View {
        #if os(macOS)
        Text(respuestaIA)
            .font(.system(size: CGFloat(self.fontSizeChatIA)))
            .foregroundStyle(self.ColorRespondIAFuente)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(self.ColorRespondIABurbuja)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .clipped()

        #else
        SelectableText(
            text: respuestaIA,
            fontSize: CGFloat(self.fontSizeChatIA),
            fontColor: self.ColorRespondIAFuente,
            alignment: .left
        )
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.ColorRespondIABurbuja)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .clipped()

        #endif
    }

    private func reloadAppearanceColors() {
        ColorRespondIAFuente = SettingModel.loadColor(
            forkey: AppCons.UD_setting_colorIA_textRespond
        ) ?? AppCons.defaultColorIA_responseText
        ColorChatIAPrimario = SettingModel.loadColor(
            forkey: AppCons.UD_setting_colorIA_main_a
        ) ?? AppCons.defaultColorIA_main_a
        ColorChatIASecundario = SettingModel.loadColor(
            forkey: AppCons.UD_setting_colorIA_main_b
        ) ?? AppCons.defaultColorIA_main_b
        ColorRespondIABurbuja = SettingModel.loadColor(
            forkey: AppCons.UD_setting_colorIA_responseBubble
        ) ?? AppCons.defaultColorIA_responseBubble
    }

    private func restoreAppearanceDefaults() {
        let settings = SettingModel()
        ColorRespondIAFuente = AppCons.defaultColorIA_responseText
        ColorChatIAPrimario = AppCons.defaultColorIA_main_a
        ColorChatIASecundario = AppCons.defaultColorIA_main_b
        ColorRespondIABurbuja = AppCons.defaultColorIA_responseBubble
        settings.saveColor(
            forkey: AppCons.UD_setting_colorIA_textRespond,
            color: ColorRespondIAFuente
        )
        settings.saveColor(
            forkey: AppCons.UD_setting_colorIA_main_a,
            color: ColorChatIAPrimario
        )
        settings.saveColor(
            forkey: AppCons.UD_setting_colorIA_main_b,
            color: ColorChatIASecundario
        )
        settings.saveColor(
            forkey: AppCons.UD_setting_colorIA_responseBubble,
            color: ColorRespondIABurbuja
        )
    }
    
    
//Vista de botones de opciones que aparecen debajo de cada respuesta de la IA
    @ViewBuilder
    private func buttomOpcionesViewContent() -> some View {
        HStack(spacing: 25){
            
            Menu{
                //Copiar la respuesta a notas
                Button{
                    let conferenceName = self.nameConference?
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let reference: String
                    if let conferenceName, !conferenceName.isEmpty {
                        reference = "\(conferenceName) (Conferencia)"
                    } else {
                        reference = self.texto
                    }
                    if self.notasModel.addNote(
                        nota: """
                        \(self.creatorContentToShare)

                        ----Texto de Referencia----
                        \(reference)
                        """,
                        title: "Nota de IA"
                    ){
                        self.alertMessage = "Se ha guardado la respuesta en Notas"
                        self.showAlert = true
                    }else{
                        self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                        self.showAlert = true
                    }
                    
                }label:{
                    Label("Guardar en Notas", systemImage: "list.clipboard")
                }
                .foregroundStyle(.black)
                .buttonStyle(.bordered)
                
                if tipoSalida.requiresAuthor {
                    Menu {
                        resultAuthorButton(
                            "Neville Goddard",
                            rawValue: "nev"
                        )
                        resultAuthorButton(
                            "Joe Dispenza",
                            rawValue: "jd"
                        )
                        resultAuthorButton(
                            "Bruce Lipton",
                            rawValue: "bruceL"
                        )
                        resultAuthorButton(
                            "Gregg Braden",
                            rawValue: "gregg"
                        )
                    } label: {
                        Label("Cambiar Autor...", systemImage: "person")
                    }
                    .foregroundStyle(.black)
                    .buttonStyle(.bordered)
                }
                
                //Regenerar Respuesta
                Button{
                    generarTexto(tipoSalida: tipoSalida, autor: self.autorRespuesta) //Función que regenera el contenido
                }label: {
                    Label("Regenerar Respuesta", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 24))
                }
                .tint(.black)
                
                Menu{
                    Button("Interpretar"){
                        selectOperation(.interpretar)
                    }
                    Button("Práctica Concreta"){
                        selectOperation(.practicaConcreta)
                    }
                    Button("Listado de prácticas"){
                        selectOperation(.practicas)
                    }
                    Button("Puntos Claves"){
                        selectOperation(.puntosClaves)
                    }
                    Button("Resumen"){
                        selectOperation(.resumen)
                    }
                    
                }label:{
                    Label("Cambiar Operación...", systemImage: "swirl.circle.righthalf.filled.inverse")
                }
                .foregroundStyle(.black)
                .buttonStyle(.bordered)
                
            }label:{
                Text("Opciones...")
            }
            .buttonStyle(.bordered)
            
            
            
            
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
//Vista del texto de referencia(Solo para Frases, reflexiones, citas, etc. NO conferencias):
    @ViewBuilder
    private func TextoReferenciaView() -> some View{
        if self.isloading{
            Text(self.texto)
                .padding()
        }else{
            VStack(alignment: .leading){
                SelectableText(text : "\(self.texto) (\(self.getNameAutor(autorRaw: self.autorOriginal)))" , fontSize: CGFloat(20), fonColor: UIColor(Color.black.opacity(0.7)), alignment: .left )
            }
            .padding()
        }
        
    }

//Barra de progreso
    
    struct LinearProgressBar: View {
        
        let actual: Int
        let total: Int
        
        private var progress: CGFloat {
            guard total > 0 else { return 0 }
            return CGFloat(actual) / CGFloat(total)
        }
        
        var body: some View {
            GeometryReader { geo in
                
                ZStack(alignment: .leading) {
                    
                    // Fondo
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                    
                    // Progreso
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: geo.size.width * progress)
                }
                .cornerRadius(4)
            }
            .frame(height: 10)
        }
    }
    
    
//---- FIN
    
    
    

    // Cancela la solicitud anterior antes de iniciar una nueva.
    private func generarTexto(tipoSalida: TiposSalida, autor: String? = nil) {
        if let autor {
            autorRespuesta = autor
            hasExplicitlySelectedAuthor = true
        }
        guard !tipoSalida.requiresAuthor
                || hasExplicitlySelectedAuthor else {
            hasStartedGeneration = false
            return
        }
        guard providerReady(selectedProvider) else {
            hasStartedGeneration = false
            return
        }
        generationTask?.cancel()
        hasStartedGeneration = true
        autorOriginal = autorRespuesta

        let requestID = UUID()
        generationRequestID = requestID
        withAnimation {
            isloading = true
        }

        generationTask = Task { @MainActor in
            do {
                try await performGeneration(tipoSalida: tipoSalida)
                try Task.checkCancellation()
                guard generationRequestID == requestID else { return }
                withAnimation {
                    isloading = false
                }
            } catch is CancellationError {
                guard generationRequestID == requestID else { return }
                withAnimation {
                    isloading = false
                }
            } catch {
                guard generationRequestID == requestID else { return }
                alertMessage = error.localizedDescription
                showAlert = true
                withAnimation {
                    isloading = false
                }
            }

            if generationRequestID == requestID {
                generationTask = nil
                generationRequestID = nil
            }
        }
    }

    private func performGeneration(tipoSalida: TiposSalida) async throws {
        let input = switch tipoSalida {
        case .puntosClaves, .practicas, .resumen:
            sourceTextForLongOperation()
        case .practicaConcreta, .interpretar:
            texto
        }
        try await model.executeRequest(
            tipoSalida: tipoSalida,
            texto: input,
            autor: autorRespuesta,
            provider: selectedProvider,
            modelIdentifier: OpenRouterConfiguration.selectedModelIdentifier
        )
    }

    private func selectOperation(_ operation: TiposSalida) {
        cancelGeneration()
        tipoSalida = operation
        hasStartedGeneration = false
        if operation.requiresAuthor {
            hasExplicitlySelectedAuthor = false
        }
    }

    private func sourceTextForLongOperation() -> String {
        guard let nameConference else { return texto }
        let cleanName = nameConference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return texto }
        let fileName = "conf_\(cleanName.lowercased())"
        let fileContent = UtilFuncs.FileRead(fileName)
        return fileContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? texto
            : fileContent
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        generationRequestID = nil
        withAnimation {
            isloading = false
        }
    }
    
    
    
    // Función auxiliar: Convierte un tipo Color  a formato hexadecimal, para la configuración del CSS del componente RichText
    func hexString(for color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        // Convertir a hexadecimal
        return String(format: "#%02lX%02lX%02lX", lroundf(Float(red * 255)), lroundf(Float(green * 255)), lroundf(Float(blue * 255)))
    }
    
    
}//fin del struct


@available(iOS 26.0, macOS 26.0, *)
private struct RespondAppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingModel = SettingModel()

    @Binding var responseTextColor: Color
    @Binding var backgroundPrimary: Color
    @Binding var backgroundSecondary: Color
    @Binding var responseBackground: Color

    var body: some View {
        NavigationStack {
            Form {
                Section("Respuesta") {
                    ColorPicker(
                        "Color de la fuente",
                        selection: $responseTextColor
                    )
                    ColorPicker(
                        "Fondo del cuadro",
                        selection: $responseBackground
                    )
                }

                Section("Fondo de la vista") {
                    ColorPicker(
                        "Color superior",
                        selection: $backgroundPrimary
                    )
                    ColorPicker(
                        "Color inferior",
                        selection: $backgroundSecondary
                    )
                    Text("Los dos colores forman el degradado del fondo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Vista previa") {
                    Text("Esta es una respuesta de ejemplo.")
                        .font(.body)
                        .foregroundStyle(responseTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            responseBackground,
                            in: RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                        )
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    backgroundPrimary,
                                    backgroundSecondary
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                }

                Section {
                    Button {
                        restoreDefaults()
                    } label: {
                        Label(
                            "Restaurar colores predeterminados",
                            systemImage: "arrow.counterclockwise"
                        )
                    }
                }
            }
            .navigationTitle("Visualización de respuestas")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: responseTextColor) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_textRespond,
                color: color
            )
        }
        .onChange(of: backgroundPrimary) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_main_a,
                color: color
            )
        }
        .onChange(of: backgroundSecondary) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_main_b,
                color: color
            )
        }
        .onChange(of: responseBackground) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_responseBubble,
                color: color
            )
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 560)
        #endif
    }

    private func restoreDefaults() {
        responseTextColor = AppCons.defaultColorIA_responseText
        backgroundPrimary = AppCons.defaultColorIA_main_a
        backgroundSecondary = AppCons.defaultColorIA_main_b
        responseBackground = AppCons.defaultColorIA_responseBubble
    }
}

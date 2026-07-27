//
//  DialogoView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/10/25.
//
//Ventana de chat de IA, recibir concejos y sugerencias relacionadas con las enseñanzas de neville 

import SwiftUI
import UniformTypeIdentifiers

private enum ResponsePersistenceAction {
    case notes(ChatMessage)
    case deviceStorage(ChatMessage)

    var title: String {
        switch self {
        case .notes:
            "Guardar en Notas"
        case .deviceStorage:
            "Guardar en el dispositivo"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .notes:
            "Guardar respuesta"
        case .deviceStorage:
            "Generar PDF"
        }
    }

    var explanation: String {
        switch self {
        case .notes:
            "Se creará una Nota nueva con el contenido de esta respuesta."
        case .deviceStorage:
            "Se generará un archivo PDF con el prompt y la respuesta. Después podrás elegir dónde guardarlo."
        }
    }
}




@available(iOS 26.0, macOS 26.0, *)
struct ChatView: View {
    @StateObject private var model: ChatViewModel
    
    @State private var  notasModel : NotasModel = NotasModel()
    
    @StateObject private var clipBoarModel : ClipboardObserver = ClipboardObserver() //Para observar cambios en el portapapales
    //@StateObject private var purchaseModel : PurchaseManager = .shared //Para las funciones Premium
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)  var fontSizeChatIA : Int = 20
    
    @AppStorage(AppCons.UD_setting_IA_AceptacionDescargo)    var DescargoDeIA : Bool = false // True permite acceso al chet IA,false prohíbe el acceso al chat de IA
    
    @State private var lastID : UUID? = nil //Para poder desplazar la lista de mensajes en el chat hasta el último siempre
    
    
    let textoACargar : String?  //Permite cargar una frase o nota  y usarla en el chatIA para entablar una conversación.
    
    
    
    
    @FocusState private var focus
    
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "ChatIA.pdf"
    @State private var pendingResponsePersistenceAction: ResponsePersistenceAction?
    @State private var showConversationHistory = false
    @State private var showOpenRouterSettings = false
    @State private var showChatAppearanceSettings = false
    @State private var showOpenRouterConsent = false
    @State private var showProviderSwitchConfirmation = false
    @State private var pendingProvider: AIChatProviderKind?
    @State private var activateOpenRouterAfterConsent = false
    
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
    
    //manejar el texto copiado:
    @State private var showSheetInterpretarTextoCopiadoIA : Bool = false
    @State private var showSheetChatIATextoCopiado : Bool   = false
    @State private var showSheetLienzoTextoCpiado  : Bool   = false
    @State private var showSheetTextoCopiadoAlPortapapelesParaInterpretar   : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaChatIA       : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaLienzo       : TextoCopiadoAlPortapapeles? = nil
    
    init(textoACargar: String?) {
        self.textoACargar = textoACargar
        _model = StateObject(wrappedValue: ChatViewModel())
    }

    var body: some View {
        
        if (self.purchaseStatus || self.yorjPremium){
            if self.DescargoDeIA == false {
                ZStack{
                    LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    DescargoResponsabilidadIA(VentanaEnSetting: false)
                }
                
            }else{
                
                ContentMain()
            }
        }else{
            PurchaseView(mostrarLogo: true, mostrarBotonCerrarMacOS: true)
        }
    }
    
    
    @ViewBuilder
    private func ContentMain() -> some View {
        ZStack{
            
            LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            
                VStack {
                    HStack {
                        Label(
                            model.activeProviderDisplayName,
                            systemImage: model.activeProvider.systemImage
                        )
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.28), in: Capsule())
                        .accessibilityLabel(
                            "Modelo activo: \(model.activeProviderDisplayName)"
                        )
                        Spacer()
                    }
                    .padding(.horizontal)

                    ScrollViewReader { scrollProxy in
                        if !model.messages.isEmpty {
                            ScrollView {
                                LazyVStack {
                                    
                                        ForEach(model.messages) { msg in
                                            HStack {
                                                if msg.isUser {
                                                    Spacer()
                                                    
                                                    VStack(alignment: .trailing) {
                                                        SelectableText(text : msg.text, fontSize: CGFloat(self.fontSizeChatIA),fonColor: UIColor(self.ColorChatIAFuente) , alignment: .left)
                                                            .padding()
                                                            .background(Color.black.opacity(0.7))
                                                            .cornerRadius(12)
                                                            .contextMenu {
                                                                Button {
                                                                    model.inputText = msg.text
                                                                    focus = true
                                                                } label: {
                                                                    Label(
                                                                        "Editar y volver a enviar",
                                                                        systemImage: "pencil"
                                                                    )
                                                                }
                                                            }
                                                            .frame(
                                                                width: {
                                                                    #if os(iOS)
                                                                    UIScreen.main.bounds.width * 0.8
                                                                    #elseif os(macOS)
                                                                    //Ajusta el ancho de la burbuja de chat a un valor predefinido: en función del ancho disponible o un valor fijo(700)
                                                                    if let screenWidth = NSScreen.main?.frame.width {
                                                                                return screenWidth * 0.3
                                                                            } else {
                                                                                return 700 // si no hay pantalla, usar 700 directamente
                                                                            }
                                                                    #endif
                                                                }(),
                                                                alignment: .trailing
                                                            )
                                                            .id(msg.id)
                                                    }
                                                    
                                                } else {
                                                    VStack{
                                                        
                                                        SelectableText(text : msg.text, fontSize: CGFloat(self.fontSizeChatIA),fonColor: UIColor(self.ColorRespondIAFuente) , alignment : .left)
                                                            .padding(.horizontal, 10)
                                                            .background(self.ColorRespondIABurbuja)
                                                            .cornerRadius(12)
                                                        
                                                        MenuOpcionesRespuesta(message: msg)
                                                            .padding(.vertical, 0)
                                                            .id(msg.id) //Para porpósitos de scrooll

                                                        HStack(spacing: 4) {
                                                            Image(systemName: msg.provider.systemImage)
                                                            Text(msg.provider.shortDisplayName)
                                                            if let modelIdentifier = msg.modelIdentifier {
                                                                Text("· \(modelIdentifier)")
                                                            }
                                                        }
                                                        .font(.caption2)
                                                        .foregroundStyle(
                                                            self.ColorRespondIAFuente.opacity(0.72)
                                                        )
                                                    }
                                                    
                                                    Spacer()
                                                }
                                            }
                                            .transition(.opacity)
                                            .font(.system(size: CGFloat(fontSizeChatIA)))
                                            .padding(.horizontal)
                                            .padding(.vertical, 4)
                                        }
                                    
                                    
                                        
                                    
                                }
                                .animation(.easeInOut(duration: 0.20), value: model.messages)
                                
                                
                                
                            }
                            .onChange(of: model.messages.count) {old, new in
                                //Permite correr el scroll para que se muestre la última conversación.
                                if let lastMsg = model.messages.last {
                                    withAnimation {
                                        if lastMsg.isUser {
                                            //Si el último mensaje es del usurio, se hace scroll para ver ver su contenido
                                            scrollProxy.scrollTo(lastMsg.id, anchor: .top)
                                        }else{
                                            //Si el último mensaje es del boot se hace scrool para ver desde el mensaje del usuario
                                            if model.messages.count > 1 {
                                                scrollProxy.scrollTo(model.messages[model.messages.count-2].id, anchor: .top)
                                            }
                                                
                                        }
                                    }
                                }
                            }
                        }
                        else{
                            ScrollView {
                                if let availabilityMessage = model.activeProviderAvailabilityMessage {
                                    ContentUnavailableView(
                                        "\(model.activeProvider.displayName) no disponible",
                                        systemImage: model.activeProvider.systemImage,
                                        description: Text(availabilityMessage)
                                    )
                                    .padding()
                                    Button(
                                        model.activeProvider == .apple
                                            ? "Comprobar de nuevo"
                                            : "Configurar OpenRouter"
                                    ) {
                                        if model.activeProvider == .apple {
                                            model.refreshAvailability()
                                        } else {
                                            showOpenRouterSettings = true
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    AdjustableGridView_neville(
                                        autor: self.model.activeAuthor,
                                        rows: 11,
                                        model: self.model
                                    )
                                }
                            }
                        }
                        
                    }
                    
                    Promt()
                        .padding(.horizontal, 5)
                        .padding(.top, model.messages.isEmpty ? 15 : 0)
                    
                }
                .onTapGesture {
                    self.focus = false
                }
            
            
            
        }
        #if os(iOS)
        .navigationTitle("Pregunta a \(self.model.activeAuthor.getNombre)")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if self.DescargoDeIA {
                // El selector de proveedor permanece visible para que el modelo
                // activo siempre sea reconocible y fácil de cambiar.
                ToolbarItem {
                    Menu {
                        Button {
                            requestProvider(.apple)
                        } label: {
                            Label(
                                "Apple Intelligence",
                                systemImage: model.activeProvider == .apple
                                    ? "checkmark"
                                    : "apple.intelligence"
                            )
                        }

                        Button {
                            requestProvider(.openRouter)
                        } label: {
                            Label(
                                "OpenRouter · Modelos gratuitos",
                                systemImage: model.activeProvider == .openRouter
                                    ? "checkmark"
                                    : "sparkles"
                            )
                        }
                    } label: {
                        Label(
                            model.activeProvider.shortDisplayName,
                            systemImage: model.activeProvider.systemImage
                        )
                    }
                    .disabled(model.isResponding)
                    .help("Seleccionar modelo de IA")
                }

                ToolbarSpacer(.fixed)

                // Las acciones secundarias se agrupan para mantener compacta
                // la barra superior.
                ToolbarItem {
                    Menu {
                        Menu {
                            authorMenuButton(.neville)
                            authorMenuButton(.JoeDispenza)
                            authorMenuButton(.bruce)
                            authorMenuButton(.gregg)
                        } label: {
                            Label(
                                "Cambiar autor · \(model.activeAuthor.getNombre)",
                                systemImage: "person.crop.circle"
                            )
                        }

                        Button {
                            self.showConversationHistory = true
                        } label: {
                            Label(
                                "Historial de conversaciones",
                                systemImage: "clock.arrow.circlepath"
                            )
                        }

                        Button {
                            reloadChatAppearanceColors()
                            self.showChatAppearanceSettings = true
                        } label: {
                            Label(
                                "Apariencia del chat",
                                systemImage: "paintpalette"
                            )
                        }

                        if self.clipBoarModel.clipboardText != nil {
                            TextoCopiadoView(
                                clipBoardModel: self.clipBoarModel,
                                nameTxt: nil,
                                showAlert: self.$showAlert,
                                alertMessage: self.$alertMessage,
                                showSheetTextoCopiadoAlPortapapelesParaInterpretar: self.$showSheetTextoCopiadoAlPortapapelesParaInterpretar,
                                showSheetTtextoCopiadoAlPortapapelesParaChatIA: self.$showSheetTtextoCopiadoAlPortapapelesParaChatIA,
                                showSheetTtextoCopiadoAlPortapapelesParaLienzo: self.$showSheetTtextoCopiadoAlPortapapelesParaLienzo
                            )
                        }

                        Divider()

                        Button {
                            showOpenRouterSettings = true
                        } label: {
                            Label("Configurar OpenRouter", systemImage: "key")
                        }
                    } label: {
                        Label("Más opciones", systemImage: "ellipsis.circle")
                    }
                    .help("Opciones de Chat IA")
                }

                ToolbarSpacer(.fixed)

                // Crear conversación permanece como acción directa.
                ToolbarItem {
                    Button {
                        Task {
                            await self.model.createNewConversation()
                        }
                    } label: {
                        Label("Nueva conversación", systemImage: "square.and.pencil")
                    }
                    .help("Nueva conversación")
                }
            }
        }
        .task {
            await model.loadInitialConversation(prefill: textoACargar)
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
        .sheet(isPresented: $showConversationHistory) {
            ConversationHistoryView(
                model: model,
                notasModel: notasModel
            )
        }
        .sheet(isPresented: $showChatAppearanceSettings) {
            ChatAppearanceSettingsView(
                promptTextColor: $ColorChatIAFuente,
                responseTextColor: $ColorRespondIAFuente,
                chatBackgroundPrimary: $ColorChatIAPrimario,
                chatBackgroundSecondary: $ColorChatIASecundario,
                responseBubbleBackground: $ColorRespondIABurbuja
            )
        }
        .sheet(isPresented: $showOpenRouterSettings) {
            OpenRouterSettingsView {
                model.refreshOpenRouterCredentialState()
            }
        }
        .sheet(
            isPresented: $showOpenRouterConsent,
            onDismiss: {
                let shouldActivate = activateOpenRouterAfterConsent
                    && OpenRouterConfiguration.hasPrivacyConsent
                activateOpenRouterAfterConsent = false
                if shouldActivate {
                    requestProvider(.openRouter)
                }
            }
        ) {
            OpenRouterPrivacyConsentView {}
        }
        .confirmationDialog(
            "Cambiar a \(pendingProvider?.displayName ?? "otro modelo")",
            isPresented: $showProviderSwitchConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continuar en una copia de esta conversación") {
                guard let pendingProvider else { return }
                self.pendingProvider = nil
                Task {
                    await model.activateProvider(
                        pendingProvider,
                        preservingContext: true
                    )
                }
            }
            Button("Empezar una conversación nueva") {
                guard let pendingProvider else { return }
                self.pendingProvider = nil
                Task {
                    await model.activateProvider(
                        pendingProvider,
                        preservingContext: false
                    )
                }
            }
            Button("Cancelar", role: .cancel) {
                pendingProvider = nil
            }
        } message: {
            Text("Para conservar el origen y la privacidad del historial, el modelo no se cambia silenciosamente dentro de la conversación actual.")
        }
        .confirmationDialog(
            pendingResponsePersistenceAction?.title ?? "Confirmar acción",
            isPresented: Binding(
                get: { pendingResponsePersistenceAction != nil },
                set: {
                    if !$0 {
                        pendingResponsePersistenceAction = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingResponsePersistenceAction {
                Button(action.confirmationTitle) {
                    pendingResponsePersistenceAction = nil
                    performResponsePersistenceAction(action)
                }
            }
            Button("Cancelar", role: .cancel) {
                pendingResponsePersistenceAction = nil
            }
        } message: {
            Text(pendingResponsePersistenceAction?.explanation ?? "")
        }
        .onChange(of: model.userFacingError) { _, newValue in
            guard let newValue else { return }
            alertMessage = newValue
            showAlert = true
            model.userFacingError = nil
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("Chat IA"), message: Text(self.alertMessage))
        }
        .fileExporter(
            isPresented: $showPDFExporter,
            document: exportedPDFDocument,
            contentType: .pdf,
            defaultFilename: exportedPDFFileName
        ) { _ in }
    }

    @ViewBuilder
    private func authorMenuButton(_ author: Autores) -> some View {
        Button {
            Task {
                await model.createNewConversation(author: author)
            }
        } label: {
            let title: String = switch author {
            case .neville:
                "Neville Goddard"
            case .JoeDispenza:
                "Joe Dispenza"
            case .bruce:
                "Dr. Bruce Lipton"
            case .gregg:
                "Gregg Braden"
            }
            Label(title, image: author.imageName)
        }
    }

    private func reloadChatAppearanceColors() {
        ColorChatIAFuente = SettingModel.loadColor(
            forkey: AppCons.UD_setting_colorIA_textContent
        ) ?? AppCons.defaultColorIA_promptText
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

    private func requestProvider(_ provider: AIChatProviderKind) {
        guard provider != model.activeProvider else { return }
        if provider == .openRouter {
            guard model.hasOpenRouterAPIKey else {
                showOpenRouterSettings = true
                return
            }
            guard OpenRouterConfiguration.hasPrivacyConsent else {
                activateOpenRouterAfterConsent = true
                showOpenRouterConsent = true
                return
            }
        }

        if model.messages.isEmpty {
            Task {
                await model.activateProvider(
                    provider,
                    preservingContext: false
                )
            }
        } else {
            pendingProvider = provider
            showProviderSwitchConfirmation = true
        }
    }
    
    
    //Construye el Promt
    @ViewBuilder
    private func Promt() -> some View {
        
        VStack{
            HStack{
                
                if model.isResponding {
                    Spacer()
                    
                    ProgressView()
                        .foregroundStyle(.black)
                        .padding(.bottom, 10)
                    Button("Detener") {
                        model.cancelResponse()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    Spacer()
                }else{
                    TextField("Escribe algo…", text: $model.inputText, axis: .vertical)
                        .font(.system(size: 20))
                        .foregroundStyle(self.ColorChatIAFuente)
                        .disabled(model.isResponding)
                        .padding(.vertical, 8)
                        .padding(.leading, 5)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black.opacity(0.8)))
                        .focused(self.$focus)
                        .onSubmit {
                            model.submitMessage()
                            self.focus = false
                        }
                    
                    Button{
                        model.submitMessage()
                        self.focus = false
                    }label:{
                        Text("Enviar").bold()
                        
                    }
                    .tint(.orange)
                    .foregroundStyle(.black)
                    .buttonStyle(.bordered)
                    .disabled(model.inputText.trimmingCharacters(in: .whitespaces).isEmpty || model.isResponding)
                }
                
                
                
                
            }
        }
        
    }
    

    //Construye el menú de opciones de cada chat
    @ViewBuilder
    private func MenuOpcionesRespuesta(message: ChatMessage) -> some View {
        if message.status != .streaming {
            HStack(spacing: 20){
                ShareLink("", item: message.text)
                    .padding(.leading, 10)
                    .id(lastID)
                Button {
                    model.retryResponse(for: message.id)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(message.status == .completed ? "Regenerar respuesta" : "Reintentar")
                Button {
                    requestResponsePersistenceAction(.notes(message))
                } label: {
                    Image(systemName: "text.page")
                }
                .accessibilityLabel("Guardar en Notas")
                .help("Guardar en Notas")

                Button {
                    requestResponsePersistenceAction(.deviceStorage(message))
                } label: {
                    Image(systemName: "doc.richtext")
                }
                .accessibilityLabel("Guardar en el dispositivo")
                .help("Guardar en el dispositivo como PDF")
                Spacer()
            }
            .font(.system(size: 14)).bold()
        }
    }

    private func requestResponsePersistenceAction(
        _ action: ResponsePersistenceAction
    ) {
        if case .deviceStorage = action,
           !(purchaseStatus || yorjPremium) {
            alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
            showAlert = true
            return
        }
        pendingResponsePersistenceAction = action
    }

    private func performResponsePersistenceAction(
        _ action: ResponsePersistenceAction
    ) {
        switch action {
        case .notes(let message):
            saveResponseToNotes(message)
        case .deviceStorage(let message):
            exportChatResponseToPDF(message)
        }
    }

    private func saveResponseToNotes(_ message: ChatMessage) {
        if notasModel.addNote(nota: message.text, title: "Nota del Chat") {
            alertMessage = "Se ha guardado la respuesta en Notas"
        } else {
            alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
        }
        showAlert = true
    }

    private func exportChatResponseToPDF(_ responseMessage: ChatMessage) {
        guard purchaseStatus || yorjPremium else {
            alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
            showAlert = true
            return
        }
        guard let responseIndex = model.messages.firstIndex(where: { $0.id == responseMessage.id }) else {
            alertMessage = "No se pudo identificar la respuesta para exportar."
            showAlert = true
            return
        }

        var promptText = "No disponible"
        if responseIndex > 0 {
            for idx in stride(from: responseIndex - 1, through: 0, by: -1) {
                let previous = model.messages[idx]
                if previous.isUser {
                    promptText = previous.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    break
                }
            }
        }

        let responseText = responseMessage.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !responseText.isEmpty else {
            alertMessage = "La respuesta está vacía."
            showAlert = true
            return
        }

        let sections = [
            PDFExportSection(
                title: "Conversación",
                lines: [
                    PDFExportLine(title: "Prompt", detail: promptText),
                    PDFExportLine(title: "Respuesta", detail: responseText)
                ]
            )
        ]

        let descriptor = PDFExportDocumentDescriptor(
            title: "Chat IA - Exportación de Respuesta",
            subtitle: "Generado el \(Date().formatted(date: .abbreviated, time: .shortened))",
            sections: sections
        )

        do {
            let data = try PDFExportModule.render(descriptor)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "ChatIA-\(dateLabel)"
            showPDFExporter = true
        } catch {
            alertMessage = "No se pudo generar el PDF."
            showAlert = true
        }
    }
    
    
    
    
  
//Vista que muestra un menu de opciones
    fileprivate struct AdjustableGridView_neville: View {
        // Número de filas y columnas
        
        let autor: Autores
        
        @State  var  rows: Int
        @State  var columns: Int = {
            #if os(iOS)
            return UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
            #else
            return 3 // por ejemplo, un valor fijo para macOS
            #endif
        }()
        
        
        @ObservedObject var model: ChatViewModel
        
        
        //Obtiene las sugerencias según el autor:
        
        private func GetSugerencias(autor: Autores) -> [String] {
            switch autor{
            case .neville:
                return ["Cuenta una fábula",
                        "¿Qué es la conciencia?","Quiero dejar de fumar","¿Qué es la revisión?",
                        "Me siento frustado","¿Cómo manifiesto mis deseos?","¿Cómo debo orar?",
                        "¿Qué es pecar?","Resume tu enseñanza","Dame un concejo","Tengo problemas","¿Quién es el Diablo?",
                        "¿Qué es la ley de creación?","Me pasan cosas malas","¿Cómo aplico tus enseñanzas?",
                        "Buenos días","¿Qué es la vida?","¿Cómo puedo mejorar?", "Quiero cambiar","Estoy estancado",
                        "¿Qué es la realidad?","Háblame del Alfarero"]
            case .JoeDispenza:
                return [
                    "¿Qué pensamientos debería cultivar cada día?",
                    "¿Qué emociones debería practicar diariamente?",
                    "¿Qué patrones mentales debería fortalecer?",
                    "¿Qué futuro debería imaginar con claridad?",
                    "¿Qué estado emocional debería mantener la mayor parte del tiempo?",
                    "¿Qué emociones del pasado debería soltar?",
                    "¿Cómo puedo pasar del modo supervivencia al modo creación?",
                    "¿Dónde debería enfocar mi atención cada día?",
                    "¿Qué pensamiento nuevo debería entrenar?",
                    "¿Qué emoción elevada debería generar ahora?",
                    "¿Qué intención clara debería establecer hoy?",
                    "¿Qué rasgos de personalidad debería desarrollar?",
                    "¿Qué comportamientos diarios debería adoptar?",
                    "¿Qué emociones deberían formar mi identidad?",
                    "¿En qué debería concentrar mi atención sostenida?",
                    "¿Cómo debería observar mis pensamientos automáticos?",
                    "¿Qué creencias limitantes debería cuestionar?",
                    "¿Qué futuro debería ensayar mentalmente?",
                    "¿Cómo debería sentirse mi futuro ideal?",
                    "¿Cómo puedo sentir gratitud antes de lograr algo?",
                    "¿Qué emoción debería cultivar hoy?",
                    "¿Cómo puedo alinear pensamientos y emociones?",
                    "¿Qué energía debería proyectar hacia mi entorno?",
                    "¿Cómo puedo responder en vez de reaccionar?",
                    "¿Qué posibilidades debería explorar ahora?",
                    "¿Qué hábitos mentales debería romper?",
                    "¿Qué pensamientos automáticos debería reemplazar?",
                    "¿Cómo puedo crear desde mi estado interno?",
                    "¿Cómo puedo liberar emociones de estrés?",
                    "¿Qué incomodidades debería aceptar para crecer?",
                    "¿Cómo puedo aprovechar lo desconocido para evolucionar?",
                    "¿Qué pequeñas acciones diarias generan mayor transformación?",
                    "¿Cómo actuaría mi mejor versión en esta situación?",
                    "¿Qué expectativas positivas debería instalar en mi mente?",
                    "¿Cómo debería vivir hoy si mi objetivo ya fuera real?",
                    "¿Qué cambio interno produciría mayor impacto en mi vida?","¿Cómo identificar pensamientos automáticos dominantes?",
                    "¿Cómo interrumpir rápidamente un pensamiento negativo?",
                    "¿Cuánto tarda en formarse una nueva red neuronal?",
                    "¿Cómo distinguir visualización efectiva de fantasía?",
                    "¿Errores comunes al ensayar mentalmente el futuro?",
                    "¿Cómo generar emociones elevadas desde estrés crónico?",
                    "¿Cómo liberar emociones almacenadas en el cuerpo?",
                    "¿Cuánto tarda el cuerpo en dejar la adicción al estrés?",
                    "¿Cómo saber si el cuerpo domina la mente?",
                    "¿Qué indica coherencia emocional real?",
                    "¿Estructura ideal de meditación diaria?",
                    "¿Cómo reconocer estados alfa o theta?",
                    "¿Importa más duración o calidad de meditación?",
                    "¿Cómo manejar pensamientos intrusivos al meditar?",
                    "¿Cómo entrenar atención sostenida?",
                    "¿Cómo sentir el futuro antes de que ocurra?",
                    "¿Cómo saber si el cuerpo cree en el futuro?",
                    "¿Qué pesa más: intención o emoción?",
                    "¿Mejor un resultado concreto o un estado?",
                    "¿Cómo proteger el estado interno del entorno?",
                    "¿Cómo inducir coherencia corazón-cerebro?",
                    "¿Cuánto mantener coherencia para cambios biológicos?",
                    "¿Diferencias fisiológicas en coherencia?",
                    "¿Qué respiración favorece la coherencia?",
                    "¿Cómo detectar coherencia sin instrumentos?",
                    "¿Qué cambios medibles hay en el campo personal?",
                    "¿Cómo estabilizar energía en entornos estresantes?",
                    "¿Puede la coherencia grupal influir en el entorno?",
                    "¿Cómo distinguir creación consciente de coincidencia?",
                    "¿Qué papel tiene la expectativa?",
                    "¿Primer hábito para cambiar personalidad?",
                    "¿Cómo evitar recaer en patrones emocionales?",
                    "¿Cómo atravesar la incomodidad del cambio?",
                    "¿Cómo debilitar patrones automáticos?",
                    "¿Qué evidencia epigenética habéis observado?",
                    "¿Señal clara de transformación biológica?"
                ]
            case .bruce:
                return [
                    "¿Cómo influye mi entorno diario en el comportamiento de mis células?",
                    "¿De qué manera mis pensamientos pueden afectar la salud de mi cuerpo?",
                    "¿Qué tipo de señales estoy enviando a mi biología a través de mis emociones?",
                    "¿Cómo puedo crear un entorno que favorezca el crecimiento y la regeneración celular?",
                    "¿Qué creencias tengo sobre mi salud que podrían estar influyendo en mi biología?",
                    "¿Cómo puedo identificar creencias limitantes que afectan mi bienestar?",
                    "¿De qué manera mis percepciones del mundo influyen en mi estado físico?",
                    "¿Cómo puedo reinterpretar una situación estresante para reducir su impacto biológico?",
                    "¿Qué hábitos diarios ayudan a mantener mi cuerpo en un estado de crecimiento en lugar de supervivencia?",
                    "¿Cómo influye el estrés en la capacidad de mi cuerpo para regenerarse?",
                    "¿Qué prácticas me ayudan a activar emociones que favorecen la salud?",
                    "¿Cómo puedo reducir las señales de miedo en mi vida cotidiana?",
                    "¿Qué tipo de pensamientos generan coherencia entre mi mente y mi cuerpo?",
                    "¿Cómo puedo desarrollar una percepción más positiva de mi entorno?",
                    "¿De qué manera mi identidad personal influye en mis decisiones de salud?",
                    "¿Cómo influyen mis relaciones sociales en mi biología?",
                    "¿Qué tipo de entorno social favorece mi bienestar físico y mental?",
                    "¿Cómo puedo reprogramar patrones subconscientes que ya no me sirven?",
                    "¿Qué papel juega la repetición en el cambio de mis creencias?",
                    "¿Qué nuevas creencias quiero instalar para mejorar mi salud?",
                    "¿Cómo puedo observar los programas subconscientes que aprendí en mi infancia?",
                    "¿Qué pensamientos automáticos dirigen la mayoría de mis decisiones diarias?",
                    "¿Cómo puedo usar la conciencia para modificar mis respuestas automáticas?",
                    "¿Cómo influye mi interpretación de los eventos en mis reacciones físicas?",
                    "¿Qué señales químicas produce mi cuerpo cuando experimento emociones positivas?",
                    "¿Cómo puedo entrenar mi mente para interpretar el entorno de forma más constructiva?",
                    "¿Qué prácticas me ayudan a generar coherencia entre pensamiento, emoción y cuerpo?",
                    "¿Cómo puedo crear rutinas que refuercen nuevas percepciones positivas?",
                    "¿De qué manera la información que consumo influye en mi percepción del mundo?",
                    "¿Cómo puedo educar mi mente para favorecer estados de bienestar?",
                    "¿Qué cambios en mi entorno podrían mejorar mi salud celular?",
                    "¿Cómo puedo reconocer cuándo mi cuerpo está en modo supervivencia?",
                    "¿Qué acciones me ayudan a volver a un estado de crecimiento?",
                    "¿Cómo puedo cultivar emociones de amor, gratitud o conexión en mi vida diaria?",
                    "¿Qué prácticas diarias ayudan a fortalecer la conexión mente-cuerpo?",
                    "¿Cómo puedo recordar que mi biología no está determinada únicamente por mis genes?"
                ]
                
            case .gregg:
                return [
                    "¿Cómo puedo sentir en este momento mi conexión con el campo que une toda la creación?",
                    "¿De qué manera mis pensamientos y emociones afectan al sistema interconectado del universo?",
                    "¿Qué pensamiento estoy emitiendo ahora mismo hacia el campo de conciencia?",
                    "¿Qué emoción está generando mi corazón en este momento?",
                    "¿Cómo puedo crear coherencia entre lo que pienso y lo que siento?",
                    "¿Qué emoción quiero transmitir al campo para influir positivamente en mi realidad?",
                    "¿Cómo se sentiría mi vida si el resultado que deseo ya hubiese ocurrido?",
                    "¿Qué creencia actual está moldeando mi experiencia de hoy?",
                    "¿Qué señales internas estoy enviando a mi ADN a través de mis pensamientos y emociones?",
                    "¿Cómo puedo practicar la gratitud ahora mismo para generar coherencia?",
                    "¿Estoy actuando desde el miedo o desde la confianza en este momento?",
                    "¿Cuál es mi intención clara en esta situación específica?",
                    "¿Cómo puedo vivir mi oración como una experiencia ya cumplida?",
                    "¿Qué cambiaría si percibiera el tiempo como algo no estrictamente lineal?",
                    "¿Qué sabiduría antigua podría ayudarme a comprender mejor este momento de mi vida?",
                    "¿Qué estado interno puedo cultivar para fortalecer mi resiliencia?",
                    "¿Cómo está influyendo mi percepción actual en la respuesta de mi cuerpo?",
                    "¿En qué quiero enfocar mi atención de manera sostenida hoy?",
                    "¿Cómo puedo asumir responsabilidad personal dentro de la unidad de la vida?",
                    "¿Qué cambio interior puedo hacer hoy que contribuya al cambio global?",
                    "¿Qué me está diciendo mi intuición en este momento?",
                    "¿Mis emociones actuales son coherentes con la intención que tengo?",
                    "¿Qué patrón interno podría estar reflejándose en mi realidad externa?",
                    "¿Cómo puedo cooperar mejor con las personas y sistemas a mi alrededor?",
                    "¿Qué contribución estoy haciendo al estado de la conciencia colectiva?",
                    "¿Qué emoción dominante estoy cultivando durante el día?",
                    "¿Qué resultado deseo experimentar y cómo se siente emocionalmente?",
                    "¿Qué historia mental estoy repitiendo que podría estar limitando mi experiencia?",
                    "¿Cómo puedo transformar el miedo en curiosidad o compasión?",
                    "¿Qué pequeña acción coherente puedo tomar ahora para alinear mente y corazón?",
                    "¿Cómo cambiaría mi realidad si creyera plenamente en mi capacidad de influir en el campo?",
                    "¿Qué prácticas diarias pueden fortalecer la coherencia corazón-cerebro?",
                    "¿Cómo puedo usar la respiración para generar coherencia emocional?",
                    "¿Qué parte de mi vida necesita más gratitud y reconocimiento?",
                    "¿Qué intención quiero enviar al mundo hoy?",
                    "¿Qué estado emocional quiero aportar a la conciencia colectiva?"
                    ]
            }
            
        }
            

            
        // Layout dinámico de columnas
        var gridLayout: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
        }
        
        
        var body: some View {
            VStack(alignment: .leading){
                
                let sugerencias  = GetSugerencias(autor: self.autor)
                
                Text("Sugerencias:").font(.subheadline).padding(.horizontal).foregroundStyle(.primary).bold().id(12)
                    LazyVGrid(columns: gridLayout, spacing: 10) {
                        ForEach(0..<sugerencias.count, id: \.self) { index in
                            Button(action: {
                                model.submitMessage(sugerencias[index])
                            }) {
                                Text(sugerencias[index])
                                    .font(.system(size: 14))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(GlassButtonStyle())
                        }
                    }
                
                    
            }
            .padding(.horizontal, 4)
            
        }
    }
    
}

@available(iOS 26.0, macOS 26.0, *)
private struct ChatAppearanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingModel = SettingModel()

    @Binding var promptTextColor: Color
    @Binding var responseTextColor: Color
    @Binding var chatBackgroundPrimary: Color
    @Binding var chatBackgroundSecondary: Color
    @Binding var responseBubbleBackground: Color

    var body: some View {
        NavigationStack {
            Form {
                Section("Colores del texto") {
                    ColorPicker(
                        "Texto del prompt",
                        selection: $promptTextColor
                    )
                    ColorPicker(
                        "Texto de las respuestas",
                        selection: $responseTextColor
                    )
                    Text("El nombre del modelo que aparece bajo cada respuesta utiliza también el color del texto de las respuestas.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Fondo del chat") {
                    ColorPicker(
                        "Color superior",
                        selection: $chatBackgroundPrimary
                    )
                    ColorPicker(
                        "Color inferior",
                        selection: $chatBackgroundSecondary
                    )
                    Text("Los dos colores forman el degradado del fondo general.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Burbujas de respuesta") {
                    ColorPicker(
                        "Color del fondo",
                        selection: $responseBubbleBackground
                    )
                }

                Section("Vista previa") {
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Text("Este es un prompt")
                                .foregroundStyle(promptTextColor)
                                .padding(10)
                                .background(.black.opacity(0.7))
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12,
                                        style: .continuous
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Esta es una respuesta de ejemplo.")
                                .foregroundStyle(responseTextColor)
                                .padding(10)
                                .background(responseBubbleBackground)
                                .clipShape(
                                    RoundedRectangle(
                                        cornerRadius: 12,
                                        style: .continuous
                                    )
                                )
                            Label(
                                "Modelo utilizado",
                                systemImage: "sparkles"
                            )
                            .font(.caption2)
                            .foregroundStyle(responseTextColor.opacity(0.72))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                chatBackgroundPrimary,
                                chatBackgroundSecondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
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
            .navigationTitle("Apariencia del Chat IA")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: promptTextColor) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_textContent,
                color: color
            )
        }
        .onChange(of: responseTextColor) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_textRespond,
                color: color
            )
        }
        .onChange(of: chatBackgroundPrimary) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_main_a,
                color: color
            )
        }
        .onChange(of: chatBackgroundSecondary) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_main_b,
                color: color
            )
        }
        .onChange(of: responseBubbleBackground) { _, color in
            settingModel.saveColor(
                forkey: AppCons.UD_setting_colorIA_responseBubble,
                color: color
            )
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 650)
        #endif
    }

    private func restoreDefaults() {
        promptTextColor = AppCons.defaultColorIA_promptText
        responseTextColor = AppCons.defaultColorIA_responseText
        chatBackgroundPrimary = AppCons.defaultColorIA_main_a
        chatBackgroundSecondary = AppCons.defaultColorIA_main_b
        responseBubbleBackground = AppCons.defaultColorIA_responseBubble
    }
}

@available(iOS 26.0, macOS 26.0, *)
private struct ConversationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: ChatViewModel
    let notasModel: NotasModel

    @State private var conversationToRename: StoredAIConversation?
    @State private var editedTitle = ""
    @State private var searchText = ""
    @State private var isSelecting = false
    @State private var selectedConversationIDs = Set<UUID>()
    @State private var showDeleteConfirmation = false
    @State private var isPerformingBulkAction = false
    @State private var resultMessage: String?

    private var filteredConversations: [StoredAIConversation] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return model.conversations }
        return model.conversations.filter { conversation in
            conversation.title.localizedStandardContains(query)
                || Autores(storedRawValue: conversation.authorRawValue)
                    .getNombre
                    .localizedStandardContains(query)
        }
    }

    private var filteredConversationIDs: Set<UUID> {
        Set(filteredConversations.map(\.id))
    }

    private var areAllFilteredConversationsSelected: Bool {
        !filteredConversationIDs.isEmpty
            && filteredConversationIDs.isSubset(of: selectedConversationIDs)
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredConversations.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "Sin conversaciones" : "Sin resultados",
                        systemImage: searchText.isEmpty
                            ? "bubble.left.and.bubble.right"
                            : "magnifyingglass",
                        description: Text(
                            searchText.isEmpty
                                ? "Inicia una conversación para verla aquí."
                                : "Prueba con otro título o autor."
                        )
                    )
                } else {
                    ForEach(filteredConversations) { conversation in
                        Button {
                            if isSelecting {
                                toggleSelection(for: conversation.id)
                            } else {
                                Task {
                                    await model.openConversation(id: conversation.id)
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                if isSelecting {
                                    Image(systemName: selectedConversationIDs.contains(
                                        conversation.id
                                    ) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(
                                        selectedConversationIDs.contains(conversation.id)
                                            ? .blue
                                            : .secondary
                                    )
                                }

                                Image(Autores(
                                    storedRawValue: conversation.authorRawValue
                                ).imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(conversation.title)
                                        .lineLimit(2)
                                    HStack(spacing: 5) {
                                        let provider = AIChatProviderKind(
                                            rawValue: conversation.providerRawValue
                                        ) ?? .apple
                                        Label(
                                            provider.shortDisplayName,
                                            systemImage: provider.systemImage
                                        )
                                        Text("·")
                                        Text(conversation.updatedAt, format: .dateTime)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if model.activeConversationID == conversation.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            if !isSelecting {
                                Button(role: .destructive) {
                                    Task {
                                        await model.deleteConversation(id: conversation.id)
                                    }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                        .contextMenu {
                            if !isSelecting {
                                Button {
                                    editedTitle = conversation.title
                                    conversationToRename = conversation
                                } label: {
                                    Label("Cambiar nombre", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    Task {
                                        await model.deleteConversation(id: conversation.id)
                                    }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Conversaciones")
            .searchable(text: $searchText, prompt: "Título o autor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isSelecting ? "Cancelar" : "Cerrar") {
                        if isSelecting {
                            endSelection()
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if isSelecting {
                        Button("Hecho") {
                            endSelection()
                        }
                    } else {
                        Button {
                            isSelecting = true
                        } label: {
                            Label("Seleccionar", systemImage: "checkmark.circle")
                        }
                        .disabled(model.conversations.isEmpty)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    if !isSelecting {
                        Button {
                            Task {
                                await model.createNewConversation()
                                dismiss()
                            }
                        } label: {
                            Label("Nueva", systemImage: "square.and.pencil")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isSelecting {
                    bulkActionsBar
                }
            }
            .confirmationDialog(
                "Eliminar conversaciones",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(
                    selectedConversationIDs.count == 1
                        ? "Eliminar conversación"
                        : "Eliminar \(selectedConversationIDs.count) conversaciones",
                    role: .destructive
                ) {
                    deleteSelectedConversations()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Esta acción eliminará permanentemente las conversaciones seleccionadas y sus mensajes.")
            }
            .alert(
                "Cambiar nombre",
                isPresented: Binding(
                    get: { conversationToRename != nil },
                    set: { if !$0 { conversationToRename = nil } }
                )
            ) {
                TextField("Nombre", text: $editedTitle)
                Button("Guardar") {
                    guard let conversationToRename else { return }
                    Task {
                        await model.renameConversation(
                            id: conversationToRename.id,
                            title: editedTitle
                        )
                        self.conversationToRename = nil
                    }
                }
                Button("Cancelar", role: .cancel) {
                    conversationToRename = nil
                }
            }
            .alert(
                "Historial de Chat IA",
                isPresented: Binding(
                    get: { resultMessage != nil },
                    set: { if !$0 { resultMessage = nil } }
                )
            ) {
                Button("Aceptar") {
                    resultMessage = nil
                }
            } message: {
                Text(resultMessage ?? "")
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 520)
        #endif
    }

    private var bulkActionsBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text(
                    selectedConversationIDs.count == 1
                        ? "Seleccionada: 1"
                        : "Seleccionadas: \(selectedConversationIDs.count)"
                )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(selectAllTitle) {
                    toggleSelectAllFiltered()
                }
                .disabled(filteredConversations.isEmpty || isPerformingBulkAction)
            }

            HStack(spacing: 12) {
                Button {
                    convertSelectedConversationsToNotes()
                } label: {
                    Label("Convertir en Notas", systemImage: "note.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    selectedConversationIDs.isEmpty
                        || isPerformingBulkAction
                        || selectionContainsActiveResponse
                )

                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(
                    selectedConversationIDs.isEmpty || isPerformingBulkAction
                )
            }

            if isPerformingBulkAction {
                ProgressView()
                    .controlSize(.small)
            } else if selectionContainsActiveResponse {
                Text("Espera a que termine la respuesta activa antes de convertir esta conversación en Nota.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
    }

    private var selectAllTitle: String {
        if areAllFilteredConversationsSelected {
            return "Quitar selección"
        }
        return searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Seleccionar todo"
            : "Seleccionar resultados"
    }

    private var selectionContainsActiveResponse: Bool {
        guard model.isResponding, let activeID = model.activeConversationID else {
            return false
        }
        return selectedConversationIDs.contains(activeID)
    }

    private func toggleSelection(for id: UUID) {
        if selectedConversationIDs.contains(id) {
            selectedConversationIDs.remove(id)
        } else {
            selectedConversationIDs.insert(id)
        }
    }

    private func toggleSelectAllFiltered() {
        if areAllFilteredConversationsSelected {
            selectedConversationIDs.subtract(filteredConversationIDs)
        } else {
            selectedConversationIDs.formUnion(filteredConversationIDs)
        }
    }

    private func endSelection() {
        isSelecting = false
        selectedConversationIDs.removeAll()
    }

    private func deleteSelectedConversations() {
        let ids = selectedConversationIDs
        guard !ids.isEmpty else { return }
        isPerformingBulkAction = true
        Task {
            let succeeded = await model.deleteConversations(ids: ids)
            isPerformingBulkAction = false
            if succeeded {
                endSelection()
            } else {
                resultMessage = model.userFacingError
                    ?? "No fue posible eliminar las conversaciones seleccionadas."
                model.userFacingError = nil
            }
        }
    }

    private func convertSelectedConversationsToNotes() {
        let ids = selectedConversationIDs
        guard !ids.isEmpty else { return }
        isPerformingBulkAction = true

        Task {
            do {
                let chatDrafts = try await model.noteDrafts(for: ids)
                guard !chatDrafts.isEmpty else {
                    isPerformingBulkAction = false
                    resultMessage = "No se encontraron conversaciones para convertir."
                    return
                }
                let noteDrafts = chatDrafts.map {
                    NotaCreationDraft(
                        title: $0.title,
                        content: $0.content,
                        category: "Chat IA"
                    )
                }
                let succeeded = notasModel.addNotes(noteDrafts)
                isPerformingBulkAction = false

                if succeeded {
                    let count = noteDrafts.count
                    endSelection()
                    resultMessage = count == 1
                        ? "La conversación se convirtió en una Nota."
                        : "Se crearon \(count) Notas, una por cada conversación."
                } else {
                    resultMessage = "No fue posible crear las Notas. No se guardó ningún resultado parcial."
                }
            } catch {
                isPerformingBulkAction = false
                resultMessage = "No fue posible leer las conversaciones: \(error.localizedDescription)"
            }
        }
    }
}






@available(iOS 26.0, macOS 26.0, *)
#Preview {
    NavigationStack {
        ChatView(textoACargar: nil)
    }
}

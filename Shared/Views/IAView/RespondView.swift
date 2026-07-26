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
    @State var ColorChatIAPrimario          : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.7)
    @State var ColorChatIASecundario        : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorRespondIAFuente         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textRespond) ?? .black
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
    
    //Obtiene el nombre completo del autor
    private func getNameAutor(autorRaw: String) -> String{
        switch autorRaw {
        case "nev": return "Neville Goddard"
        case "jd": return "Dr. Joe Dispenza"
        case "bruceL": return "Dr. Bruce H. Lipton"
        case "gregg": return "Greegg Braden"
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
            LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .bottom)
            
            if (self.purchaseStatus || self.yorjPremium){
                
                if self.DescargoDeIA{
                    
                    VStack{
                        HStack{
                            Text("Segun Autor: \(self.getNameAutor(autorRaw: self.autorRespuesta))").bold()
                            Spacer()
                            
                            Menu{
                                Text("Autores:")
                                
                                Button{
                                    self.isloading = true
                                    self.autorRespuesta = "nev"
                                    generarTexto(tipoSalida: self.tipoSalida, autor: "nev")
                                    
                                }label:{
                                    #if os(macOS)
                                    iconMenu(nombre: "nev-min", title: "Neville Goddard")
                                    #else
                                    Label("Neville Goddard", image: "nev-min")
                                    #endif
                                    
                                }
                                
                                
                                Button{
                                    self.isloading = true
                                    self.autorRespuesta = "jd"
                                    generarTexto(tipoSalida: self.tipoSalida, autor: "jd")
                                }label:{
                                    #if os(macOS)
                                    iconMenu(nombre: "jd", title: "Dr. Joe Dispenza")
                                    #else
                                    Label("Dr. Joe Dispenza", image: "jd")
                                    #endif
                                    
                                }
                                
                                Button{
                                    self.isloading = true
                                    self.autorRespuesta = "bruceL"
                                    generarTexto(tipoSalida: self.tipoSalida, autor: "bruceL")
                                }label:{
                                    #if os(macOS)
                                    iconMenu(nombre: "bruce", title: "Dr. Bruce Lipton")
                                    #else
                                    Label("Dr. Bruce Lipton", image: "bruce")
                                    #endif
                                }
                                
                                Button{
                                    self.isloading = true
                                    self.autorRespuesta = "gregg"
                                    generarTexto(tipoSalida: self.tipoSalida, autor: "gregg")
                                }label:{
                                    #if os(macOS)
                                    iconMenu(nombre: "gregg", title: "Gregg Braden")
                                    #else
                                    Label("Gregg Braden", image: "gregg")
                                    #endif
                                }
                                
                            }label: {
                                Image(self.getImageAutor(autorRaw: self.autorRespuesta))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                            .disabled(self.isloading)
                            
                            
                            
                        }
                        .padding()
                        .redacted(reason: self.isloading ? .placeholder : []) //Mostrar un skeleton mientras se carga el contenido
                        
                        if self.isloading {
                            
                            VistaDeProcesamiento().padding()
                            Spacer()
                            
                        }else{
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
                            .redacted(reason: self.isloading ? .placeholder : []) //Mostrar un skeleton mientras se carga el contenido
                        }
                    }
                    
                    
                }else{
                    DescargoResponsabilidadIA(VentanaEnSetting: false)
                }
            }else{
                PurchaseView(mostrarLogo: true, mostrarBotonCerrarMacOS: true)
            }
            
            
  
        }
        .onAppear{
            guard !hasStartedGeneration,
                  self.purchaseStatus || self.yorjPremium else { return }
            hasStartedGeneration = true
            self.autorOriginal = self.autorRespuesta
            generarTexto(tipoSalida: self.tipoSalida)
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
        .sheet(isPresented: self.$showSheetInfo){
            ZStack{
                LinearGradient.FondoGrizAzulMate()
                    .ignoresSafeArea()
                VStack{
                    ScrollView{
                        Text("""
                            ☘️ Información sobre la IA utilizada:
                            
                            Estas funciones utilizan el modelo de Foundation Models de Apple y procesan las solicitudes en el dispositivo. El historial del chat se guarda localmente en el dispositivo y no se sincroniza con iCloud.
                            
                            El modelo genera respuestas inspiradas en las enseñanzas de Neville Goddard, Joe Dispenza, Bruce Lipton y Gregg Braden. Estas respuestas pueden contener errores, por lo que conviene revisarlas y tomar decisiones informadas.
                            
                            Las instrucciones limitan las respuestas al marco establecido para cada autor, diferencian las enseñanzas de los hechos científicos y reducen sesgos e información inventada.
                            
                            Esta herramienta ofrece contenido educativo y de reflexión. No sustituye asesoramiento médico, psicológico, legal ni financiero.
                            
                            La configuración del modelo se revisará y actualizará junto con la aplicación.
                            """)
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
                        Text("Generando Concejos Prácticos").bold()
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
        VStack{
            ScrollView{
                    Text(respuestaIA)
                        .font(.system(size: CGFloat(self.fontSizeChatIA)))
                        .foregroundColor(Color(self.ColorRespondIAFuente))
                        .textSelection(.enabled)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
        
        #else
        VStack(alignment: .leading) {
            SelectableText(text: respuestaIA, fontSize: CGFloat(self.fontSizeChatIA), fonColor: UIColor(self.ColorRespondIAFuente), alignment: .left )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
        
        #endif
        
        
    }
    
    
//Vista de botones de opciones que aparecen debajo de cada respuesta de la IA
    @ViewBuilder
    private func buttomOpcionesViewContent() -> some View {
        HStack(spacing: 25){
            
            Menu{
                //Copiar la respuesta a notas
                Button{
                    if let nameConferencia = self.nameConference {
                        if self.notasModel.addNote(nota: "\(self.creatorContentToShare ) \n\n ----Texto de Referencia---- \n \(self.tipoSalida == .interpretar ? self.texto : nameConferencia + " (Conferencia)")", title: "Nota de IA"){
                            self.alertMessage = "Se ha guardado la respuesta en Notas"
                            self.showAlert = true
                        }else{
                            self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                            self.showAlert = true
                        }
                    }
                    
                }label:{
                    Label("Guardar en Notas", systemImage: "list.clipboard")
                }
                .foregroundStyle(.black)
                .buttonStyle(.bordered)
                
                //Cambiar de Autor
                Menu{
                    Button("Neville Goddard"){
                        self.isloading = true
                        self.autorRespuesta = "nev"
                        generarTexto(tipoSalida: self.tipoSalida, autor: "nev")
                        
                    }
                    Button("Dr. Joe Dispenza"){
                        self.isloading = true
                        self.autorRespuesta = "jd"
                        generarTexto(tipoSalida: self.tipoSalida, autor: "jd")
                    }
                    Button("Dr. Bruce Lipton"){
                        self.isloading = true
                        self.autorRespuesta = "bruceL"
                        generarTexto(tipoSalida: self.tipoSalida, autor: "bruceL")
                    }
                    
                    Button("Gregg Braden"){
                        self.isloading = true
                        self.autorRespuesta = "gregg"
                        generarTexto(tipoSalida: self.tipoSalida, autor: "gregg")
                    }
                }label: {
                    Label("Cambiar Autor...", systemImage: "person")
                }
                .foregroundStyle(.black)
                .buttonStyle(.bordered)
                
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
                        self.tipoSalida = .interpretar
                        self.generarTexto(tipoSalida: self.tipoSalida)
                    }
                    Button("Práctica Concreta"){
                        self.tipoSalida = .practicaConcreta
                        self.generarTexto(tipoSalida: self.tipoSalida)
                    }
                    Button("Listado de prácticas"){
                        self.tipoSalida = .practicas
                        self.generarTexto(tipoSalida: self.tipoSalida)
                    }
                    Button("Puntos Claves"){
                        self.tipoSalida = .puntosClaves
                        self.generarTexto(tipoSalida: self.tipoSalida)
                    }
                    Button("Resumen"){
                        self.tipoSalida = .resumen
                        self.generarTexto(tipoSalida: self.tipoSalida)
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
        }
        generationTask?.cancel()

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
        let longFormText = sourceTextForLongOperation()
        switch tipoSalida {
        case .puntosClaves:
            try await model.executeRequestPuntosClaves(texto: longFormText)
        case .practicas:
            try await model.executeRequestListAplicacionPractica(
                texto: longFormText,
                autor: autorRespuesta
            )
        case .practicaConcreta:
            try await model.executeRequestPracticaConcreta(
                texto: texto,
                autor: autorRespuesta
            )
        case .resumen:
            try await model.executeRequestResumenGeneral(texto: longFormText)
        case .interpretar:
            try await model.executeRequestInterpretaTexto(
                texto: texto,
                autor: autorRespuesta
            )
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






  

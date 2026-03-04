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
    @State private var bounce = false //Para animar la imagend de IA en el centro de la pantalla
    
    @AppStorage(AppCons.UD_setting_fontContentSize)    var fontSizeContenido : Int = 24
    @AppStorage(AppCons.UD_setting_IA_AceptacionDescargo)    var DescargoDeIA : Bool = false // Si es true se permite utilizar la IA.

    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    
    //Parámetros
    let nameConference  : String //Nombre de la conferencia
    let texto           : String //Texto a procesar por la IA
    let tipoSalida      : TiposSalida //Especifica el tipo de salida desea: Puntos Claves / Resumen General, etc
    
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
    
    
    
    
    var body: some View {
        ZStack{
            LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea(edges: .bottom)
            
            if (self.purchaseStatus || self.yorjPremium){
                if self.DescargoDeIA{
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
                    //Sobrepone una vista de procesamiento
                        if self.isloading{
                            VistaDeProcesamiento().padding()
                        }
                    
                }else{
                    DescargoResponsabilidadIA(VentanaEnSetting: false)
                }
            }else{
                PurchaseView(mostrarLogo: true, mostrarBotonCerrarMacOS: true)
            }
            
            
  
        }
        .onAppear{
            if (self.purchaseStatus || self.yorjPremium){
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                    }
                    
                   generarTexto()
                    
                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            }
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
                RespondView(nameConference: "", texto: text.texto, tipoSalida: .interpretar)
        }
        .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaChatIA){ text in
                ChatView(textoACargar: text.texto)
        }
        .sheet(item: $showSheetTtextoCopiadoAlPortapapelesParaLienzo){ text in
                LienzoMain(texto : text.texto, imagenPrimariaACargar: nil)
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
                    .foregroundStyle(.white)
                    .offset(y: bounce ? -5 : 5) // movimiento hacia arriba y abajo
                                .animation(
                                    .easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: bounce
                                )
                                .onAppear {
                                    bounce = true
                                }
                //Text(self.tipoSalida == .puntosClaves ? "Generando Puntos Claves" : "Creando  Resumen")
                switch self.tipoSalida {
                case .puntosClaves:
                    Text("Generando Puntos Claves")
                case .resumen:
                    Text("Creando Resumen")
                case .practicas:
                    Text("Generando Concejos Prácticos")
                case .practicaConcreta:
                    Text("Generando Aplicación Práctica")
                case .interpretar:
                    Text("Interpretando Texto")
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
                
                #if os(macOS)
                //Permitiendo Cancelar la operacion
                VStack{
                    Button("Cancelar"){
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                            }
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    .tint(.black).bold()
                }.padding()
                
                
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
                ContenidoView(contenido: idea)
            }
            
            buttomOpcionesViewContent()
            
        }
        .padding()
    }
    
    
//Para mostrar un resumen General de la conferencia (solo conferencia)
@ViewBuilder
    private func VistaDeResumenGeneral() -> some View{
        VStack{
            ContenidoView(contenido: self.model.resumenGeneral)
            buttomOpcionesViewContent()
        }
        .padding()

    }
    

//Para mostrar un listado de acciones prácticas (solo Conferencia)
@ViewBuilder
    private func VistaPracticas() -> some View{
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach (self.model.practicas, id: \.self){ idea in
                ContenidoView(contenido: idea)

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
                
                ContenidoView(contenido: self.model.practicaConcreta)
                
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
                
                ContenidoView(contenido: self.model.interpretacion)
                
                buttomOpcionesViewContent()
                
                Spacer()
                
                VStack{
                    TextoReferenciaView()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
            }
            .padding()

        
    }

    
    
    
//-----  Componentes visuales del cuadro de Contenido que se presenta al usuario
    
//Vista de contenido
    @ViewBuilder
    private func ContenidoView(contenido: String) -> some View {
        #if os(macOS)
        VStack{
            ScrollView{
                    Text(texto)
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
            
            SelectableText(text: contenido, fontSize: CGFloat(self.fontSizeChatIA), fonColor: UIColor(self.ColorRespondIAFuente), alignment: .left )
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
            //Copiar la respuesta a notas
            Button{
                
                if self.notasModel.addNote(nota: "\(self.creatorContentToShare ) \n\n ----Texto de Referencia---- \n \(self.tipoSalida == .interpretar ? self.texto : self.nameConference + " (Conferencia)")", title: "Nota de IA"){
                    self.alertMessage = "Se ha guardado la respuesta en Notas"
                    self.showAlert = true
                }else{
                    self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                    self.showAlert = true
                }
            }label:{
                Label("", systemImage: "text.page")
                    .font(.system(size: 24))
            }
            .tint(.black)
            
            //Regenerar Respuesta
            Button{
                generarTexto() //Función que regenera el contenido
            }label: {
                Label("", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 24))
            }
            .tint(.black)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
//Vista del texto de referencia(Solo para Frases, reflexiones, citas, etc. NO conferencias):
    @ViewBuilder
    private func TextoReferenciaView() -> some View {
        if self.isloading{
            Text(self.texto)
                .padding()
        }else{
            VStack(alignment: .leading){
                SelectableText(text : self.texto, fontSize: CGFloat(20), fonColor: UIColor(Color.black.opacity(0.7)), alignment: .left )
            }
            .padding()
        }
        
    }

//---- FIN
    
    
    

    //Funciones del botón de Regenerar Texto. Vuelce hacer una solicitud de respuesta a Apple Intelligence
    private func generarTexto(){
            switch self.tipoSalida {
            case .puntosClaves:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestPuntosClaves(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .practicas:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestListAplicacionPractica(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .practicaConcreta:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestPracticaConcreta(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .resumen:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestResumenGeneral(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
            case .interpretar:
                Task { @MainActor in
                    withAnimation {
                        self.isloading = true
                        bounce = true
                    }
                        await self.model.executeRequestInterpretaTexto(texto: self.texto)

                    withAnimation {
                        self.isloading = false
                    }
                    
                }
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






  



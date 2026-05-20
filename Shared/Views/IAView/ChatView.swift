//
//  DialogoView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/10/25.
//
//Ventana de chat de IA, recibir concejos y sugerencias relacionadas con las enseñanzas de neville 

import SwiftUI
import UniformTypeIdentifiers




@available(iOS 26.0, macOS 26.0, *)
struct ChatView: View {
    

    
    @StateObject private var model = ChatViewModel.shared
    
    @State private var  notasModel : NotasModel = NotasModel()
    
    @StateObject private var clipBoarModel : ClipboardObserver = ClipboardObserver() //Para observar cambios en el portapapales
    //@StateObject private var purchaseModel : PurchaseManager = .shared //Para las funciones Premium
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)  var fontSizeChatIA : Int = 20
    
    @AppStorage(AppCons.UD_setting_IA_AceptacionDescargo)    var DescargoDeIA : Bool = false // True permite acceso al chet IA,false prohíbe el acceso al chat de IA
    
    @State private var lastID : UUID? = nil //Para poder desplazar la lista de mensajes en el chat hasta el último siempre
    
    
    @State private var autor : Autores = .neville
    
    let textoACargar : String?  //Permite cargar una frase o nota  y usarla en el chatIA para entablar una conversación.
    
    
    
    
    @FocusState private var focus
    
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "ChatIA.pdf"
    
    //Colores de IA chat:
    @State var ColorChatIAPrimario         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.7)
    @State var ColorChatIASecundario       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorChatIAFuente           : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textContent) ?? .white
    
    //manejar el texto copiado:
    @State private var showSheetInterpretarTextoCopiadoIA : Bool = false
    @State private var showSheetChatIATextoCopiado : Bool   = false
    @State private var showSheetLienzoTextoCpiado  : Bool   = false
    @State private var showSheetTextoCopiadoAlPortapapelesParaInterpretar   : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaChatIA       : TextoCopiadoAlPortapapeles? = nil
    @State private var showSheetTtextoCopiadoAlPortapapelesParaLienzo       : TextoCopiadoAlPortapapeles? = nil
    
    
    
    
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
                                                        
                                                        SelectableText(text : msg.text, fontSize: CGFloat(self.fontSizeChatIA),fonColor: UIColor(self.ColorChatIAFuente) , alignment : .left)
                                                            .padding(.horizontal, 10)
                                                            .background(Color.black.opacity(0.5))
                                                            .cornerRadius(12)
                                                        
                                                        MenuOpcionesRespuesta(message: msg)
                                                            .padding(.vertical, 0)
                                                            .id(msg.id) //Para porpósitos de scrooll
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
                                    AdjustableGridView_neville( autor : self.$autor ,rows : 11 , model: self.model)
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
        .navigationTitle("Pregunta  a \(self.autor.getNombre)")
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar{
            if self.DescargoDeIA {
                
               
                
                //Cambiar instrucciones de conversación
                ToolbarItem{

                     Menu{
                         Text("Cambiar Autor")
                         Button{
                             self.autor = .neville
                             self.model.newConversation()
                         }label:{
                             #if os(macOS)
                             iconMenu(nombre: "nev-min", title: "Neville")
                             #else
                             Label("Neville Goddard", image: "nev-min")
                             #endif
                         }
                         
                         
                         Button{
                             self.autor = .JoeDispenza
                             self.model.newConversation()
                         }label:{
                             #if os(macOS)
                             iconMenu(nombre: "jd", title: "Joe Dispenza")
                             #else
                             Label("Joe Dispenza", image: "jd")
                             #endif
                         }
                         
                         Button{
                             self.autor = .bruce
                             self.model.newConversation()
                         }label:{
                             #if os(macOS)
                             iconMenu(nombre: "bruce", title: "Bruce lipton")
                             #else
                             Label("Bruce lipton", image: "bruce")
                             #endif
                             
                         }
                         
                         Button{
                             self.autor = .gregg
                             self.model.newConversation()
                         }label:{
                             #if os(macOS)
                             iconMenu(nombre: "gregg", title: "Gregg Braden")
                             #else
                             Label("Gregg Braden", image: "gregg")
                             #endif
                            
                         }
                         
                     }label: {

                          switch self.autor {
                          case .neville: iconoRedimensionado(nombre: "nev-min")
                          case .JoeDispenza: iconoRedimensionado(nombre: "jd")
                          case .bruce: iconoRedimensionado(nombre: "bruce")
                          case .gregg: iconoRedimensionado(nombre: "gregg")
                          }  
                     }
                     
                   
                }
                
                ToolbarSpacer(.fixed)
                //Barra de opciones para texto copiado:
                ToolbarItem{
                    //Menú de acciones con el texto copiado
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
                
                //Boton Nueva Conversación
                ToolbarItem {
                    Button{
                        withAnimation {
                            self.model.newConversation()
                        }
                        
                        
                    }label:{
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            
        }
        .task {
            //🔥 Carga una sesión por defecto
            self.autor = .neville
            model.newConversation()
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
                    Spacer()
                }else{
                    TextField("Escribe algo…", text: $model.inputText, axis: .vertical)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .disabled(model.isResponding)
                        .padding(.vertical, 8)
                        .padding(.leading, 5)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(.black.opacity(0.8)))
                        .focused(self.$focus)
                        .onSubmit {
                            if ( !self.model.inputText.trimmingCharacters(in: .whitespaces).isEmpty  && self.model.inputText.trimmingCharacters(in: .whitespaces).count >= ChatViewModel.maxCharactersContext){
                                self.alertMessage = "El texto a enviar es demasiado largo. Se admite como máximo 4100 caracteres."
                                self.showAlert = true
                            }else{
                                Task{
                                    await model.sendMessage(autor: self.autor, questionUser: model.inputText)
                                    self.focus = false
                                }
                            }
                            
                            
                        }
                    
                    Button{
                        if ( !self.model.inputText.trimmingCharacters(in: .whitespaces).isEmpty  && self.model.inputText.trimmingCharacters(in: .whitespaces).count >= ChatViewModel.maxCharactersContext){
                            self.alertMessage = "El texto a enviar es demasiado largo. Se admite como máximo 4100 caracteres."
                            self.showAlert = true
                        }else{
                            Task{
                                await model.sendMessage(autor: self.autor, questionUser: model.inputText)
                                self.focus = false
                            }
                        }
                    }label:{
                        Text("Enviar").bold()
                        
                    }
                    .tint(.orange)
                    .foregroundStyle(.black)
                    .buttonStyle(.bordered)
                    .disabled(model.inputText.trimmingCharacters(in: .whitespaces).isEmpty || model.isResponding)
                }
                
                
                
                
            }
            .onAppear{
                //Cargar en el promt el valor pasado a la variable Texto: puede ser una frase, nota o cita
                if let texto = self.textoACargar{
                    if !texto.isEmpty{
                        self.model.inputText = "Hablemos sobre este texto: \(texto)"
                    }
                }
            }
            
        }
        
    }
    

    //Construye el menú de opciones de cada chat
    @ViewBuilder
    private func MenuOpcionesRespuesta(message: ChatMessage) -> some View {
        HStack(spacing: 20){
            ShareLink("", item: message.text)
            .padding(.leading, 10)
            .id(lastID)
            //Pasar a notas:
            Button{
                if self.notasModel.addNote(nota: message.text, title: "Nota del Chat"){
                    self.alertMessage = "Se ha guardado la respuesta en Notas"
                    self.showAlert = true
                }else{
                    self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                    self.showAlert = true
                }
            }label:{
                Image(systemName: "text.page")
            }
            Button {
                exportChatResponseToPDF(message)
            } label: {
                Image(systemName: "doc.richtext")
            }
            Spacer()
        }
        
        .font(.system(size: 14)).bold()
        
        
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
        
        @Binding var autor : Autores
        
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
                                Task{
                                    model.inputText = sugerencias[index]
                                    await model.sendMessage(autor: self.autor, questionUser: model.inputText)
                                }
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
#Preview {
    NavigationStack {
        ChatView(textoACargar: nil)
    }
}

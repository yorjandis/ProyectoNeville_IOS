//
//  DialogoView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/10/25.
//
//Ventana de chat de IA, recibir concejos y sugerencias relacionadas con las enseñanzas de neville 

import SwiftUI

@available(iOS 26.0, *)
struct ChatView: View {
    
    @StateObject private var model = ChatViewModel()
    
    @State private var  notasModel : NotasModel = NotasModel()
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)  var fontSizeChatIA : Int = 20
    
    @AppStorage(AppCons.UD_setting_AceptacionDescargoIA)    var DescargoDeIA : Bool = false // True permite acceso al chet IA,false prohíbe el acceso al chat de IA
    
    @State private var lastID : UUID? = nil //Para poder desplazar la lista de mensajes en el chat hasta el último siempre
    
    let textoACargar : String?  //Permite cargar una frase o nota  y usarla en el chatIA para entablar una conversación.
    
    
    @FocusState private var focus
    
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    //Colores de IA chat:
    @State var ColorChatIAPrimario         : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_a) ?? .orange.opacity(0.7)
    @State var ColorChatIASecundario       : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_main_b) ?? .brown
    @State var ColorChatIAFuente           : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_colorIA_textContent) ?? .black
    
    var body: some View {
        
        
        if self.DescargoDeIA == false {
            ZStack{
                LinearGradient(colors: [self.ColorChatIAPrimario,  self.ColorChatIASecundario], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
                DescargoResponsabilidadIA(VentanaEnSetting: false)
            }
            
        }else{
            
            ContentMain()
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
                                                        SelectableText(msg.text, fontSize: CGFloat(self.fontSizeChatIA),fonColor: UIColor(self.ColorChatIAFuente) , alignment: .left)
                                                            .padding()
                                                            .background(Color.black.opacity(0.7))
                                                            .cornerRadius(12)
                                                            .frame(
                                                                width: UIScreen.main.bounds.width * 0.8, // cada carácter reduce 5 puntos
                                                                alignment: .trailing
                                                            )
                                                            .id(msg.id)
                                                    }
                                                    
                                                } else {
                                                    VStack{
                                                        SelectableText(msg.text, fontSize: CGFloat(self.fontSizeChatIA),fonColor: UIColor(self.ColorChatIAFuente) , alignment : .left)
                                                            .padding()
                                                            .background(Color.black.opacity(0.5))
                                                            .cornerRadius(12)
                                                        
                                                        MenuOpcionesRespuesta(texto: msg.text)
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
                                AdjustableGridView(rows: 4 , model: self.model)
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
        .navigationTitle("Pregunta  a Neville")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar{
            if self.DescargoDeIA {
                ToolbarItem {
                    Button{
                        withAnimation {
                            self.model.newConversation()
                        }
                        
                        print(self.model.messages.isEmpty ? "No hay mensajes" : "Hay mensajes")
                    }label:{
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("Chat IA"), message: Text(self.alertMessage))
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
                        .tint(.black)
                    Spacer()
                }else{
                    TextField("Escribe algo…", text: $model.inputText, axis: .vertical)
                        .font(.system(size: 20))
                        .disabled(model.isResponding)
                        .padding(.vertical, 8)
                        .padding(.leading, 20)
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.black.opacity(0.8)))
                        .focused(self.$focus)
                    
                    Button{
                        Task {
                            await model.sendMessage()
                            self.focus = false
                        }
                    }label:{
                        Text("Enviar").bold()
                        
                    }
                    .tint(.orange)
                    .foregroundStyle(.black)
                    .buttonStyle(.borderedProminent)
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
    private func MenuOpcionesRespuesta(texto: String) -> some View {
        HStack(spacing: 20){
            ShareLink("", item: texto)
            .padding(.leading, 10)
            .id(lastID)
            //Pasar a notas:
            Button{
                if self.notasModel.addNote(nota: texto, title: "Nota del Chat"){
                    self.alertMessage = "Se ha guardado la respuesta en Notas"
                    self.showAlert = true
                }else{
                    self.alertMessage = "No fue posible guardar la respuesta en Notas. Inténtelo más tarde."
                    self.showAlert = true
                }
            }label:{
                Image(systemName: "text.page")
            }
            Spacer()
        }
        
        .font(.system(size: 14)).bold()
        
        
    }
    
    
    
    
  
//Vista que muestra un menu de opciones
    fileprivate struct AdjustableGridView: View {
        // Número de filas y columnas
        
        @State  var  rows: Int
        @State  var  columns: Int = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2 //Ajusta el No. columnas segun iOS/ipadOS
        
        
        
        @ObservedObject var model: ChatViewModel
        
        
        
        // Ejemplo: 6 botones
        @State private var  buttonTitles = ["Cuenta una fábula",
                            "¿Qué es la conciencia?","Quiero dejar de fumar","¿Qué es la revisión?",
                            "Me siento frustado","¿Cómo manifiesto mis deseos?","¿Cómo debo orar?",
                            "¿Qué es pecar?","Resume tu enseñanza","Dame un concejo","Tengo problemas","¿Quién es el Diablo?",
                            "¿Qué es la ley de creación?","Me pasan cosas malas","¿Cómo aplico tus enseñanzas?",
                            "Buenos días","¿Qué es la vida?","¿Cómo puedo mejorar?", "Quiero cambiar","Estoy estancado",
                            "¿Qué es la realidad?","Háblame del Alfarero"]
        
        // Layout dinámico de columnas
        var gridLayout: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
        }
        
        
        var body: some View {
            VStack(alignment: .leading){
                Text("Sugerencias:").font(.subheadline).padding(.horizontal).foregroundStyle(.primary).bold().id(12)
                    LazyVGrid(columns: gridLayout, spacing: 10) {
                        ForEach(0..<buttonTitles.count, id: \.self) { index in
                            Button(action: {
                                Task{
                                    model.inputText = buttonTitles[index]
                                    await model.sendMessage()
                                }
                            }) {
                                Text(buttonTitles[index])
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






@available(iOS 26.0, *)
#Preview {
    NavigationStack {
        ChatView(textoACargar: nil)
    }
}


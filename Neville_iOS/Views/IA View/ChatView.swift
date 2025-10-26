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
    
    @AppStorage(AppCons.UD_setting_fontChatIASize)  var fontSizeChatIA : Int = 20
    
    var body: some View {
        
        ZStack{
            
            LinearGradient(colors: [.orange.opacity(0.7),  .brown], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack {
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(model.messages) { msg in
                                HStack {
                                    if msg.isUser {
                                        Spacer()
                                        Text(msg.text)
                                            .padding()
                                            .background(Color.blue.opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    } else {
                                        Text(msg.text)
                                            .padding()
                                            .background(Color.black.opacity(0.5))
                                            .cornerRadius(12)
                                            .foregroundStyle(.white)
                                        Spacer()
                                    }
                                }
                                .transition(.opacity)
                                
                                .font(.system(size: CGFloat(fontSizeChatIA)))
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                            
                            BurbujaCarga() //Aparece mientras la IA esta procesando la información

                        }
                        .animation(.easeInOut(duration: 0.20), value: model.messages)
                    }
                    .onChange(of: model.messages.count) {old, new in
                        //Permite correr el scroll para que se muestre el último mensaje
                        if let last = model.messages.last {
                            withAnimation {
                                scrollProxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                
                Promt()
                .padding()
            }
        }
        .navigationTitle("Chat IA")
        .toolbar{
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
    
    
    @ViewBuilder
    func Promt() -> some View {
        VStack{
            if model.messages.isEmpty {
                AdjustableGridView(rows: 3, columns: 3, model: self.model)
            }
            HStack {
                TextField("Escribe un mensaje…", text: $model.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: CGFloat(fontSizeChatIA)))
                    .disabled(model.isResponding)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.ultraThinMaterial))
                    .onSubmit {
                        Task {
                            await model.sendMessage()
                        }
                    }
                Button{
                    Task {
                        await model.sendMessage()
                    }
                }label:{
                    Text("Enviar")
                }
                .buttonStyle(.glass)
                .foregroundStyle(.white)
                .tint(.orange)
                .disabled(model.inputText.trimmingCharacters(in: .whitespaces).isEmpty || model.isResponding)
                
                
            }
        }
        
    }
    
    @ViewBuilder
    func BurbujaCarga() -> some View {
        if model.isResponding {
            HStack {
                LoadingSymbolBubble()
                Spacer()
            }
            .transition(.opacity)
            .font(.system(size: CGFloat(fontSizeChatIA)))
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    // Subview: animated SF Symbol inside assistant-style bubble
    private struct LoadingSymbolBubble: View {
        @State private var bounce: Bool = false

        var body: some View {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .offset(y: bounce ? -5 : 5)
                        .opacity(0.9)
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.4),
                            value: bounce
                        )
                }
            }
            .padding(12)
            .background(Color.black.opacity(0.5))
            .cornerRadius(12)
            .onAppear {
                bounce = true
            }
        }
    }
    
    
    
  

    struct AdjustableGridView: View {
        // Número de filas y columnas
        let rows: Int
        let columns: Int
        
        @ObservedObject var model: ChatViewModel
        
        
        
        // Ejemplo: 6 botones
        let buttonTitles = ["Cuenta una fábula",
                            "Qué es la conciencia?",
                            "Quiero dejar de fumar",
                            "Qué es la revisión",
                            "Me siento frustado",
                            "Como manifiesto mis deseos",
                            "¿Cómo debo orar?",
                            "¿Qué es pecar?",
                            "Resume tu enseñanza"]
        
        // Layout dinámico de columnas
        var gridLayout: [GridItem] {
            Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
        }
        
        var body: some View {
            ScrollView {
                LazyVGrid(columns: gridLayout, spacing: 10) {
                    ForEach(0..<buttonTitles.count, id: \.self) { index in
                        Button(action: {
                            Task{
                                model.inputText = buttonTitles[index]
                                await model.sendMessage()
                            }
                            
                        }) {
                            Text(buttonTitles[index])
                                .frame(maxWidth: .infinity, minHeight: 60)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
        }
    }
    
    
}






@available(iOS 26.0, *)
#Preview {
    NavigationStack {
        ChatView()
    }
}


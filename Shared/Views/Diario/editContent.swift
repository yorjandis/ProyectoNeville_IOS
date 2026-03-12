//
//  editContent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/11/25.
//


import SwiftUI
import CoreData


//View: Editar el contenido de una entrada del diario

struct editContent : View {
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    @StateObject private var diarioModel = DiarioModel.shared
    
    @Binding var diario : Diario
    
    @State  var textTitle : String
    @State  var textContent : String
    @State  var emoticono : Emociones
    var onEntryUpdated: (Date?) -> Void = { _ in }
    
    enum Focustext{
        case title
        case content
    }
    @FocusState private var focus: Focustext?
    
    var body: some View {
        NavigationStack {
            List{
                Section("Título"){
                    HStack(spacing: 5){
                        Menu{
                            ForEach(Emociones.allCases, id: \.self) { emocion in
                                Button {
                                    emoticono = emocion
                                } label: {
                                    HStack {
                                        Text(emocion.rawValue)
                                        Text(emocion.emoji)
                                    }
                                }
                            }
                        }label: {
                            Text(emoticono.emoji)
                                .font(.system(size: 40))
                        }
                        
                        
                        TextField("", text: $textTitle, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .focused(self.$focus, equals: .title)
                            
                    }
                    
                }
                
                Section("Contenido"){
                    
                        TextField("", text: $textContent, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .focused(self.$focus, equals: .content)
                }
                
                
            }
            //Al inicio actualiza el icono de emocion
            .foregroundStyle(theme == .dark ? .white : .black)
            .onAppear{
                emoticono = diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")
            }
            .onChange(of: self.focus) { oldValue, newValue in
               switch newValue {
               case .title:
                   if self.textTitle == "Título"{
                       self.textTitle = ""
                   }
               case .content:
                   if self.textContent == "Nuevo Contenido!" {
                       self.textContent = ""
                   }
               default:
                   self.focus = nil
                }
            }
            .navigationTitle("Modificar Entrada")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                
                #if os(macOS)
                if ventanaActualEsModal(){
                    ToolbarItem(placement: .navigation) {
                        Button{
                            if let windows = NSApp.keyWindow{
                                    closeWindow(windows)
                            }
                            
                        }label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                        
                    }
                }
                
                
                #endif
                
                ToolbarItem {
                    Button(action: {
                        diarioModel.UpdateItem(diario: diario, title: textTitle, content: textContent, emoticono: emoticono)
                        onEntryUpdated(diario.fecha)
                        dimiss()
                    }) {
                        Text("Guardar")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Color.blue
                            )
                            .clipShape(Capsule())
                            .compositingGroup()

                    }
                    .buttonStyle(PlainButtonStyle())
                    .tint(.clear)
                }
                
                
            }
        }
    }
}

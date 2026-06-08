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
    @State  var direccionMapa : String
    @State  var emoticono : Emociones
    @StateObject private var locationCapture = AgendaLocationCapture()
    @State private var isCapturingLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    var onEntryUpdated: (Date?) -> Void = { _ in }
    
    enum Focustext{
        case title
        case content
    }
    @FocusState private var focus: Focustext?

    private func closeEditorView() {
#if os(macOS)
        if let window = NSApp.keyWindow {
            closeWindow(window)
            return
        }
#endif
        dimiss()
    }
    
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
                        .menuStyle(.borderlessButton)
                        .buttonStyle(.plain)
                        
                        
                        TextField("", text: $textTitle, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .focused(self.$focus, equals: .title)
                            
                    }
                    
                }
                
                Section("Contenido"){
                    TextEditor(text: $textContent)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.black.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                        )
                        .frame(minHeight: 220)
                        .focused(self.$focus, equals: .content)
                }

                Section("Dirección (Mapas)") {
                    HStack(spacing: 8) {
                        if isCapturingLocation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            TextField("Ej: Gran Vía 1, Madrid", text: $direccionMapa, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button {
                            isCapturingLocation = true
                            locationCapture.captureCurrentAddress { result in
                                isCapturingLocation = false
                                switch result {
                                case .success(let address):
                                    direccionMapa = address
                                case .failure(let error):
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        } label: {
                            Label("Ubicación actual", systemImage: "location.fill")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingLocation)
                    }
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
                ToolbarItem(placement: .cancellationAction) {
                    Button{
                        closeEditorView()
                    }label:{
                        Text("Cancelar")
                            .fontWeight(.semibold)
                            .frame(width: 80)
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                    
                }

                #if os(macOS)
                if ventanaActualEsModal(){
                    ToolbarItem(placement: .navigation) {
                        Button {
                            closeEditorView()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                
                #endif
                
                ToolbarItem {
                    Button(action: {
                        diarioModel.UpdateItem(diario: diario, title: textTitle, content: textContent, emoticono: emoticono, direccionMapa: direccionMapa)
                        onEntryUpdated(diario.fecha)
                        closeEditorView()
                    }) {
                        Text("Guardar")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
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
            .alert("Ubicación", isPresented: $showAlert) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
}

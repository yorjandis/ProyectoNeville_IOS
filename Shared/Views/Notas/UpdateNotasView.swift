//
//  UpdateNotasView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 5/10/23.
//Actualiza el contenido de una nota y recarga el listado de notas

import SwiftUI
import CoreData

struct UpdateNotasView: View {
    @Environment(\.dismiss) var dimiss
    @EnvironmentObject var modelNotas : NotasModel
    
    let NotaId : String //Id de la nota a actualizar
    @State var title : String
    @State var categoria : String
    @State var nota : String
    @State var direccionMapa : String
    @State var isChecklist: Bool = false
    @State var checklistItems: [NotaChecklistItem] = []
    @StateObject private var locationCapture = AgendaLocationCapture()
    @State private var isCapturingLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    
    var body: some View {
        NavigationStack {
            Divider()
            Form{
                Section("Título"){
                    TextField("", text: $title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    
                }
                Section("Categoría"){
                    HStack {
                        TextField("Sin categoría", text: $categoria, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                        Menu {
                            Button("Sin categoría") {
                                categoria = ""
                            }
                            ForEach(existingCategories, id: \.self) { category in
                                Button(category) {
                                    categoria = category
                                }
                            }
                        } label: {
                            Image(systemName: "folder")
                        }
                        .disabled(existingCategories.isEmpty)
                    }
                }
                Section("Tipo"){
                    Picker("Tipo de nota", selection: $isChecklist) {
                        Label("Texto", systemImage: "text.alignleft").tag(false)
                        Label("Checklist", systemImage: "checklist").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isChecklist) { _, newValue in
                        if newValue && checklistItems.isEmpty {
                            checklistItems = NotaChecklistItem.fromText(nota)
                        }
                    }
                }
                Section(isChecklist ? "Checklist" : "Nota"){
                    if isChecklist {
                        NotaChecklistEditor(items: checklistBinding)
                    } else {
                        TextEditor(text: $nota)
                                .font(.system(size: 22))
                                .frame(minHeight: 150)
                                .scrollContentBackground(.hidden)
                                .background(.black.opacity(0.02))
                                .cornerRadius(8)
                    }
                }
                Section("Coordenadas (Mapas)") {
                    HStack(spacing: 8) {
                        if isCapturingLocation {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            TextField("Ej: 40.416775,-3.703790", text: $direccionMapa, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button {
                            isCapturingLocation = true
                            locationCapture.captureCurrentAddress { result in
                                isCapturingLocation = false
                                switch result {
                                case .success(let coordinates):
                                    direccionMapa = coordinates
                                case .failure(let error):
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        } label: {
                            Label {
                                Text("Coordenadas actuales")
                            } icon: {
                                Image(systemName: direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "location.fill" : "checkmark.circle.fill")
                                    .foregroundStyle(direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.primary : Color.green)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCapturingLocation)
                    }
                }
            }
            .navigationTitle("Actualizar una Nota")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    Button("Actualizar"){
                        let items = sanitizedChecklistItems
                        let noteText = isChecklist ? NotaChecklistItem.renderPlainText(items) : nota
                        if NotasModel().updateNota(NotaID: NotaId, newTitle: title, newNota: noteText, direccionMapa: direccionMapa, categoria: categoria, isChecklist: isChecklist, checklistItems: items){
                            self.modelNotas.getAllNotasToModel()
                            
                            
                            
                        }else{
                            msg("Error al actualizar la nota")
                        }
                        
                        //Saliendo de la ventana
                        if let windows = NSApp.keyWindow{
                            if ventanaActualEsModal(){
                                closeWindow(windows)
                            }
                        }

                    }
                }
                
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
                
                
                
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Actualizar"){
                        let items = sanitizedChecklistItems
                        let noteText = isChecklist ? NotaChecklistItem.renderPlainText(items) : nota
                        if NotasModel().updateNota(NotaID: NotaId, newTitle: title, newNota: noteText, direccionMapa: direccionMapa, categoria: categoria, isChecklist: isChecklist, checklistItems: items){
                            self.modelNotas.getAllNotasToModel()
                        }else{
                            msg("Error al actualizar la nota")
                        }
                        dimiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                        Button{
                            dimiss()
                        }label: {
                            Text("Cancelar")
                                .foregroundStyle(.red)
                        }
                }
                #endif
            }
            .alert("Ubicación", isPresented: $showAlert) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        
    }

    private var existingCategories: [String] {
        Array(Set(modelNotas.notas.compactMap { nota in
            let value = (nota.value(forKey: "categoria") as? String ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }))
        .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var checklistBinding: Binding<[NotaChecklistItem]> {
        Binding {
            checklistItems.isEmpty ? [NotaChecklistItem(text: "")] : checklistItems
        } set: { newValue in
            checklistItems = newValue
        }
    }

    private var sanitizedChecklistItems: [NotaChecklistItem] {
        checklistItems
            .map {
                NotaChecklistItem(
                    id: $0.id,
                    text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    isChecked: $0.isChecked
                )
            }
            .filter { !$0.text.isEmpty }
    }

}

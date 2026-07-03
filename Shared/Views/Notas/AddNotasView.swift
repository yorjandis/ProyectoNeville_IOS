//
//  AddNotasView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 2/10/23.
//
//Views Permite adicionar una nota a la BD

import SwiftUI
import CoreData

struct AddNotasView: View {
    @Environment(\.dismiss) var dimiss
    
    @EnvironmentObject private var modelNotas : NotasModel
    
    @State      var title : String = ""
    @State      var categoria : String = ""
    @State      var nota : String = ""
    @State      var direccionMapa: String = ""
    @State private var isChecklist = false
    @State private var checklistItems: [NotaChecklistItem] = [NotaChecklistItem(text: "")]
    @StateObject private var locationCapture = AgendaLocationCapture()
    @State private var isCapturingLocation = false

    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        NavigationStack {
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
                }
                Section(isChecklist ? "Checklist" : "Nota"){
                    if isChecklist {
                        NotaChecklistEditor(items: $checklistItems)
                    } else {
                        TextEditor(text: $nota)
                            .font(.system(size: 22))
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
                            .frame(height: 250)
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
            #if os(macOS)
            .frame(width: 600, height: 400)
            #endif
            .navigationTitle("Adicionar una nota")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    Button("Guardar"){
                        let items = sanitizedChecklistItems
                        let noteText = isChecklist ? NotaChecklistItem.renderPlainText(items) : nota
                        if NotasModel().addNote(nota: noteText, title: title, isFav: false, direccionMapa: direccionMapa, categoria: categoria, isChecklist: isChecklist, checklistItems: items) {
                            
                            self.modelNotas.getAllNotasToModel() //Actualizando el listado
                            
                            if FeedBackModel.checkReviewRequest() {
                            
                                showWindow(for: FeedbackView(showTextBotton: false),
                                           environmentObjects: [],
                                           title: "Enviar una Reseña a la App Store",
                                           size: AppCons.windows_size_content_small,
                                           isModal: true
                                )
                            
                                
                            }
                            
                        }else{
                            self.alertMessage = "No se pudo guardar la nota"
                            self.showAlert = true
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
                    Button("Guardar"){
                        let items = sanitizedChecklistItems
                        let noteText = isChecklist ? NotaChecklistItem.renderPlainText(items) : nota
                        if NotasModel().addNote(nota: noteText, title: title, isFav: false, direccionMapa: direccionMapa, categoria: categoria, isChecklist: isChecklist, checklistItems: items) {
                            
                            self.modelNotas.getAllNotasToModel()
                            
                            if FeedBackModel.checkReviewRequest() {
                                self.sheetShowFeedBackReview = true
                            }else{
                                dimiss()
                            }
                            
                        }else{
                            self.alertMessage = "No se pudo guardar la nota"
                            self.showAlert = true
                        }
                        
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button{ dimiss()}label: {
                        Text("Cancelar")
                            .foregroundStyle(.red)
                    }
                }
                #endif
            }
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                FeedbackView(showTextBotton: true)
            }
            .alert(isPresented: self.$showAlert){
                Alert(title: Text("Adicionar una nota"), message: Text(self.alertMessage))
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

struct NotaChecklistEditor: View {
    @Binding var items: [NotaChecklistItem]

    var body: some View {
        VStack(spacing: 8) {
            ForEach($items) { $item in
                HStack(spacing: 10) {
                    Button {
                        item.isChecked.toggle()
                    } label: {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)

                    TextField("Elemento", text: $item.text, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        remove(item)
                    } label: {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .disabled(items.count == 1)
                }
            }

            Button {
                items.append(NotaChecklistItem(text: ""))
            } label: {
                Label("Añadir elemento", systemImage: "plus.circle")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func remove(_ item: NotaChecklistItem) {
        guard items.count > 1 else { return }
        items.removeAll { $0.id == item.id }
    }
}

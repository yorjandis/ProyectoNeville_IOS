//
//  AddNota.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 8/2/24.
//

import Foundation
import SwiftUI
import CoreData
import CoreLocation


struct AddNota : View {
    
    private let context : NSManagedObjectContext = CoreDataController.shared.context
    @Environment(\.dismiss) private var dismiss
    @State private var title : String = ""
    @State private var categoria : String = ""
    @State private var texto : String = ""
    @State private var isfav : Bool = false
    @State private var showAlert = false
    @State private var alertMesage = ""
    @State private var isWorking = false
    @StateObject private var locationCapture = WatchLocationCapture()
    @State private var direccionMapa: String = ""
    @State private var isResolvingLocation = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 10){
                Text("Nueva Nota")
                    .foregroundStyle(.orange).bold()
                    .padding(.top, 5)
                Divider()
                    .padding(.top, 20)
                ScrollView{
                    
                    TextFieldLink("título: \(title)", prompt: Text("Título de nota")) { str in
                        title = str
                    }
                    .frame(width: .infinity ,  height: 40)
                    .cornerRadius(20)
                    .padding([.leading, .trailing], 5)
                    
                    TextFieldLink("Nota: \(texto)", prompt: Text("Título de nota")) { str in
                        texto = str
                    }
                    .frame(width: .infinity ,  height: 40)
                        .cornerRadius(20)
                        .padding([.leading, .trailing], 5)

                    TextFieldLink("Categoría: \(categoria)", prompt: Text("Categoría")) { str in
                        categoria = str
                    }
                    .frame(width: .infinity ,  height: 40)
                    .cornerRadius(20)
                    .padding([.leading, .trailing], 5)
                    
                    
                    Toggle(isOn: $isfav, label: {
                        Text("Favorito")
                    })
                    .padding(.horizontal, 10)

                    Button {
                        attachCurrentLocation()
                    } label: {
                        if isResolvingLocation {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "location" : "checkmark.circle.fill")
                                    .foregroundStyle(direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.black : Color.green)
                                Text("Añadir coordenadas")
                                    .foregroundStyle(.black)
                            }
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 10)
                    .disabled(isResolvingLocation)
                    .buttonStyle(.bordered)

                    if !direccionMapa.isEmpty {
                        Text(direccionMapa)
                            .font(.system(size: 11))
                            .lineLimit(2)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                    }
                    
                    Button{
                        Task{
                            if title.isEmpty || texto.isEmpty {
                                self.alertMesage = "Debe colocar un titulo y un texto para la nota" ; showAlert = true
                            }else{
                                //Crear una entidad Nota
                                let newNota = Notas(context: self.context)
                                let now = Date()
                                let noteID = UUID().uuidString
                                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedCategory = categoria.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedText = texto.trimmingCharacters(in: .whitespacesAndNewlines)
                                let trimmedAddress = direccionMapa.trimmingCharacters(in: .whitespacesAndNewlines)
                                newNota.id = noteID
                                newNota.title = trimmedTitle
                                newNota.setValue(trimmedCategory, forKey: "categoria")
                                newNota.nota = trimmedText
                                newNota.isfav = isfav
                                newNota.setValue(trimmedAddress, forKey: "direccionMapa")
                                newNota.setValue(now, forKey: "fechaCreacion")
                                newNota.setValue(now, forKey: "fechaModificacion")
                                
                                do {
                                    try self.context.save()
                                    WatchNotesTransferSender.shared.sendCreatedNote(
                                        WatchNoteTransferPayload(
                                            id: noteID,
                                            title: trimmedTitle,
                                            nota: trimmedText,
                                            categoria: trimmedCategory,
                                            direccionMapa: trimmedAddress,
                                            isfav: isfav,
                                            fechaCreacion: now,
                                            fechaModificacion: now
                                        )
                                    )
                                    self.alertMesage = "Nota Creada"
                                    self.showAlert = true
                                    
                                }catch{
                                    self.context.rollback()
                                    self.alertMesage = "Error al Crear Nota"
                                    self.showAlert = true
                                    
                                }
                                
                                dismiss()
                                
                            }
                             
                        }
                        
                    }label: {
                        Label("Guardar", systemImage: "plus")
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(self.isWorking ? 0 : 1)
                    .overlay(content: { if self.isWorking { ProgressView() }
                    })
                    .padding([.horizontal, .vertical])
                    .buttonStyle(PlainButtonStyle())
                }
               
                   
            }
            
        }
        .ignoresSafeArea()
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Notas"), message: Text(self.alertMesage))
        })
        
    }

    private func attachCurrentLocation() {
        isResolvingLocation = true
        locationCapture.captureCurrentAddress { result in
            isResolvingLocation = false
            switch result {
            case .success(let coordinates):
                direccionMapa = coordinates
                if texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    texto = coordinates
                }
            case .failure(let error):
                alertMesage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    AddNota()
}

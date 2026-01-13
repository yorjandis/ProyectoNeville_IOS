//
//  RowFraseMenu.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 13/1/26.
//

//Solo para macOS

#if os(macOS)

import SwiftUI
import CoreData

struct RowFraseMenu: View {

     let frase: Frases
     @ObservedObject var frasesModel: FrasesModel
     @ObservedObject var settingModel: SettingModel
     
     @State private var showConfirmDialogDeleteFrase = false
     
     //Alert
     @State private var showAlert: Bool = false
     @State private var alertMessage: String = ""
     
     // Cache de valores precalculados
     private let coreData: Frases?
     private let isFav: Bool
     private let esNoInbuilt: Bool
     private let iaDisponible: Bool
     
     /// Inicialización para evitar trabajo en body
     init(frase: Frases,
          frasesModel: FrasesModel,
          settingModel: SettingModel)
     {
         self.frase = frase
         self.frasesModel = frasesModel
         self.settingModel = settingModel
         
         // Cache de valores
         self.coreData = frasesModel.getFraseCoreData(FraseID: frase.id ?? "")
         self.isFav = frasesModel.isFavFrase(fraseID: frase.id ?? "")
         self.esNoInbuilt = frasesModel.isNoInbuilt(fraseID: frase.id ?? "") ?? true
         
         if #available(iOS 26.0, macOS 26.0, *) {
             self.iaDisponible = IAModelAppleIntelligence.isAvailable()
         } else {
             self.iaDisponible = false
         }
     }
     
     var body: some View {
         
         Menu(""){
             // Editar
             if esNoInbuilt {
                 Button {
                     if let core = coreData {
                         
                          showWindow(
                              for: FrasesUpdateView(frase: core),
                              environmentObjects: [frasesModel],
                              title: "Frases",
                              size: AppCons.windows_size_content_small,
                              isModal: true
                          )
                          
                         
                     }
                 } label: {
                     Label("Editar Frase", systemImage: "square.and.pencil")
                         .tint(.green)
                 }
             }
             
             // Notas
             Button {
                 
                  showWindow(
                      for: FrasesNotasAddView(frase: frase),
                      environmentObjects: [frasesModel],
                      title: "Frases",
                      size: AppCons.windows_size_content_small,
                      isModal: true
                  )
                  
                 
             } label: {
                 Label("Notas", systemImage: "bookmark")
                     .tint(.green)
             }
             
             // Favorito
             Button {
                 
                  let nuevoValor = !isFav
                  if frasesModel.setFavFrase(fraseID: frase.id ?? "", nuevoValor) {
                      Task {
                          await frasesModel.FiltrarListado()
                      }
                  }
                  
                 
             } label: {
                 Label("Favorito", systemImage: "heart.fill")
                     .tint(.gray)
             }
             
             // QR
             Button {
                 
                  showWindow(
                      for: GenerateQRView(footer: frase.frase ?? ""),
                      environmentObjects: [frasesModel],
                      title: "Frases",
                      size: AppCons.windows_size_content,
                      isModal: false
                  )
                  
                 
             } label: {
                 Label("Generar QR", systemImage: "qrcode")
                     .tint(.brown)
             }
             
             //Guardar Frases en Notas
             //Guardar la frase a Notas
             Button{
                 
                  //Guarda la nota poniendo como titulo una parte de la cadena
                 if NotasModel().addNote(
                     nota: frase.frase ?? "",
                     title: "\(String((frase.frase ?? "").prefix((frase.frase ?? "").count / 3)))..."
                 ) {
                     // acción si addNote devuelve true
                     self.alertMessage = "Frase almacenada en Notas"
                     self.showAlert = true
                 }
                 
                  
                 
             }label: {
                 Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
             }
             
             
             //Compartir la frase
             
             ShareLink(item: frase.frase ?? "") {
                             Label("Compartir frase", systemImage: "square.and.arrow.up")
                         }
             
             Button{
                 
                  showWindow(for: LienzoMain(texto: frase.frase ?? ""),
                             environmentObjects: [],
                             title: "Lienzo",
                             size: .absolute(CGSize(width: 650, height: 750)),
                             isModal: false
                  )
                  
                 
                 
             }label:{
                 Label("Lienzo", systemImage: "heart.text.square")
             }
             
             
             
             // Inteligencia Artificial
             if #available(iOS 26.0, macOS 26.0, *){
                 if iaDisponible {
                     
                     Button {
                         
                          showWindow(
                              for: RespondView(
                                  nameConference: "",
                                  texto: frase.frase ?? "",
                                  tipoSalida: .interpretar
                              ),
                              environmentObjects: [frasesModel, settingModel],
                              title: "Interpretar",
                              size: AppCons.windows_size_content,
                              isModal: true,
                              isIAWindows: true
                          )
                          
                         
                     } label: {
                         Label("Interpretar", systemImage: "sparkles")
                     }
                     .tint(.purple)
                     
                     
                     Button {
                         
                          showWindow(
                              for: RespondView(
                                  nameConference: "",
                                  texto: frase.frase ?? "",
                                  tipoSalida: .practicaConcreta
                              ),
                              environmentObjects: [frasesModel, settingModel],
                              title: "Aplicación Práctica",
                              size: AppCons.windows_size_content,
                              isModal: true,
                              isIAWindows: true
                          )
                          
                         
                     } label: {
                         Label("Aplicación Práctica", systemImage: "sparkles")
                     }
                     .tint(.purple)
                     
                     
                     Button {
                         
                          showWindow(
                              for: ChatView(textoACargar: frase.frase ?? ""),
                              environmentObjects: [frasesModel, settingModel],
                              title: "Charlar con la IA",
                              size: AppCons.windows_size_content,
                              isModal: false,
                              isIAWindows: true
                          )
                          
                         
                     } label: {
                         Label("Charlar con la IA", systemImage: "sparkles")
                     }
                     .tint(.purple)
                 }
             }
             
             
             
             // Eliminar
             if esNoInbuilt {
                 Button(role: .destructive) {
                     showConfirmDialogDeleteFrase = true
                 } label: {
                     Label("Eliminar", systemImage: "minus.circle.fill")
                         .tint(.red.opacity(0.8))
                 }
             }
         }
         .frame(width: 15)
         .padding(.trailing, 5)
         .confirmationDialog(
             "Confirme que desea Eliminar la Frase",
             isPresented: $showConfirmDialogDeleteFrase
         ) {
             Button("Eliminar", role: .destructive) {
                 eliminarFrase()
             }
         } message: {
             Text("La nota será removida!!!")
         }
         .alert(isPresented: self.$showAlert){
             Alert(title: Text("La Ley"), message: Text(self.alertMessage))
         }
         
         
        
         
     }
     
     
     // MARK: - Funciones internas (sin extensiones)
     private func eliminarFrase() {
         
          withAnimation {
              if frasesModel.DeleteFraseInbuilt(fraseID: frase.id ?? "") {
                  Task {
                      frasesModel.criterioFiltroActual = .FrasesPersonales
                      await frasesModel.FiltrarListado()
                  }
              }
          }
          
            
     }
     
 }


#endif

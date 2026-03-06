//
//  TextoCopiadoView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/12/25.
//

import SwiftUI


struct TextoCopiadoView: View {
    
    @ObservedObject var clipBoardModel : ClipboardObserver
    //@StateObject private var purchaseModel : PurchaseManager = .shared
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    let  nameTxt : String?  //Nombre del fichero txt
    
    //Alertas:
    @Binding var showAlert : Bool
    @Binding var alertMessage : String
    
    //Item del menu
    @Binding var showSheetTextoCopiadoAlPortapapelesParaInterpretar : TextoCopiadoAlPortapapeles?
    @Binding var showSheetTtextoCopiadoAlPortapapelesParaChatIA : TextoCopiadoAlPortapapeles?
    @Binding var showSheetTtextoCopiadoAlPortapapelesParaLienzo : TextoCopiadoAlPortapapeles?
    
 
    var body: some View {
        
        if (self.purchaseStatus || self.yorjPremium) {
            Menu{
                Label("Texto copiado a: ", systemImage: "info.circle")
                .tint(.gray)
                
                Button{
                    
                    if let texto = self.clipBoardModel.clipboardText {
                        if NotasModel().addNote(nota: texto, title: "Nota de conferencia:\(self.nameTxt ?? "")", isFav: false){
                            self.alertMessage = "Se ha guardado el texto en Notas"
                            self.showAlert = true
                        }
                    }
                    
                    
                    
                }label:{
                    Label("Notas", systemImage: "square.on.square.dashed")
                }
                
                Button{
                    if let texto = self.clipBoardModel.clipboardText {
                        
                        if FrasesModel.shared.AddFrase(frase: texto, autor: "personal"){
                            self.alertMessage = "Se ha guardado el texto en Frases"
                            self.showAlert = true
                        }
                    }
                }label:{
                    Label("Frases", systemImage: "square.on.square.dashed")
                }
                
                Button{
                    #if os(macOS)
                    
                    if let texto = self.clipBoardModel.clipboardText{
                        showWindow(for: LienzoMain(texto: texto, imagenPrimariaACargar: nil),
                        environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false
                        )
                    }
                    #else
                    if let texto = self.clipBoardModel.clipboardText{
                        self.showSheetTtextoCopiadoAlPortapapelesParaLienzo = TextoCopiadoAlPortapapeles(texto: texto)
                    }
                    
                    #endif
                }label:{
                    Label("Lienzo", systemImage: "heart.text.square")
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    Button{
                        #if os(macOS)
                        if let texto = NSPasteboard.general.string(forType: .string){
                            showWindow(for: RespondView(nameConference: "", texto: texto, tipoSalida: .interpretar, autorRespuesta: "nev"),
                                       environmentObjects: [],
                                       title: "Interpretar texto",
                                       size: AppCons.windows_size_content,
                                       isModal: false)
                        }
                        #else
                        if let texto = self.clipBoardModel.clipboardText{
                            self.showSheetTextoCopiadoAlPortapapelesParaInterpretar = TextoCopiadoAlPortapapeles(texto: texto)
                        }
                        
                        #endif
                    }label:{
                        Label("Interpretar", systemImage: "sparkles")
                    }
                    .tint(.orange)
                    .help("Interpreta el texto copiado en el portapapeles con la IA")
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    Button{
                        #if os(macOS)
                        if let texto = NSPasteboard.general.string(forType: .string) {
                            showWindow(for: ChatView(textoACargar: texto),
                                       environmentObjects: [],
                                       title: "ChatIA - Interpretar texto",
                                       size: AppCons.windows_size_content,
                                       isModal: false)
                        }
                        #else
                        Task{
                            if let clipBoardText = self.clipBoardModel.clipboardText{
                                self.showSheetTtextoCopiadoAlPortapapelesParaChatIA = TextoCopiadoAlPortapapeles(texto: clipBoardText)
                            }
                        }
                       
                        #endif
                    }label:{
                        Label("ChatIA", systemImage: "sparkles")
                    }
                    .tint(.orange)
                    .help("Permite charlar con la IA sobre el texto copiado al potapaepeles")
                }
            }label: {
                Label("Texto Copiado a: ", systemImage: "rectangle.fill.on.rectangle.fill.circle.fill")
            }
            .tint(.green)
        }else{
            Menu{
                Label("Texto copiado a: ", systemImage: "info.circle")
                .tint(.gray)
                
                Button{
                    alertMessage = "Se requiere una suscripción Premium. Vaya a Ajustes -> última opción"
                    showAlert = true
                }label:{
                    Label("Notas", systemImage: "square.on.square.dashed")
                }
                
                Button{
                    alertMessage = "Se requiere una suscripción Premium. Vaya a Ajustes -> última opción"
                    showAlert = true
                }label:{
                    Label("Frases", systemImage: "square.on.square.dashed")
                }
                
                Button{
                    alertMessage = "Se requiere una suscripción Premium. Vaya a Ajustes -> última opción"
                    showAlert = true
                }label:{
                    Label("Lienzo", systemImage: "heart.text.square")
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    Button{
                       alertMessage = "Se requiere una suscripción Premium. Vaya a Ajustes -> última opción"
                        showAlert = true
                    }label:{
                        Label("Interpretar", systemImage: "sparkles")
                    }
                    .tint(.orange)
                    .help("Interpreta el texto copiado en el portapapeles con la IA")
                }
                
                if #available(iOS 26.0, macOS 26.0, *) {
                    Button{
                        alertMessage = "Se requiere una suscripción Premium"
                        showAlert = true
                    }label:{
                        Label("ChatIA", systemImage: "sparkles")
                    }
                    .tint(.orange)
                    .help("Permite charlar con la IA sobre el texto copiado al potapaepeles")
                }
            }label: {
                Label("Texto Copiado a: ", systemImage: "rectangle.fill.on.rectangle.fill.circle.fill")
            }
            .tint(.green)
            
        }
   
    }
}

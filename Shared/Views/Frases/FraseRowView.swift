//
//  FraseRowView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 2/2/26.
//

//Representa una fila de la lista de frases

import SwiftUI
import CoreData


struct FraseRowView: View {
    
    @ObservedObject var frase: Frases
    @Environment(\.managedObjectContext) private var context
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @Binding var showTabViewFrasesRelac : Bool
    @Binding var fraseRelacionadaMain : Frases?
    
    @State private var showAlert: Bool = false
   
    @State private var alertMessage: String = ""
    
    @State private var FraseAEliminar : Frases? = nil
    @State private var showConfirmDialogDeleteFrase: Bool = false

    
    var body: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading){
                #if os(macOS)
                //Vista de listado de Frases desde macOS, con un Menu al principio de cada frase
                HStack{
                    RowFraseMenu(frase: frase , frasesModel: FrasesModel.shared, settingModel: SettingModel(),showTabViewFrasesRelac: self.$showTabViewFrasesRelac, fraseRelacionadaMain: self.$fraseRelacionadaMain )
                    
                    
                    //Mostrar Un icono de favorito si la frase es favorita
                    if frase.isfav {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                    }
                    VStack(alignment: .leading ,spacing: 2){
                        Text(frase.frase ?? "")
                            .font(.system(size: 22))
                            .fontDesign(.serif)
                            .foregroundStyle(.black).bold()
                            .textSelection(.enabled)
                            .padding(.vertical, 15)
                        HStack{
                            Text(frase.autor ?? "").font(.footnote).italic()
                            Spacer()
                            if !frase.relacionadasArray.isEmpty{
                                Button{
                                    self.fraseRelacionadaMain = frase
                                    self.showTabViewFrasesRelac = true
                                }label:{
                                    Image(systemName: "personalhotspot")
                                        .font(.footnote)
                                }
                            }
                            
                        }
                    }
                    
                    
                    Spacer()

                }

                #else
                VStack( alignment: .leading , spacing: 2){
                    
                    Text(frase.frase ?? "")
                        .font(.system(size: 20))
                        .textSelection(.enabled)
                    HStack{
                        Text(frase.autor ?? "").font(.footnote).italic()
                        Spacer()
                        
                        if !frase.relacionadasArray.isEmpty{
                             Button{
                                 self.fraseRelacionadaMain = frase
                                 self.showTabViewFrasesRelac = true
                             }label:{
                                 Image(systemName: "personalhotspot")
                                     .font(.footnote)
                             }
                         }
                    }
                }
                //SelectableText(frase) //No funciona, no se ve el texto de la frase. Puede ser porque esta embebido en una List
                #endif
                
            }
            #if os(iOS) || os(ipadOS)
            //Modificar el campo nota de una frase
            .swipeActions(edge: .leading, allowsFullSwipe: true){
                //Esta View no se mostrará si Apple Intelligence no esta disponible
                if #available(iOS 26.0, macOS 26.0,  *) {
                    if IAModelAppleIntelligence.isAvailable() {
                        Menu{
                            NavigationLink{
                                RespondView(nameConference: "", texto: frase.frase ?? "", tipoSalida: .interpretar, autorRespuesta: frase.autor ?? "nev" )
                            }label:{
                                Label("Interpretar", systemImage: "sparkles")
                            }
                            .tint(.orange)
                            
                            NavigationLink{
                                RespondView(nameConference: "", texto: frase.frase ?? "", tipoSalida: .practicaConcreta, autorRespuesta: frase.autor ?? "nev")
                            }label:{
                                Label("Aplicación Práctica", systemImage: "sparkles")
                            }
                            .tint(.orange)
                            
                            NavigationLink{
                                ChatView(textoACargar: frase.frase ?? "")
                            }label: {
                                Label("Charlar con IA", systemImage: "sparkles")
                            }
                            .tint(.orange)
                            
                        }label:{
                            Image(systemName: "sparkles")
                        }
                        .tint(.purple)
                    }
                }
                //Notas de la Frase
                NavigationLink{
                     FrasesNotasAddView( frase: frase)
                }label: {
                    Image(systemName: "bookmark")
                        .tint(.green)
                }
                
                //Guardar la frase a Notas
                Button{
                    
                     //Guarda la nota poniendo como titulo una parte de la cadena
                    if  NotasModel().addNote(nota: frase.frase ?? "", title: "\(String(frase.frase ?? "").prefix((frase.frase ?? "").count / 3 )))..."){
                         self.alertMessage = "Frase almacenada en Notas"
                         self.showAlert = true
                     }
                     
                    
                }label: {
                    Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
                }
                
                //Compartir la frase:
                ShareLink(item: frase.frase ?? "") {
                                Label("Compartir frase", systemImage: "square.and.arrow.up")
                            }
                
                //Si la Frase es personal, permite eliminarla
                if frase.noinbuilt == true{
                    Button{
                        self.FraseAEliminar = frase
                        self.showConfirmDialogDeleteFrase = true
                    }label:{
                        Image(systemName: "minus.circle.fill")
                            .tint(.red.opacity(0.8))
                    }
                }
               
                
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true){
                
                //Menú de opciones para frases Relacionadas:
                
                    Menu{
                        
                        if (self.purchaseStatus || self.yorjPremium){
                            if (self.showTabViewFrasesRelac && self.frase != self.fraseRelacionadaMain && self.fraseRelacionadaMain != nil) {
                                 Button{
                                     frase.vincularCon(self.fraseRelacionadaMain!)
                                     //Persistiendo
                                     FrasesModel.shared.guardarCambios()
                                 }label:{
                                     Label("Agregar Frase", systemImage: "tray.and.arrow.up.fill")
                                         .tint(.purple)
                                 }
                             }

                             //Modo edición de frases relacionadas
                             Button{
                                 self.fraseRelacionadaMain = frase
                                 self.showTabViewFrasesRelac = true
                             }label:{
                             Label("Frases Relacionadas", systemImage: "graduationcap.circle")
                                 .tint(.blue)
                             }

                            //Mostrar/Ocultar el ponel de frases relacionadas
                            if frase.relacionadasArray.count > 0 {
                                NavigationLink{
                                    FrasesMainListRelacionadas(fraseMain: frase)
                                }label:{
                                    Label("Modo Lista", systemImage: "append.page")
                                        .tint(.blue)
                                }
                            }
                        }else{
                            Button{
                                self.alertMessage = "Las Frases Relacionadas están disponibles en la Versión Extendida"
                                self.showAlert = true
                            }label:{
                                Label("Frases Relacionadas", systemImage: "graduationcap.circle")
                                    .tint(.blue)
                            }
                        }
                        
                        
                        
                         

                    }label:{
                        Image(systemName: "graduationcap.circle")
                            .tint(.blue)
                    }
               
                 
                 

                //Editar la frase: Solo si es Personal
                
                    if frase.noinbuilt == true{
                        NavigationLink{
                            FrasesUpdateView(frase: frase)
                        }label:{
                            Image(systemName: "square.and.pencil")
                                .tint(.green)
                        }
                    }
                
                
                //Generando el QR de la frase
                NavigationLink{
                    GenerateQRView(footer: frase.frase ?? "")
                }label: {
                    Image(systemName: "qrcode")
                        .tint(.brown)
                }
                
                //Lienzo
                NavigationLink{
                    LienzoMain(texto: frase.frase ?? "", imagenPrimariaACargar: LienzoModel.getImagenAutor(autor: self.frase.autor ?? ""))
                }label: {
                    Image(systemName: "heart.text.square")
                        .tint(.brown)
                }
                
                //Ajustar el estado de favorito de una frase
                Button {
                    frase.isfav.toggle()
                    do{
                        if context.hasChanges{
                            try context.save()
                            if FrasesModel.shared.criterioFiltroActual == .FrasesFavoritas {
                                withAnimation {
                                    FrasesModel.shared.listfrases.removeAll{$0.id == frase.id}
                                }
                                
                            }
                        }
                    }catch{
                        msg("Error al guardar el estado del favorito de una frase")
                    }
                } label: {
                    Image(systemName: frase.isfav ? "heart.fill" : "heart")
                        .tint(frase.isfav ? .orange : .gray)
                }
                
                //Información de la Frase:
                Button{
                    self.alertMessage = """
                        Autor: \(frase.getNameAutor)  
                        Contextos: \n - \((frase.contextosArray.map{$0.nombre ?? ""}).joined(separator: "\n- "))
                        """
                    self.showAlert = true
                }label: {
                    Label("", systemImage: "info.circle")
                }
                
                
                
            }
            #endif
        }
        .confirmationDialog(
            "Confirme que desea Eliminar la Frase",
            isPresented: $showConfirmDialogDeleteFrase
        ) {
            Button("Eliminar", role: .destructive) {
                if let fraseTemp = self.FraseAEliminar{
                    withAnimation {
                        FrasesModel.shared.eliminarFrase(fraseTemp)
                    }
                    self.FraseAEliminar = nil
                }
               
                
            }
        } message: {
            Text("La frase será removida!!!")
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("La Ley"), message: Text(self.alertMessage))
        }
    }
}

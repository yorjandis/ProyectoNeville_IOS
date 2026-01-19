//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

fileprivate enum TipeViewOptionTab : String,  Identifiable{
    case notas, diario, lienzo,metas, codeScanner, codeGenerate, game,ayudas, reflex, setting, reminder, premium, evidenciaCientifica
    case biografiaNeville,  frasesNeville, conferenciasNeville, citasNevile, preguntasNeville
    case biografiaJD,frasesJD
    case biografiaGregg, FrasesGreeg
    case biografíaBruceL,FrasesBruceL
    var id: String { rawValue }
}




struct optionView: View {
    
    @EnvironmentObject var settingModel: SettingModel
    /*
     @State private var showNotasSheet   = false
     @State private var showDiarioSheet  = false
     @State private var showLienzoSheet  = false
     @State private var showFrasesList   = false
     @State private var showCodeScanner  = false
     @State private var showCodeGenerate = false
     @State private var showGame         = false
     @State private var showBiografia    = false
     @State private var showCitas        = false
     @State private var showPreguntas    = false
     @State private var showAyudas       = false
     @State private var showReflex       = false
     @State private var showSetting      = false
     @State private var showReminder     = false
     @State private var showPremium      = false
     */
    
    
    @State private var showView : TipeViewOptionTab?  = nil

    private let sizeWigth : CGFloat = 150
    
    struct QRText: Identifiable {
        let id = UUID()
        let text: String
    }
    
    @State private var footerToQRCode : QRText?
    
    var body: some View {
        NavigationStack{
            
            VStack{
                HStack{
                    Menu{
                        Button("Bibliografía"){self.showView = .biografiaNeville}
                        Button("Conferencias"){self.showView = .conferenciasNeville}
                        Button("Frases"){self.showView = .frasesNeville}
                        Button("Citas"){self.showView = .citasNevile}
                        Button("Preguntas"){self.showView = .preguntasNeville}
                        Button("Evaluación"){self.showView = .game}
                    }label: {
                        Text("Neville Goddard")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Menu{
                        Button("Ayudas"){self.showView = .ayudas}
                        Button("Reflexiones"){self.showView = .reflex}
                        Button("Evidencia Científica"){self.showView = .evidenciaCientifica}
                        Button("Notas"){self.showView = .notas}
                        
                    }label: {
                        Text("Recursos Didácticos")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(5)
                .padding(.top, 10)
                
                HStack{
                    Menu{
                        Button("Bibliografía"){ }
                        Button("Conferencias"){}
                        Button("Frases"){self.showView = .frasesJD}
                    }label: {
                        Text("Joe Dispenza")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Menu{
                        Button("Lienzo"){self.showView = .lienzo}
                        Button("Recordatorios"){self.showView = .reminder}
                        Button("Metas"){self.showView = .metas}
                        Button("Lector QR"){self.showView = .codeScanner}
                        Button("Generador QR"){self.showView = .codeGenerate}
                    }label: {
                        Text("Productividad")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                }
                .padding(5)
                
                HStack{
                    Menu{
                        Button("Bibliografía"){}
                        Button("Charlas"){}
                        Button("Frases"){}
                    }label: {
                        Text("Gregg Braden")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Button{
                        self.showView = .setting
                    }label:{
                        Text("Ajustes")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                        
                    
                }
                .padding(5)
                
                
                HStack{
                    Menu{
                        Button("Bibliografía"){}
                        Button("Charlas"){}
                        Button("Frases"){}
                    }label: {
                        Text("Bruce Lipton")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            
                           
                    }
                    
                    Spacer()
                    
                    Button{
                        self.showView = .premium
                    }label: {
                        Text("La ley Premium")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                        
                        
                    
                }
                .padding(5)
                

            }
            .padding(10)
            .buttonStyle(.bordered)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
        }
        .preferredColorScheme(.dark)
        .background(LinearGradient.AzulTecnologico())
        .sheet(item: self.$showView, content: { item in
            VStack{
                switch item{
                case .setting:
                    Ajustes()
                case .notas:
                    ListNotasViews()
                case .biografiaNeville:
                    ContentTxtShowView(title: "Biografía", nombreTxt: "biografia", type: .NA )
                case .preguntasNeville:
                    TxtListView(typeOfContent: .preg, title: "Preguntas")
                case .citasNevile:
                    TxtListView(typeOfContent: .citas, title: "Citas")
                case .ayudas:
                    TxtListView(typeOfContent: .ayud, title: "Ayudas")
                case .reflex:
                    ReflexListView()
                case .diario:
                    DiarioListView()
                case .lienzo:
                    LienzoMain(texto: "")
                case .premium:
                    PurchaseView()
                case .conferenciasNeville:
                    TxtListView(typeOfContent: .conf, title: "Conferencias")
                    
                case .frasesNeville:
                    FrasesListView(mostrarFrasesDe: .nev)
                    
                case .codeScanner:
                    //Mostrar el lector de código
                    CodeScannerView(codeTypes: [.qr]) { qrCodeString in
                        do{
                            let result =  try qrCodeString.get().string
                            self.footerToQRCode = QRText(text: result)
                            
                        }catch{
                            
                        }
                        
                    }
                case .codeGenerate:
                    GenerateQRView(footer: "")
                case .game:
                    GamePLay()
                case .reminder:
                    ReminderListView()
                case .metas:
                    GoalsListView()
                case .biografiaJD:
                    EmptyView()
                case .biografiaGregg:
                    EmptyView()
                case .biografíaBruceL:
                    EmptyView()
                case .evidenciaCientifica:
                    VStack(spacing: 25){
                        Text("🚧 en Construcción...")
                        Text("Objetivo: Mostrar Evidencia y base científica sobre los temas abordados en estas enseñanzas")
                    }
                case .frasesJD:
                    FrasesListView(mostrarFrasesDe: .jd)
                case .FrasesGreeg:
                    EmptyView()
                case .FrasesBruceL:
                    EmptyView()
                }
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            
        })
        /*
         .sheet(isPresented: $showNotasSheet) {
             ListNotasViews()
         }
         .sheet(isPresented: $showBiografia) {
             ContentTxtShowView(title: "Biografía", nombreTxt: "biografia", type: .NA )
         }
         .sheet(isPresented: $showPreguntas) {
             TxtListView(typeOfContent: .preg, title: "Preguntas")
         }
         .sheet(isPresented: $showCitas) {
             TxtListView(typeOfContent: .citas, title: "Citas")
         }
         .sheet(isPresented: $showAyudas) {
             TxtListView(typeOfContent: .ayud, title: "Ayudas")
         }
         .sheet(isPresented: $showReflex) {
             ReflexListView()
         }
         .sheet(isPresented: $showDiarioSheet) {
             DiarioListView()
         }
         .sheet(isPresented: $showLienzoSheet) {
             LienzoMain(texto: nil)
         }
         .sheet (isPresented: $showFrasesList){
             FrasesListView()
         }
         .sheet(isPresented: $showSetting){
             Ajustes()
                 .presentationDetents([.large])
         }
         .sheet(isPresented: $showCodeScanner){
             //Mostrar el lector de código
             CodeScannerView(codeTypes: [.qr]) { qrCodeString in
                 do{
                   let result =  try qrCodeString.get().string
                     self.footerToQRCode = QRText(text: result)
                    
                 }catch{
                     
                 }
                 
             }
            
         }
         .sheet(item: $footerToQRCode){ item in
             GenerateQRView(footer: item.text)
                 .presentationDetents([.large])
                 .presentationDragIndicator(.hidden)
         }
         .sheet(isPresented: $showCodeGenerate){
            
                 GenerateQRView(footer: "")
                     .presentationDetents([.large])
                     .presentationDragIndicator(.hidden)
             
             
         }
         .sheet(isPresented: $showGame){
             GamePLay()
                 .presentationDetents([.large])
                 .presentationDragIndicator(.hidden)
         }
         .sheet(isPresented: self.$showReminder) {
             ReminderListView()
         }
         */
        
    }
    
    
    /*
     @ViewBuilder
     func primerGroup()-> some View{
         VStack(spacing: 20){
             HStack(spacing: 20){
                 
                 Button{
                     showReflex = true
                 }label: {
                     bloqueA("infinity", "Reflexiones")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Button{
                     showAyudas = true
                 }label: {
                     bloqueA("flag.2.crossed.fill", "Ayudas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             .padding(.top, 20)
             
             HStack(spacing: 20){
                 
                 Button{
                     showLienzoSheet = true
                 }label: {
                     bloqueA("heart.text.square", "Lienzo")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
                 
                 Button{
                     showFrasesList = true
                 }label: {
                     bloqueA("bookmark.fill", "Frases")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             
             HStack(spacing: 20){
                 Button{
                     showCitas = true
                 }label: {
                     bloqueA("doc.append", "Citas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Button{
                     showSetting = true
                 }label: {
                     bloqueA("gear", "Ajustes")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
             }
             Spacer()
             
             HStack{
                 
                 Spacer()
                 
                 Text ("     Inicio")
                     .font(.title2)
                     .fontDesign(.serif)
                 
                 Spacer()
                 
             }
             .padding(.vertical, 0)
             
             
             
         }
         
     }
     
     
     @ViewBuilder
     func  segundoGrupo()-> some View {
         VStack(spacing: 20){
             
             HStack(spacing: 20){
                 Button{
                     showBiografia = true
                 }label: {
                     bloqueA("person.text.rectangle", "Bibliografia")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Link(destination: URL(string: "https://t.me/+rODRAz2S6nVmMmY0")!){
                     bloqueA("personalhotspot", "Canal Telegram")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
             }
             .padding(.top, 20)
             HStack(spacing: 20){
                 Button{
                     showGame = true
                 }label: {
                     bloqueA("gamecontroller", "Evaluación")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
                 Button{
                     showPreguntas = true
                 }label: {
                     bloqueA("questionmark.bubble", "Preguntas & Respuestas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             HStack(spacing: 20){
                 
                 Button{
                     showReminder = true
                 }label: {
                     bloqueA("timer", "Recordatorios")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Menu{
                     Button{
                         //Mostrar el lector de QR
                         showCodeScanner = true
                     }label: {
                         bloqueA("qrcode.viewfinder", "Leer QR")
                     }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                     
                     Button{
                         showCodeGenerate = true
                     }label: {
                         bloqueA("qrcode", "Crear QR")
                     }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 }label: {
                     bloqueA("qrcode.viewfinder", "Funciones QR")
                 }
                 .modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
             }
             Spacer()
             Text ("Recursos")
                 .font(.title2)
                 .fontDesign(.serif)
             
         }
     }
     
     */
    
    

    //auxiliar
    @MainActor
    @ViewBuilder
    private  func bloqueA( _ systemImagen : String, _ texto : String)-> some View{
        
        HStack {
            Image(systemName: systemImagen)
            Text(texto)
            Spacer()
        }
        .foregroundStyle(.black).bold()
        
    }
    
    
}





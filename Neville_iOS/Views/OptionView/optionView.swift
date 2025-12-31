//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI


struct optionView: View {
    
    @EnvironmentObject var settingModel: SettingModel
    
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

    private let sizeWigth : CGFloat = 150
    
    struct QRText: Identifiable {
        let id = UUID()
        let text: String
    }
    
    @State private var footerToQRCode : QRText?
    
    var body: some View {
        NavigationStack{
            ZStack{
                

                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 5) {
                        primerGroup()
                            .padding(.horizontal, 7)
                            .padding(.vertical, 20)
                        segundoGrupo()
                            .padding(.horizontal, 7)
                            .padding(.vertical, 20)
                    }
                    
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity , maxHeight: .infinity)
                .background(.ultraThinMaterial)
                
                
                
               
            }
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
            
        }
    }
    
    
    
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





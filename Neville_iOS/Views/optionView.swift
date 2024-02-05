//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

struct optionView: View {

    @State private var showNotasSheet   = false
    @State private var showDiarioSheet  = false
    @State private var showFrasesList   = false
    @State private var showCodeScanner  = false
    @State private var showCodeGenerate = false
    @State private var showGame         = false
    @State private var showBiografia    = false
    @State private var showCitas        = false
    @State private var showPreguntas    = false
    @State private var showAyudas       = false
    @State private var showReflex       = false
    
    private let colorGradientButton = [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a),
                                       SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]
    
    private let sizeWigth : CGFloat = 150
    
    var body: some View {
        NavigationStack{
            ZStack{
                
                Color(Color.black.opacity(0.7))
                
                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 5) {
                        primerGroup()
                        .padding(.horizontal, 7)
                        segundoGrupo()
                        .padding(.horizontal, 7)
                        tercerGrupo()
                        .padding(.horizontal, 45)
                        
                    }
         
                }
                .scrollIndicators(.hidden)
                .frame(maxWidth: .infinity , maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .shadow(radius: 5)
            }
            
            .sheet(isPresented: $showNotasSheet) {
                ListNotasViews()
            }
            .sheet(isPresented: $showDiarioSheet) {
                DiarioListView()
            }
            .sheet (isPresented: $showFrasesList){
                FrasesListView()
            }
            .sheet(isPresented: $showCodeScanner){
                //QRCodeScanner()
            }
            .sheet(isPresented: $showCodeGenerate){
                GenerateQRView(footer: "", showImage: false)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showGame){
                GamePLay()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showBiografia){
                ContentTxtShowView(type: .NA, fileName: "biografia", title: "Biografía")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showCitas){
                TxtListView(type: .citas, title: "Citas")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showPreguntas){
                TxtListView(type: .preg, title: "Preguntas Respuestas")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showAyudas){
                TxtListView(type: .ayud, title: "Ayudas")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showReflex){
                ReflexListView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
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
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                   showAyudas = true
                }label: {
                    bloqueA("flag.2.crossed.fill", "Ayudas")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
 
            }
            .padding(.top, 5)
            
            HStack(spacing: 20){
                
                Button{
                showDiarioSheet = true
                }label: {
                    bloqueA("book", "Diario")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                    showFrasesList = true
                }label: {
                    bloqueA("bookmark.fill", "Frases")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
            }
            
            HStack(spacing: 20){
                Button{
                    showCitas = true
                }label: {
                    bloqueA("doc.append", "Citas")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                   showPreguntas = true
                }label: {
                    bloqueA("questionmark.bubble", "Preguntas & Respuestas")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
            }
            Spacer()
            Text ("Inicio")
                .font(.title2)
                .fontDesign(.serif)
            
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
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
 
                    Link(destination: URL(string: "https://t.me/+rODRAz2S6nVmMmY0")!){
                        bloqueA("personalhotspot", "Canal Telegram")
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                }
                .padding(.top, 5)
                HStack(spacing: 20){
                    Button{
                    showGame = true
                    }label: {
                        bloqueA("gamecontroller", "Evaluación")
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                    
                    
                    Button{
                        showNotasSheet = true
                    }label: {
                        bloqueA("note.text", "Notas")
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                }
            HStack(spacing: 20){

                Button{
                showCodeScanner = true
                }label: {
                    bloqueA("qrcode.viewfinder", "Leer QR")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                    showCodeGenerate = true
                }label: {
                    bloqueA("qrcode", "Crear QR")
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                
            }
            Spacer()
            Text ("Recursos")
                .font(.title2)
                .fontDesign(.serif)
                
            }
    }

    
    @ViewBuilder
    func  tercerGrupo()-> some View {
        VStack(spacing: 20){

                    Link(destination: URL(string: "https://www.youtube.com/watch?v=jd5ctdBQAeo&list=PL2kf06WQ27nmP4VFSy4li_U1jvoPM6wPU")!){
                        bloqueA("link", "Espiritualidad")
                    }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
                .padding(.top, 5)
            
            Link(destination: URL(string: "https://www.youtube.com/watch?v=ZPOS12O0Vd0&list=PL2kf06WQ27nmK4nw5oo1Dnw24xrxUDtyV")!){
                bloqueA("link", "Alcanzar el Éxito")
            }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
                    
            Link(destination: URL(string: "https://www.youtube.com/watch?v=wcE8X8FBWN0&list=PL2kf06WQ27nnuvoeU7-sk7qmEofplDEMR")!){
                bloqueA("link", "Personas que dejaron huellas")
            }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
                
            
            
               Spacer()
            Text ("10 lecciones de Sabiduria")
                .font(.title2)
                .fontDesign(.serif)
            }
    }
    
    //auxiliar
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



#Preview {
    optionView()
}
#Preview("home") {
    ContentView()
}

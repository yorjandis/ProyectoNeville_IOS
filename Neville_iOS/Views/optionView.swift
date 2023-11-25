//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

struct optionView: View {

    @State private var showNotasSheet = false
    @State private var showDiarioSheet = false
    @State private var showFrasesList = false
    @State private var showSeeting = false
    @State private var showCodeScanner = false
    @State private var showCodeGenerate = false
    @State private var showGame = false
    private let colorGradientButton = [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a),
                                       SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]
    private let sizeWigth : CGFloat = 130
    
    var body: some View {
            ZStack{
                
                Color(Color.black.opacity(0.7))
                
                ScrollView(.horizontal) {
                    HStack(alignment: .center, spacing: 10) {
                        primerGroup()
                        .padding(.horizontal, 20)
                        segundoGrupo()
                        .padding(.horizontal, 20)
                        tercerGrupo()
                        .padding(.horizontal, 40)
                        
                    }
         
                }
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
            .sheet (isPresented: $showSeeting){
                settingView()
            }
            .sheet(isPresented: $showCodeScanner){
                ReadQRCode()
            }
            .sheet(isPresented: $showCodeGenerate){
                GenerateQRView(string: "", footer: "", showImage: false)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $showGame){
                GamePLay()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
    
    @ViewBuilder
    func primerGroup()-> some View{
        VStack(spacing: 20){
            HStack(spacing: 20){
                Button{
                showGame = true
                }label: {
                    HStack {
                        Image(systemName: "gamecontroller")
                        Text("Jugar!")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                
                Button{
                    showNotasSheet = true
                }label: {
                    HStack {
                        Image(systemName: "note.text")
                        Text("Notas")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
            }
            
            HStack(spacing: 20){
                
                Button{
                showDiarioSheet = true
                }label: {
                    HStack {
                        Image(systemName: "book")
                        Text("Diario")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                    showFrasesList = true
                }label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                        Text("Frases")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
            }
            
            HStack(spacing: 20){
                
                Button{
                showCodeScanner = true
                }label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Leer QR")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
                Button{
                    showCodeGenerate = true
                }label: {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Crear QR")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                
            }
            
            HStack(spacing: 20){
                
                Button{
                    showSeeting = true
                }label: {
                    HStack {
                        Image(systemName: "gear")
                        Text("Ajustes")
                    }
                    .foregroundStyle(.black).bold()
                }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))

            }
        }
    }
    

    @ViewBuilder
    func  segundoGrupo()-> some View {
        VStack(spacing: 20){
                HStack(spacing: 20){
                    Button{
                    
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Bibliografia")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                    
                    Button{
                       
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Galeria")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                }
                HStack(spacing: 20){
                    Button{
                    
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Citas")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                    
                    Button{
                       
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Preguntas & Respuestas")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                }
                HStack(spacing: 20){
                    Button{
                    
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Reflexiones")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                    
                    Button{
                       
                    }label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Silencio")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                }
            Text ("Sobre el Maestro")
                .font(.title2)
                .fontDesign(.serif)
            }
    }

    @ViewBuilder
    func  tercerGrupo()-> some View {
        VStack(spacing: 10){

                    Link(destination: URL(string: "https://www.youtube.com/watch?v=jd5ctdBQAeo&list=PL2kf06WQ27nmP4VFSy4li_U1jvoPM6wPU")!){
                        HStack {
                            Image(systemName: "link")
                            Text("Espiritualidad")
                        }
                        .foregroundStyle(.black).bold()
                    }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
            
            Link(destination: URL(string: "https://www.youtube.com/watch?v=ZPOS12O0Vd0&list=PL2kf06WQ27nmK4nw5oo1Dnw24xrxUDtyV")!){
                HStack {
                    Image(systemName: "link")
                    Text("Alcanzar el Éxito")
                }
                .foregroundStyle(.black).bold()
            }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
                    
            Link(destination: URL(string: "https://www.youtube.com/watch?v=wcE8X8FBWN0&list=PL2kf06WQ27nnuvoeU7-sk7qmEofplDEMR")!){
                HStack {
                    Image(systemName: "link")
                    Text("Personas que dejaron huellas")
                }
                .foregroundStyle(.black).bold()
            }.modifier(GradientButtonStyle(ancho: 270, colors: colorGradientButton))
                
            
            
               
            Text ("10 lecciones de Sabiduria")
                .font(.title2)
                .fontDesign(.serif)
            }
    }

    
}



#Preview {
    optionView()
}
#Preview("home") {
    ContentView()
}

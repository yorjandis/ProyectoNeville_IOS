//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

struct optionView: View {

    @State private var showNotasSheet = false
    @State private var showFavSheet = false
    @State private var showFrasesList = false
    @State private var showSeeting = false
    @State private var showCodeScanner = false
    @State private var showCodeGenerate = false
    private let colorGradientButton = [SettingModel().loadColor(forkey: Constant.setting_color_main_a),
                                       SettingModel().loadColor(forkey: Constant.setting_color_main_b)]
    private let sizeWigth : CGFloat = 130
    
    var body: some View {
            ZStack{
                
                VStack(spacing: 20){
                    HStack(spacing: 20){
                        Button{
                            showSeeting = true
                        }label: {
                            HStack {
                                Image(systemName: "gear")
                                Text("Setting")
                            }
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                        Button{
                            showNotasSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "note.text")
                                Text("Notas")
                            }
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                    }
                    
                    HStack(spacing: 20){
                        
                        Button{
                        showFavSheet = true
                        }label: {
                            HStack {
                                Image(systemName: "heart")
                                Text("Favoritos")
                            }
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                        Button{
                            showFrasesList = true
                        }label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Frases")
                            }
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
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                        Button{
                            showCodeGenerate = true
                        }label: {
                            HStack {
                                Image(systemName: "qrcode")
                                Text("Crear QR")
                            }
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                    } 
                }
                .frame(maxWidth: .infinity , maxHeight: .infinity)
                .background(.ultraThinMaterial)
            }
            
            .sheet(isPresented: $showNotasSheet) {
                ListNotasViews()
            }
            .sheet(isPresented: $showFavSheet) {
                ListFavView()
            }
            .sheet (isPresented: $showFrasesList){
                FrasesListView()
            }
            .sheet (isPresented: $showSeeting){
                settingView()
            }
            .popover(isPresented: $showCodeScanner){
                ReadQRCode()
            }.popover(isPresented: $showCodeGenerate){
                GenerateImageQR(string: "Ejemplo", footer: "Ejemplo")
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
 

    
    
   
}

#Preview {
    optionView()
}
#Preview("home") {
    ContentView()
}

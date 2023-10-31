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
    @State private var showFrasesNotes = false
    @State private var showSeeting = false
    private let colorGradientButton = [SettingModel().loadColor(forkey: Constant.setting_color_main_a),
                                       SettingModel().loadColor(forkey: Constant.setting_color_main_b)]
    private let sizeWigth : CGFloat = 130
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black, .cyan], startPoint: .top, endPoint: .bottom)
                
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
                            showFrasesNotes = true
                        }label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Notas Frases")
                            }
                        }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: colorGradientButton))
                        
                    }
                    
                    
                    
                }
            }
            .sheet(isPresented: $showNotasSheet) {
                ListNotasViews()
            }
            .sheet(isPresented: $showFavSheet) {
                ListFavView()
            }
            .sheet (isPresented: $showFrasesNotes){
                FrasesNotasListView()
            }
            .sheet (isPresented: $showSeeting){
                settingView()
            }
        }
 
    }
    
    
   
}

#Preview {
    optionView()
}

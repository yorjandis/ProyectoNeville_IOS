//
//  ReflexShowTextView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import SwiftUI
import CoreData

struct ReflexShowTextView: View {
    
    @State var entity : RefType
    
    @State private var fontSizeContent : CGFloat = 18
    @State private var showSlider = false


    @AppStorage(AppCons.UD_setting_fontContentSize)  var fontSizeContenido  = 18
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Título"){
                    VStack(alignment: .leading){
                        Text(entity.title)
                            .multilineTextAlignment(.leading)
                        Text("Autor: \(entity.autor)").font(.footnote)
                    }
                    
                }
                Section("Reflexión"){
                    VStack{
                        ScrollView{
                            Text(entity.content)
                                .multilineTextAlignment(.leading)
                                .font(.system(size: fontSizeContent, design: .rounded))
                        }.scrollIndicators(.automatic)
                    }
                    
                   
                }
            }
            
                Divider()
                HStack{
                    Spacer()
                    if showSlider {
                        HStack{
                            Button{
                                withAnimation(.easeInOut) {
                                    showSlider = false
                                }
                            }label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            Slider(value: $fontSizeContent, in: 18...30) { Bool in
                                fontSizeContenido = Int(fontSizeContent)
                            }
                        }
                        .padding(.horizontal, 15)
                        
                    }
                }
                .navigationTitle("Reflexiones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Menu{
                    /*
                    if entity.isInbuilt == false {
                        NavigationLink("Editar Reflexión"){
                            ReflexEditView(reflex: $entity)
                        }
                    }
                    
                    */
                    
                    Button("Tamaño de Letra", systemImage: "textformat") {
                        withAnimation(.easeInOut) {
                            showSlider.toggle()
                        }
                    }
                }label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(Angle(degrees: 135))
                }
                
            }
            .onAppear {
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
            }
            
        }
    }
}

#Preview {
    ReflexShowTextView( entity: RefType(title: "", content: "", autor: "", isInbuilt: true, isfav: false))
}

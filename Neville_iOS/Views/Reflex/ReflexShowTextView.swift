//
//  ReflexShowTextView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import SwiftUI
import CoreData

struct ReflexShowTextView: View {
    
    @State var entity : Reflex
    @State private var fontSizeContent : CGFloat = 18
    @State private var showSlider = false
    
    @State var title = ""
    @State var autor = ""
    @State var texto = ""

    @AppStorage(AppCons.UD_setting_fontContentSize)  var fontSizeContenido  = 18
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Autor"){
                    Text(autor)
                        .multilineTextAlignment(.leading)
                }
                Section("Reflexión"){
                    Text(texto)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: fontSizeContent, design: .rounded))
                }
                
            }
            .onAppear{
                if self.entity.isnew {
                    RefexModel().RemoveNewFlag(entity: &self.entity)
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Menu{
                    if entity.isInbuilt == false {
                        NavigationLink("Editar Reflexión"){
                            ReflexEditView(reflex: $entity)
                        }
                    }
                    
                    
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
                
                title = entity.title ?? ""
                autor = entity.autor ?? ""
                texto = entity.texto ?? ""
                
                fontSizeContent = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontContentSize))
                fontSizeContenido = Int(self.fontSizeContent)
                
                //Desmarcando el elemento news:   
                if self.entity.isnew {
                    RefexModel().RemoveNewFlag(entity: &entity)
                }
                
            }
            
        }
    }
}

#Preview {
    ReflexShowTextView( entity: Reflex(context: CoreDataController.dC.context) )
}

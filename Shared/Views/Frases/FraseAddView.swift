//
//  FraseAddView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//

//Permite adicionar una nueva frase personal

import SwiftUI

struct FraseAddView: View {
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack{
                
#if os(macOS)
            HStack{
                Button("Guardar"){
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        FrasesModel.shared.AddFrase(frase: text)
                        //Lanza la ventana de FeedBackreview si se alcanza el humbral de hitos
                        if  FeedBackModel.checkReviewRequest() {
                            #if os(macOS)
                            showWindow(for: FeedbackView(showTextBotton: false),
                                       environmentObjects: [],
                                       title: "Enviar una Reseña a la App Store",
                                       size: AppCons.windows_size_content_small,
                                       isModal: true
                            )
                            #else
                            self.sheetShowFeedBackReview = true
                            #endif
                            
                        }
                        
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                        }else{
                            self.dismiss()
                        }
                        
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue.opacity(0.4))
                .disabled(self.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Spacer()
                
                Button("Cancelar"){
                    if let window = NSApp.keyWindow {
                        closeWindow(window)
                    }else{
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.4))
            }.padding()
#endif
                
                
                Form(){
                    Section("Frase"){
                        #if os(macOS)
                        ScrollView {
                            TextEditor(text: $text)
                                .font(.system(size: 20))
                                .scrollDisabled(false)
                                .frame(height: 150)
                                .padding(.bottom, 15)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                }
                        }
                        .padding(.horizontal, 5)
                        
                        
                        #else
                        TextField("Texto de la frase", text: $text, axis: .vertical)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 22))
                            .frame(height: 80)
                        #endif
                       
                    }
                }
                .padding(.horizontal, 5)
                
            }
            .navigationTitle("Nueva Frase")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("Guardar"){
                        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            FrasesModel.shared.AddFrase(frase: text)
                            //Lanza la ventana de FeedBackreview si se alcanza el humbral de hitos
                            if  FeedBackModel.checkReviewRequest() {
                                self.sheetShowFeedBackReview = true
                            }
                            self.dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue.opacity(0.4))
                }
                
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar"){
                        self.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red.opacity(0.4))
                }
            }
        #endif
            .sheet(isPresented: self.$sheetShowFeedBackReview) {
                FeedbackView(showTextBotton: true)
            }
        }
        #if os(macOS)
        .frame(minWidth: 400 , maxHeight: 450)
        #endif
    }
}

#Preview {
    FraseAddView()
}

//
//  gnerateQR.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Muestra una imagen con un pie de página

import SwiftUI



struct GenerateQRView : View {
    
    @State var  string : String
    @State var  footer : String = ""
    @State var  showImage = false
    
   
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    Text("Modifique el texto debajo de la imagen y utilice el botón: Generar")
                    Divider()
                    if showImage {
                        Image(uiImage: UIImage(data: QRModel().generateQRCode(text: string)!)!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300 )
                            //.offset(x:50)
                    }
                   
                    
                    TextField("Escriba un texto...!", text: $footer, axis: .vertical)
                        .font(.title2)
                        .padding(.horizontal, 10)
                        .lineLimit(12)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 20)
                        .onTapGesture {
                            withAnimation {
                                showImage = false
                            }
                            
                        }
                    Spacer()
             

            }
            }
            
            .navigationTitle("Generar Código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("Generar"){
                    withAnimation {
                        showImage = true
                    }
                    
                    string = footer
                }
            }
        }
            

    }
     
 
   
}




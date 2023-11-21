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
    @State var title : String = "Toque el texto para modificarlo"
    @State var   textFiel : Bool = true //false para mostrar un Text en lugar de un TextField
    @State var  showImage = true //muestra la imagen del QR ya generado
    @FocusState private var focusState : Bool
    @State private var showAlert = false
    @State private var imagen : UIImage? = UIImage(systemName: "qrcode")
    
    
   //UIImage(data: QRModel().generateQRCode(text: string)!)!
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    Text(title)
                        .padding(5)
                    Divider()
                    if showImage {
                        Image(uiImage: imagen!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300 )
                            .onTapGesture {
                                focusState = false
                            }
                        
                           
                    }
                   
                    if textFiel {
                        TextField("Escriba un texto...!", text: $footer, axis: .vertical)
                            .font(.title2)
                            .padding(.horizontal, 10)
                            .lineLimit(12)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.roundedBorder)
                            .padding(.top, 20)
                            .focused($focusState)
                            .onTapGesture {
                                withAnimation {
                                    showImage = false
                                }
                                
                            }
                    }else{
                        Text(footer)
                            .multilineTextAlignment(.leading)
                            .font(.title2)
                            .padding(.horizontal, 10)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
             

            }
                .onAppear {
                    imagen = getImageQR()
                    if textFiel == false {
                        title = ""
                    }
                }
            }
            
            .navigationTitle("Generar Código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button{
                    withAnimation {
                        imagen = getImageQR()
                        showImage = true
                        focusState = false
                    }
                    
                    string = footer
                }label: {
                    Image(systemName: "qrcode")
                }
                Menu{
                    
                    ShareLink(
                        item: Image(uiImage: imagen!),
                                    preview: SharePreview("Compartir",
                                        image: Image(systemName: "book")
                                    )
                     )
                    
                    Button{
                        UIImageWriteToSavedPhotosAlbum(imagen!, nil, nil, nil)
                        showAlert = true
                    }label: {
                        Label("Guardar en Galeria", systemImage: "photo.badge.arrow.down.fill")
                    }
                }label: {
                    Image(systemName: "ellipsis")
                        .rotationEffect(Angle(degrees: 135))
                }
                
                
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("La Ley"), message: Text("Se ha guardado la imagen QR en la galería"))
            }
        }
            

    }
    
    func getImageQR()->UIImage{
        return UIImage(data: QRModel().generateQRCode(text: string)!)!
    }
     
 
   
}




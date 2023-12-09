//
//  gnerateQR.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Muestra una imagen con un pie de página

import SwiftUI

struct GenerateQRView : View {


    
    @State var  footer : String = ""
    @State var title : String = "Toque el texto para modificarlo"
    @State var  showImage = true //muestra la imagen del QR ya generado
    @FocusState private var focusState : Bool //Para ocultar el teclado
    @State private var imagen : UIImage? = UIImage(systemName: "qrcode")
    
    @State private var showAlert = false
    
    
    
   //UIImage(data: QRModel().generateQRCode(text: string)!)!
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(spacing: 10){
                    Text(title)
                        .padding(5)
                        .padding(.top, 25)
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
                    
                    Spacer()
             

            }
                .onAppear {
                    if showImage {
                        imagen = getImageQR()
                    }

                }
            }
            
            .navigationTitle("Generar Código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button{
                    withAnimation {
                        if !self.footer.isEmpty {
                            imagen = getImageQR()
                            showImage = true
                            focusState = false
                        } 
                    }
                    
                }label: {
                    Image(systemName: "qrcode")
                }
                Menu{
                    
                    if showImage {
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
                    }
                    
                   
                    NavigationLink{
                        QRLoadFromGaleryView()
                    }label: {
                        Label("Cargar de Galeria", systemImage: "qrcode")
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
    
    
    //Obtiene la imagen QR de un texto
    func getImageQR()->UIImage{
        return UIImage(data: QRModel().generateQRCode(text: self.footer)!)!
    }
     
    
    
    //Auxiliar para cargar una imagen QR de la galería y decodificarla
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                      context: nil,
                                      options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
            let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else { return }

        let qrCodeLink = features.reduce("") { $0 + ($1.messageString ?? "") }

        print(qrCodeLink)//Your result from QR Code
    }
 
   
}




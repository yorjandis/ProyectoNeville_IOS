//
//  gnerateQR.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Muestra una imagen con un pie de página

import SwiftUI
#if os(macOS)
import AppKit
#endif



struct GenerateQRView : View {


    
    @State var  footer : String = ""
    
    @State  var title : String = "Toque el texto para modificarlo"
    
    @State  var  showImage = true //muestra la imagen del QR ya generado
    
    @FocusState private var focusState : Bool //Para ocultar el teclado
    #if os(iOS)
    @State private var imagen : UIImage? = UIImage(systemName: "qrcode")
    #endif
    
    #if os(macOS)
    @State private var imagen : UIImage? = UIImage(systemSymbolName: "qrcode", accessibilityDescription: nil)
    
    #endif
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
                        #if os(iOS)
                        Image(uiImage: imagen!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300 )
                            .onTapGesture {
                                focusState = false
                            }
                            .contextMenu {
                                
                                ShareLink( item: Image(uiImage: imagen!),
                                                preview: SharePreview("Compartir",
                                                    image: Image(systemName: "book")
                                                )
                                 )
                                Button("Guardar en Frases"){
                                    FrasesModel.shared.AddFrase(frase: footer)
                                }
                                Button("Guardar en Notas"){
                                    _ = NotasModel().addNote(nota: footer, title: "\(String(String(footer).prefix(footer.count / 3 )))...")
                                }
                                
                                
                            }
                            #elseif os(macOS)
                            Image(nsImage: imagen!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 300, height: 300 )
                            .onTapGesture {
                                focusState = false
                            }
                            .contextMenu {
                                
                                ShareLink( item: Image(nsImage: imagen!),
                                                preview: SharePreview("Compartir",
                                                    image: Image(systemName: "book")
                                                )
                                 )
                                Button("Guardar en Frases"){
                                    FrasesModel.shared.AddFrase(frase: footer)
                                }
                                Button("Guardar en Notas"){
                                    _ = NotasModel().addNote(nota: footer, title: "\(String(String(footer).prefix(footer.count / 3 )))...")
                                }
                                
                                
                            }
                            #endif
                            
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
                    
                    
                    #if os(macOS)
                    //Barra inferior para cerrar la ventana modal en macOS
                    HStack{
                        Spacer()
                        Button("Cerrar"){
                            if let window = NSApp.keyWindow {
                                    window.sheetParent?.endSheet(window)
                                }
                        }
                    }
                    .padding()
                    #endif

            }
                .onAppear {
                    if showImage {
                        imagen = getImageQR()
                    }

                }
            }
            
            .navigationTitle("Generar Código QR")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
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
                        #if os(iOS)
                        ShareLink(
                            item: Image(uiImage: imagen!),
                                        preview: SharePreview("Compartir",
                                            image: Image(systemName: "book")
                                        )
                         )
                        #elseif os(macOS)
                        ShareLink(
                            item: Image(nsImage: imagen!),
                                        preview: SharePreview("Compartir",
                                            image: Image(systemName: "book")
                                        )
                         )
                        #endif
                        
                        
                        #if os(iOS)
                        Button{
                            UIImageWriteToSavedPhotosAlbum(imagen!, nil, nil, nil)
                            showAlert = true
                        }label: {
                            Label("Guardar en Galeria", systemImage: "photo.badge.arrow.down.fill")
                        }
                        #endif
                    }
                    
                    #if os(iOS)
                    NavigationLink{
                        QRLoadFromGaleryView()
                    }label: {
                        Label("Cargar de Galeria", systemImage: "qrcode")
                    }
                    #endif
                    
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
     
    
    #if os(iOS)
    //Auxiliar para cargar una imagen QR de la galería y decodificarla
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                      context: nil,
                                      options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
              let _ = detector.features(in: ciImage) as? [CIQRCodeFeature] else { return }
    }
    #endif
 
}







//
//  gnerateQR.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Muestra una imagen con un pie de página

import SwiftUI
import CoreImage.CIFilterBuiltins


struct GenerateImageQR : View {
    
    @State var  string : String
    let footer : String
    @State private var textfiel = ""
    
    var body: some View {
        NavigationStack{
            VStack(spacing: 10){
                Image(uiImage: UIImage(data: generateQRCode(text: string)!)!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300 )
                    //.offset(x:50)
                
                TextField("", text: $textfiel, axis: .vertical)
                    .font(.title2)
                    .padding(.horizontal, 10)
                    .lineLimit(12)
                    .multilineTextAlignment(.center)
                    .onAppear{
                        textfiel = footer
                    }
                
         

        }
            .navigationTitle("Generar Código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("Generar"){
                    string = textfiel
                }
            }
        }
            

    }
     
    //Otra función:
    func generateQRCode(text: String) -> Data? {
        
            if text.count >= 4296  {return nil}
        
            let filter = CIFilter.qrCodeGenerator()
            guard let data = text.data(using: .utf8, allowLossyConversion: false) else { return nil }
            filter.message = data
            guard let ciimage = filter.outputImage else { return nil }
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledCIImage = ciimage.transformed(by: transform)
            let uiimage = UIImage(ciImage: scaledCIImage)
            return uiimage.pngData()!
        }
   
}




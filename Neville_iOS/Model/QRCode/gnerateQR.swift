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
    
    let string : String
    let footer : String
    
    var body: some View {
        GeometryReader(){proxy in 
            VStack(spacing: 10){
                Image(uiImage: UIImage(data: generateQRCode(text: string)!)!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width * 0.8, height: proxy.size.height )
                    .offset(x:50)
                
                Text(footer)
                    .font(.title2)
                    .padding(.horizontal, 10)
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




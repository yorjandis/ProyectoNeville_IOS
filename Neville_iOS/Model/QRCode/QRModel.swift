//
//  QRModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 13/11/23.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins



struct QRModel{

    
    //Función que genera un código QR. Devuelve un Data que puede ser cargado como imagen
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




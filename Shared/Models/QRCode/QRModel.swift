//
//  QRModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 13/11/23.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

#if os(macOS)
import AppKit
#endif


struct QRModel{

    #if os(iOS)
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
    
    #endif
    
    #if os(macOS)
    func generateQRCode(text: String) -> Data? {
        // Los códigos QR tienen un límite práctico (~4296 caracteres)
        guard text.count < 4296 else { return nil }
        
        // Crear el filtro de QR
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = text.data(using: .utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // Obtener la imagen CI
        guard let ciImage = filter.outputImage else { return nil }
        
        // Escalar para mejor resolución
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // Crear un contexto para renderizar la imagen
        let rep = NSCIImageRep(ciImage: scaledCIImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        // Convertir la imagen NSImage a PNG Data
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData
    }
    
    #endif
    
    
}




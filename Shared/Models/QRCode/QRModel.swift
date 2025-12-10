//
//  QRModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 13/11/23.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

#if os(iOS)
import UIKit
#endif
@preconcurrency import Vision

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
    //Genera un data que puede ser convertido a NSImage
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
    
    
    //Lee una imagen QR y la convierte a Texto
    static func leerQRConVision(from nsImage: NSImage, completion: @escaping @Sendable (String?) -> Void) {
        // Intentar obtener CGImage directamente
        guard let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion(nil)
            return
        }

        // Crear la petición de detección de códigos de barras (QR)
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                print("Error en VNDetectBarcodesRequest:", error)
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let results = request.results as? [VNBarcodeObservation],
                  let firstQR = results.first(where: { $0.symbology == .qr }),
                  let payload = firstQR.payloadStringValue else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async {
                completion(payload)
            }
        }

        // Ejecutar la petición en un hilo de background
        Task{
            await  MainActor.run {
                 let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                 do {
                     try handler.perform([request])
                 } catch {
                     print("Error ejecutando VNImageRequestHandler:", error)
                     DispatchQueue.main.async { completion(nil) }
                 }
             }
        }
       
        
    }
    
    
    // Función para guardar la imagen como archivo temporal PNG
       static func guardarImagenTemporalmente(imagen: NSImage) -> URL? {
           // 1. Obtener carpeta temporal
           let tempDir = FileManager.default.temporaryDirectory

           // 2. Limpiar la carpeta temporal
           do {
               let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
               for fileURL in contents {
                   try FileManager.default.removeItem(at: fileURL)
               }
           } catch {
               print("Error limpiando carpeta temporal: \(error)")
               // No se detiene el proceso, solo se avisa
           }

           // 3. Convertir NSImage a PNG
           guard let tiffData = imagen.tiffRepresentation,
                 let bitmap = NSBitmapImageRep(data: tiffData),
                 let pngData = bitmap.representation(using: .png, properties: [:]) else {
               return nil
           }

           // 4. Guardar la imagen como archivo temporal
           let fileURL = tempDir.appendingPathComponent("imagen_compartir.png")
           do {
               try pngData.write(to: fileURL)
               return fileURL
           } catch {
               print("Error guardando imagen temporal: \(error)")
               return nil
           }
       }
    
    #endif
    
    
    
    
    
    //Detectar formato de importación de Notas:
    //Ejempo de nota: nota>>título de la nota>>contenido de la nota>>No/Si
    //Devuelve una tupla compuesta: la primera parte si es true es que se ha detectado un formato de importación de Notas Válido, la segunda parte es una tupla de tres valores:
    //Primer valor: título de la nota, segundoValor: contenido de la nota, tercer valor: favorito que puede ser true o false
    @MainActor static func detectFormatImportNota(text: String) -> (Bool, (String, String, Bool))? {
        
        
        // El texto debe comenzar con el prefijo correcto
        guard text.hasPrefix(AppCons.zspNota) else {
            return nil
        }
        
        
        // Dividir usando "::". Si no hay exactamente 3 partes, el formato falla.
        let parts = text.split(separator: "::")
        guard parts.count == 3 else {
            return nil
        }

        // Interpretar el último valor: Favorito de la nota
        let flagString = parts[2].lowercased()
        guard flagString == "si" || flagString == "no" else {
            return nil
        }
        let isFavorite =  flagString == "no" ? false : true

        //Antes de retornar elimina los 3 caracteres ocultos del texto:
        return (true, (String(parts[0].dropFirst(3)), String(parts[1]), isFavorite))
    }
    
    
    @MainActor static func detectFormatImportFrase(text: String) -> (Bool, String)? {
        
        guard text.hasPrefix(AppCons.zspFrase) else {return nil}
        
        //Antes de retornar elimina los 3 caracteres ocultos al inicio de la cadena
        return (true, String(text.dropFirst(3)))
    }
    
    
    @MainActor static func aplicarFormatoImportacion(texto: String, tipo: String) -> String{
        //Primero limpia el texto de los caracteres ocultos utilizados
        let textoTemp = QRModel.removeHiddenChars(texto)
        if tipo == "nota"{
            return "\(AppCons.zspNota)\(textoTemp)"
        }else if tipo == "frase"{
            return "\(AppCons.zspFrase)\(textoTemp)"
        }else{
            return ""
        }
    }
    
    
    static func removeHiddenChars(_ text: String) -> String {
        let charsToRemove: [Character] = ["\u{200B}", "\u{2063}"]
        return String(text.filter { !charsToRemove.contains($0) })
    }
    
    
    
}




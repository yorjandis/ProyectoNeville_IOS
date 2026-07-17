//
//  ShareExtensionView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/12/25.
//

import SwiftUI
import Vision
import AppKit
import CoreImage

struct ShareExtensionView: View {
    
    @State var  texto: String = ""
    var image: NSImage? = nil
    
    @State private var textqr: String = ""
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"
    @State private var hasPremium : Bool = false
    
    @State private var showEditor : Bool = false
    
    
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    
    var body: some View {
        NavigationStack {
            
            ZStack{
                LinearGradient(colors: [.orange, .green], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if (self.hasPremium || self.yorjPremium){
                    VStack{
                        //Logo & Título
                        VStack{
                            Image("logo") // Reemplaza con el nombre de tu imagen en Assets
                                           .resizable()
                                           .aspectRatio(contentMode: .fill)
                                           .frame(width: 60, height: 60) // Tamaño del círculo
                                           .clipShape(Circle()) // Hace la imagen circular
                                           .overlay(
                                               Circle().stroke(Color.black, lineWidth: 4) // Borde opcional
                                           )
                                           .shadow(radius: 5) // Sombra opcional
                            Text("La Ley")
                                .font(.title).bold()
                                .foregroundStyle(.black)
                        }

                        //Si se trata de una imagen
                        if let img = image {
                            
                            VStack{
                                //Manejo de Texto
                                Image(nsImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                
                                if let textoQR = detectQRCode(from: img){
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    
                                                    if self.showEditor {
                                                        
                                                        TextEditor(text: self.$textqr)
                                                            .frame(height: 200)
                                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                                        HStack{
                                                            Spacer()
                                                            Button("Guardar"){
                                                                self.showEditor = false
                                                            }
                                                        }
                                                        
                                                    }else{
                                                        Text(textoQR)
                                                            .textSelection(.enabled)
                                                            .font(.title2)
                                                            .foregroundStyle(.black)
                                                            .padding(.vertical, 8)
                                                            .padding(.horizontal, 14)
                                                            .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.5) // Altura dependiente del 40% de la pantalla
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                    .fill(Color.blue.opacity(0.3))
                                                            )
                                                            .onAppear {
                                                                self.textqr = textoQR // Almacenando el texto del código QR
                                                            }
                                                        HStack{
                                                            Spacer()
                                                            Button("Editar"){
                                                                self.showEditor = true
                                                            }
                                                        }
                                                    }
                                                    
                                                    
                                                }
                                                .frame(width: geometry.size.width) // Ocupa todo el ancho de la pantalla
                                    }
                                    
                                    Spacer()
                                    
                                    //Panel de opciones
                                    VStack(spacing: 20){
                                        
                                        Button("OCR sobre la Imagen"){
                                            Task{
                                                do{
                                                    let texto = try await ocrAccurate(from: img)
                                                    self.textqr = texto
                                                }catch{
                                                    print("La imagen no parece contener texto legible")
                                                }
                                            }
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                        
                                        Button("Guardar Texto en Notas") {
                                            
                                            // 2. Guardar el QR en UserDefaults del App Group
                                            guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                                print("❌ No se pudo acceder al App Group")
                                                return
                                            }
                                                defaults.set(textoQR, forKey: self.keyNotaShareText)
                                                self.alertMessage = localized("Texto guardado en Notas.")
                                                self.showAlert = true
                                            
                                            
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                        
                                        Button("Guardar Texto en Frases") {
                                            
                                            // 2. Guardar el QR en UserDefaults del App Group
                                            guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                                print("❌ No se pudo acceder al App Group")
                                                return
                                            }
                                                defaults.set(textoQR, forKey: self.keyFraseShareText)
                                            
                                            
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    
                                }else{
                                    //Si la imagen no tiene código QR:
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    
                                                    if self.showEditor {
                                                        TextEditor(text: self.$textqr)
                                                            .frame(height: 200)
                                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                                        HStack{
                                                            Spacer()
                                                            Button("Guardar"){
                                                                self.showEditor = false
                                                            }
                                                        }
                                                    }else{
                                                        Text(textqr)
                                                            .textSelection(.enabled)
                                                            .font(.title2)
                                                            .foregroundStyle(.black)
                                                            .padding(.vertical, 8)
                                                            .padding(.horizontal, 14)
                                                            .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.5) // Altura dependiente del 40% de la pantalla
                                                            .background(
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                    .fill(Color.blue.opacity(0.3))
                                                            )
                                                        HStack{
                                                            Spacer()
                                                            Button("Editar"){
                                                                self.showEditor = true
                                                            }
                                                        }
                                                    }
                                                    
                                                    
                                                }
                                                .frame(width: geometry.size.width) // Ocupa todo el ancho de la pantalla
                                    }
                                    
                                    Button("OCR sobre la Imagen"){
                                        Task{
                                            do{
                                                let texto = try await ocrAccurate(from: img)
                                                self.textqr = texto
                                            }catch{
                                                print("La imagen no parece contener texto legible")
                                            }
                                        }
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)
                                    
                                    Spacer()
                                }
                            }
                            
                        } else if !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                            //manejo del texto. Permite editarlo antes de procesarlo
                            
                            VStack{
                                GeometryReader { geometry in
                                            ScrollView {
                                                
                                                if self.showEditor {
                                                    TextEditor(text: self.$texto)
                                                        .frame(height: 200)
                                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                                    HStack{
                                                        Spacer()
                                                        Button("Guardar"){
                                                            self.showEditor = false
                                                        }
                                                    }
                                                }else{
                                                    Text(texto)
                                                        .font(.title2)
                                                        .foregroundStyle(.black)
                                                        .padding(.vertical, 8)
                                                        .padding(.horizontal, 14)
                                                        .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.5) // Altura dependiente del 50% de la pantalla
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .fill(Color.blue.opacity(0.3))
                                                        )
                                                    HStack{
                                                        Spacer()
                                                        Button("Editar"){
                                                            self.showEditor = true
                                                        }
                                                    }
                                                }
                                                
                                                
                                                    
                                            }
                                            .frame(width: geometry.size.width) // Ocupa todo el ancho de la pantalla
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 20){
                                    Button("Guardar Texto en Notas") {
                                        
                                        // 2. Guardar el QR en UserDefaults del App Group
                                        guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                            print("❌ No se pudo acceder al App Group")
                                            return
                                        }
                                            defaults.set(texto, forKey: self.keyNotaShareText)
                                        
                                        
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)
                                    
                                    Button("Guardar Texto en Frases") {
                                        
                                        // 2. Guardar el QR en UserDefaults del App Group
                                        guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                            print("❌ No se pudo acceder al App Group")
                                            return
                                        }
                                            defaults.set(texto, forKey: self.keyFraseShareText)
                                        
                                        
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)
                                }
                                
                                
                            }
                            
                        }else{
                            
                            Text("No se ha detectado contenido que pueda ser utilizado")
                                .font(.title2)
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                        
                        
                        HStack{
                            Spacer()
                            Button{
                                close()
                            }label:{
                               Text("Salir")
                                    .foregroundStyle(.black)
                            }
                            .foregroundStyle(.black)
                            .buttonStyle(.bordered)
                            
                        }
                        .frame(maxWidth: .infinity)
                        
                        
                    }
                    .padding()
                }else{
                    VStack{
                        PurchaseView(mostrarLogo: false)
                        Button("Cerrar"){
                            close()
                        }
                        .foregroundStyle(.black)
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    
                }
                
            }
            .task{
                self.hasPremium = await PremiumService.shared.hasPremiumAccess()
            }
            
        }
        .alert(isPresented: self.$showAlert){
            Alert(title: Text("La Ley"), message: Text(self.alertMessage))
        }
        
    }
    
    
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }

    private func localized(_ spanish: String) -> String {
        Bundle.main.localizedString(forKey: spanish, value: spanish, table: "Localizable")
    }
    
    
    
    /// Detecta y devuelve el texto del QR contenido en una imagen.
    /// Devuelve nil si no existe un QR detectable.
    func detectQRCode(from image: NSImage) -> String? {
        
        // Convertimos NSImage a CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil,
                                          context: nil,
                                          hints: nil) else {
            return nil
        }
        
        // Convertimos CGImage a CIImage
        let ciImage = CIImage(cgImage: cgImage)
        
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        
        guard let qrDetector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: context,
            options: options
        ) else {
            return nil
        }
        
        let features = qrDetector.features(in: ciImage)
        
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature,
               let message = qrFeature.messageString {
                return message
            }
        }
        
        return nil
    }

    /// Función OCR precisa.
    /// Devuelve el texto reconocido en la imagen.
    /// - Parameters:
    ///   - image: NSImage de entrada
    ///   - languages: Idiomas de reconocimiento (por defecto español e inglés)
    func ocrAccurate(
        from image: NSImage,
        languages: [String] = ["es-ES", "en-US"]
    ) async throws -> String {

        // Convertimos NSImage a CGImage
        guard let cgImage = image.cgImage(forProposedRect: nil,
                                          context: nil,
                                          hints: nil) else {
            return ""
        }

        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err = err {
                    cont.resume(throwing: err)
                    return
                }

                let observations = req.results as? [VNRecognizedTextObservation] ?? []

                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                cont.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .up
            )

            // Ejecutamos fuera del closure para evitar problemas de concurrencia
            Task {
                do {
                    try handler.perform([request])
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }
    
    
    
}


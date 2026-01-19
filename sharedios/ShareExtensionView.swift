import SwiftUI
import Vision
import UIKit

struct ShareExtensionView: View {
    
    var  texto: String = ""
    var image: UIImage? = nil
    
    @State private var textqr: String = ""
    
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"
    @State private var hasPremium : Bool = false
    
    
    
    var body: some View {
        NavigationStack {
            
            ZStack{
                LinearGradient(colors: [.orange, .green], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if self.hasPremium{
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
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                
                                if let textoQR = detectQRCode(from: img){
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    SelectableText(textoQR)
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
                                        .buttonStyle(.borderedProminent)
                                        
                                        Button("Guardar Texto en Notas") {
                                            
                                            // 2. Guardar el QR en UserDefaults del App Group
                                            guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                                print("❌ No se pudo acceder al App Group")
                                                return
                                            }
                                                defaults.set(textoQR, forKey: self.keyNotaShareText)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        
                                        Button("Guardar Texto en Frases") {
                                            
                                            // 2. Guardar el QR en UserDefaults del App Group
                                            guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                                print("❌ No se pudo acceder al App Group")
                                                return
                                            }
                                                defaults.set(textoQR, forKey: self.keyFraseShareText)
                                            
                                            
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                    
                                    
                                }else{
                                    //Si la imagen no tiene código QR:
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    SelectableText(textqr)
                                                        .font(.title2)
                                                        .foregroundStyle(.black)
                                                        .padding(.vertical, 8)
                                                        .padding(.horizontal, 14)
                                                        .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.5) // Altura dependiente del 40% de la pantalla
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                .fill(Color.blue.opacity(0.3))
                                                        )
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
                                    .buttonStyle(.borderedProminent)
                                    
                                    Spacer()
                                }
                            }
                            
                        } else if !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                            //manejo del texto. Permite editarlo antes de procesarlo
                            
                            VStack{
                                GeometryReader { geometry in
                                            ScrollView {
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
                                    .buttonStyle(.borderedProminent)
                                    
                                    Button("Guardar Texto en Frases") {
                                        
                                        // 2. Guardar el QR en UserDefaults del App Group
                                        guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
                                            print("❌ No se pudo acceder al App Group")
                                            return
                                        }
                                            defaults.set(texto, forKey: self.keyFraseShareText)
                                        
                                        
                                    }
                                    .buttonStyle(.borderedProminent)
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
                            .buttonStyle(.bordered)
                            
                        }
                        .frame(maxWidth: .infinity)
                        
                        
                    }
                    .padding()
                }else{
                    PurchaseView(mostrarLogo: false)
                }
                
            }
            .task{
                self.hasPremium = await PremiumService.shared.hasPremiumAccess()
            }
            
        }
    }
    
    
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }
    
    
    
    //Detecta y devuelve el Texto del QR contenido en una imagen. nil si no existe QR detectable
    func detectQRCode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext()
        let options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
        
        let features = qrDetector?.features(in: ciImage) ?? []
        
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let message = qrFeature.messageString {
                return message
            }
        }
        
        return nil
    }

    //Funcion OCR
    func ocrAccurate(from image: UIImage,languages: [String] = ["es-ES", "en-US"]) async throws -> String {
        guard let cg = image.cgImage else { return "" }

        return try await withCheckedThrowingContinuation { cont in
            let request = VNRecognizeTextRequest { req, err in
                if let err = err {
                    cont.resume(throwing: err)
                    return
                }
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let text = obs.compactMap { $0.topCandidates(1).first?.string }
                               .joined(separator: "\n")
                cont.resume(returning: text)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(cgImage: cg, orientation: .up)

            // Ejecutamos directo, sin capturar handler en un closure @Sendable
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



import SwiftUI
import Vision
import UIKit

struct ShareExtensionView: View {
    
    @State var  texto: String = ""
    var image: UIImage? = nil
    
    @State private var textqr: String = ""

    @State private var ShowEditor : Bool = false
    
    
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"
    let keyCalmaShareText   = "calmaShareText"
    
    
    @State private var hasPremium : Bool = false
    @State private var actionMessage: String = ""
    @State private var showActionMessage: Bool = false
    
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false
    
    
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
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                
                                //Detectando automáticamente el código QR, si existe
                                if let textoQR = detectQRCode(from: img){
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    if self.ShowEditor {
                                                        VStack{
                                                            SwiftUI.TextEditor(text: self.$textqr)
                                                                .frame(height: 150)
                                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                            Button("Guardar"){
                                                                self.ShowEditor = false
                                                            }
                                                            .foregroundStyle(.black)
                                                            .buttonStyle(.bordered)
                                                        }
                                                        
                                                    }else{
                                                        Text(textoQR)
                                                            .font(.title2)
                                                            .foregroundStyle(.black)
                                                            .textSelection(.enabled)
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
                                                                self.ShowEditor = true
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
                                            saveToAppGroup(
                                                key: self.keyNotaShareText,
                                                value: textoQR,
                                                successMessage: "Texto guardado en Notas."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                        
                                        Button("Guardar Texto en Frases") {
                                            saveToAppGroup(
                                                key: self.keyFraseShareText,
                                                value: textoQR,
                                                successMessage: "Texto guardado en Frases."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)

                                        Button("Guardar como Frase Personal Calma") {
                                            saveToAppGroup(
                                                key: self.keyCalmaShareText,
                                                value: textoQR,
                                                successMessage: "Texto guardado como Frase Personal de Calma."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    
                                }else{
                                    //Si la imagen no tiene código QR:
                                    GeometryReader { geometry in
                                                ScrollView {
                                                    if self.ShowEditor {
                                                        VStack{
                                                            SwiftUI.TextEditor(text: self.$textqr)
                                                                .frame(height: 150)
                                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                            HStack{
                                                                Spacer()
                                                                Button("Guardar"){
                                                                    self.ShowEditor = false
                                                                }
                                                                .foregroundStyle(.black)
                                                                .buttonStyle(.bordered)
                                                            }
                                                            
                                                        }
                                                    }else{
                                                        Text(textqr)
                                                            .font(.title2)
                                                            .foregroundStyle(.black)
                                                            .textSelection(.enabled)
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
                                                                self.ShowEditor = true
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
                                    
                                    //Si se devuelve texto se muestran los botones:
                                    if !self.textqr.isEmpty {
                                        Button("Guardar Texto en Notas") {
                                            saveToAppGroup(
                                                key: self.keyNotaShareText,
                                                value: textqr,
                                                successMessage: "Texto guardado en Notas."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                        
                                        Button("Guardar Texto en Frases") {
                                            saveToAppGroup(
                                                key: self.keyFraseShareText,
                                                value: textqr,
                                                successMessage: "Texto guardado en Frases."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)

                                        Button("Guardar como Frase Personal Calma") {
                                            saveToAppGroup(
                                                key: self.keyCalmaShareText,
                                                value: textqr,
                                                successMessage: "Texto guardado como Frase Personal de Calma."
                                            )
                                        }
                                        .foregroundStyle(.black)
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    
                                    Spacer()
                                }
                            }
                            
                        } else if !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                            
                            //Si es solo texto
                            
                            VStack{
                                GeometryReader { geometry in
                                            ScrollView {
                                                
                                                if self.ShowEditor{
                                                    VStack{
                                                        SwiftUI.TextEditor(text: self.$texto)
                                                            .frame(height: 200)
                                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                                        HStack{
                                                            Spacer()
                                                            Button("Guardar"){
                                                                self.ShowEditor = false
                                                            }
                                                            .foregroundStyle(.black)
                                                            .buttonStyle(.bordered)
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
                                                            self.ShowEditor = true
                                                        }
                                                        .foregroundStyle(.black)
                                                        .buttonStyle(.bordered)
                                                    }
                                                     
                                                }
                                                
                                                
                                                    
                                            }
                                            .frame(width: geometry.size.width) // Ocupa todo el ancho de la pantalla
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 20){
                                    Button("Guardar Texto en Notas") {
                                        saveToAppGroup(
                                            key: self.keyNotaShareText,
                                            value: texto,
                                            successMessage: "Texto guardado en Notas."
                                        )
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)
                                    
                                    Button("Guardar Texto en Frases") {
                                        saveToAppGroup(
                                            key: self.keyFraseShareText,
                                            value: texto,
                                            successMessage: "Texto guardado en Frases."
                                        )
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)

                                    Button("Guardar como Frase Personal Calma") {
                                        saveToAppGroup(
                                            key: self.keyCalmaShareText,
                                            value: texto,
                                            successMessage: "Texto guardado como Frase Personal de Calma."
                                        )
                                    }
                                    .foregroundStyle(.black)
                                    .buttonStyle(.bordered)
                                }
                                
                                
                            }
                            
                        }else{
                            
                            Text("No se ha detectado contenido que pueda ser utilizado")
                                .font(.title2)
                                .foregroundStyle(.black)
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
                        
                        if showActionMessage {
                            Text(actionMessage)
                                .font(.footnote)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .transition(.opacity)
                        }
                        
                        
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

    private func saveToAppGroup(key: String, value: String, successMessage: String) {
        guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
            showTemporaryMessage(localized("No se pudo acceder al App Group."))
            return
        }
        defaults.set(value, forKey: key)
        showTemporaryMessage(localized(successMessage))
    }

    private func localized(_ spanish: String) -> String {
        Bundle.main.localizedString(forKey: spanish, value: spanish, table: "Localizable")
    }

    private func showTemporaryMessage(_ message: String) {
        withAnimation {
            self.actionMessage = message
            self.showActionMessage = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run {
                withAnimation {
                    self.showActionMessage = false
                }
            }
        }
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

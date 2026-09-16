import SwiftUI
import Vision
import UIKit
import Translation

private enum OCRLanguage: String, CaseIterable, Identifiable {
    case spanish
    case english
    case simplifiedChinese
    case french
    case german
    case hindi
    case italian

    var id: Self { self }

    var displayName: LocalizedStringKey {
        switch self {
        case .spanish: "Español"
        case .english: "Inglés"
        case .simplifiedChinese: "Chino mandarín"
        case .french: "Francés"
        case .german: "Alemán"
        case .hindi: "Hindi"
        case .italian: "Italiano"
        }
    }

    /// Vision prueba los identificadores en orden de prioridad.
    var recognitionIdentifiers: [String] {
        switch self {
        case .spanish: ["es-ES", "es-MX"]
        case .english: ["en-US", "en-GB"]
        case .simplifiedChinese: ["zh-Hans"]
        case .french: ["fr-FR"]
        case .german: ["de-DE"]
        case .hindi: ["hi-IN"]
        case .italian: ["it-IT"]
        }
    }
}

private enum TranslationTargetLanguage: String, CaseIterable, Identifiable {
    case spanish
    case english
    case simplifiedChinese

    var id: Self { self }

    var displayName: LocalizedStringKey {
        switch self {
        case .spanish: "Español"
        case .english: "Inglés"
        case .simplifiedChinese: "Chino mandarín"
        }
    }

    var localeLanguage: Locale.Language {
        switch self {
        case .spanish: Locale.Language(identifier: "es")
        case .english: Locale.Language(identifier: "en")
        case .simplifiedChinese: Locale.Language(identifier: "zh-Hans")
        }
    }
}

struct ShareExtensionView: View {
    
    @State var  texto: String = ""
    var image: UIImage? = nil
    
    @State private var textqr: String = ""
    @State private var selectedOCRLanguage: OCRLanguage = .spanish
    @State private var isRecognizingText: Bool = false
    @State private var selectedTranslationLanguage: TranslationTargetLanguage = .spanish
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var pendingTranslationText: String = ""
    @State private var isTranslating: Bool = false

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
                                        
                                        ocrLanguagePicker

                                        ocrButton(for: img)
                                        
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
                                    
                                    ocrLanguagePicker

                                    ocrButton(for: img)
                                    
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

                        if !translationSourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            translationControls
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
            .translationTask(translationConfiguration) { session in
                await translatePendingText(using: session)
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

    private var ocrLanguagePicker: some View {
        HStack {
            Text("OCR desde:")
                .foregroundStyle(.black)

            Picker("Idioma de origen del OCR", selection: $selectedOCRLanguage) {
                ForEach(OCRLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .tint(.black)
        }
    }

    private var translationSourceText: String {
        image == nil ? texto : textqr
    }

    private func ocrButton(for image: UIImage) -> some View {
        Button {
            Task {
                isRecognizingText = true
                defer { isRecognizingText = false }

                do {
                    textqr = try await ocrAccurate(
                        from: image,
                        language: selectedOCRLanguage
                    )
                } catch {
                    showTemporaryMessage(String(localized: "La imagen no parece contener texto legible."))
                }
            }
        } label: {
            if isRecognizingText {
                ProgressView()
            } else {
                Text("OCR sobre la Imagen")
            }
        }
        .foregroundStyle(.black)
        .buttonStyle(.bordered)
        .disabled(isRecognizingText)
    }

    private var translationControls: some View {
        HStack {
            Text("Traducir al:")
                .foregroundStyle(.black)

            Picker("Idioma de destino de la traducción", selection: $selectedTranslationLanguage) {
                ForEach(TranslationTargetLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.menu)
            .tint(.black)

            Button {
                requestTranslation()
            } label: {
                if isTranslating {
                    ProgressView()
                } else {
                    Text("Traducir")
                }
            }
            .foregroundStyle(.black)
            .buttonStyle(.bordered)
            .disabled(isTranslating)
        }
    }

    private func requestTranslation() {
        let sourceText = translationSourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty else { return }

        pendingTranslationText = sourceText
        isTranslating = true

        let targetLanguage = selectedTranslationLanguage.localeLanguage
        if translationConfiguration?.target == targetLanguage {
            translationConfiguration?.invalidate()
        } else {
            translationConfiguration = TranslationSession.Configuration(
                source: nil,
                target: targetLanguage
            )
        }
    }

    @MainActor
    private func translatePendingText(using session: TranslationSession) async {
        do {
            let response = try await session.translate(pendingTranslationText)
            if image == nil {
                texto = response.targetText
            } else {
                textqr = response.targetText
            }
        } catch {
            showTemporaryMessage(String(localized: "No se pudo traducir el texto."))
        }
        isTranslating = false
    }

    //Funcion OCR
    private func ocrAccurate(from image: UIImage, language: OCRLanguage) async throws -> String {
        guard let cg = image.cgImage else { return "" }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = language.recognitionIdentifiers.map {
            Locale.Language(identifier: $0)
        }

        let observations = try await request.perform(on: cg, orientation: .up)
        return observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
    
    
    
}

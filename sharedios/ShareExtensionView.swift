import SwiftUI
import CoreData

struct ShareExtensionView: View {
    
    var  texto: String = ""
    var image: UIImage? = nil
    
    @State private var textqr: String = ""
    
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"
    

 
    // Inicializador para texto
    /*
    init(texto: String) {
        self.texto = "Esto es solo un ejemplo"
        self.image = nil
    }

    // Inicializador para imagen
    init(image: UIImage) {
        self.image = image
        self.texto = ""
    }
    */
    
    
    var body: some View {
        NavigationStack {
            VStack{
                
                if let img = image {
                    
                    VStack{
                        //Manejo de Texto
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                        
                        if let textoQR = detectQRCode(from: img){

                            Text(textoQR)
                                .font(.title2)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 14)
                                .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.blue.opacity(0.3))
                                    )
                                .onAppear{
                                    self.textqr = textoQR //Almacenando el texto del código QR
                                }
                            
                            Spacer()
                            
                            VStack(spacing: 20){
                                Button("Guardar Texto en Notas") {
                                    
                                    // 2. Guardar el QR en UserDefaults del App Group
                                    if let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") {
                                        defaults.set(textoQR, forKey: self.keyNotaShareText)
                                    }
                                    
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Guardar Texto en Frases") {
                                    
                                    // 2. Guardar el QR en UserDefaults del App Group
                                    if let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") {
                                        defaults.set(textoQR, forKey: self.keyFraseShareText)
                                    }
                                    
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            
                        }else{
                            Text("La imagen no contiene QR legible")
                        }
                    }
                    
                } else if !texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
                    //manejo del texto. Permite editarlo antes de procesarlo
                    
                    VStack{
                        Text(texto)
                            .font(.title2)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.blue.opacity(0.3))
                                )
                        
                        Spacer()
                        
                        VStack(spacing: 20){
                            Button("Guardar Texto en Notas") {
                                
                                // 2. Guardar el QR en UserDefaults del App Group
                                if let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") {
                                    defaults.set(texto, forKey: self.keyNotaShareText)
                                }
                                
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Guardar Texto en Frases") {
                                
                                // 2. Guardar el QR en UserDefaults del App Group
                                if let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") {
                                    defaults.set(texto, forKey: self.keyFraseShareText)
                                }
                                
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
            }
            .padding()
            .navigationTitle("La Ley")
            .toolbar {
                Button("Cancel") { close() }
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

    
}



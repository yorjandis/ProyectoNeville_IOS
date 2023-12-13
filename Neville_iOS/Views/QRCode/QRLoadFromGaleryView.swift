//
//  QRLoadFromGaleryView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 8/12/23.
//
//Carga una imagen desde lagaleria

import SwiftUI
import PhotosUI

struct QRLoadFromGaleryView: View {
    
    @State private var selectedItem: PhotosPickerItem?
     @State private var selectedImage : UIImage?
     @State private var texto = ""
    
    @State private var ShowMenu = false
    @State private var inicialScreen = false
    
    private let colorGradientButton = [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a),
                                       SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                if let tt = selectedImage {
                    Image(uiImage: tt )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .contextMenu {
                            ShareLink( item: Image(uiImage: tt),
                                            preview: SharePreview("Compartir",
                                                image: Image(systemName: "book")
                                            )
                             )
                            Button("Guardar en Frases"){
                                FrasesModel().AddFrase(frase: texto)
                            }
                            Button("Guardar en Notas"){
                                _ = NotasModel().addNote(nota: texto, title: "\(String(String(texto).prefix(texto.count / 3 )))...")
                            }
                            
                        }
                    
                    Text(texto)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                    
                }
                
                
                Spacer()
                
                PhotosPicker(selection: $selectedItem, matching: .images){
                    Label("Seleccionar imagen", systemImage: "photo")
                }
                    .onChange(of: selectedItem) {
                        
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                
                                guard let temp = UIImage(data: data) else {return}//Aqui tenemos la imagen de la galería
                                
                                //Intentanto leer la imagen cargada
                                if let features = detectQRCode(temp), !features.isEmpty{
                                    for case let row as CIQRCodeFeature in features{
                                        self.texto = row.messageString ?? ""
                                    }
                                    withAnimation {
                                        self.inicialScreen = true
                                        selectedImage = temp
                                    }
                                    
                                    
                                }else{
                                    selectedImage = UIImage(systemName: "qrcode")
                                    self.texto = ""
                                }
                            }else{
                                print("Fallo al cargar la imagen de la galeria")
                            }
                        }
                    }
                    .padding(.bottom, 25)
                    .tint(.blue)
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
  
            }
            .overlay {
                VStack{
                    Text("Seleccione una imagen QR de la galeria para leer")
                        .multilineTextAlignment(.center)
                        .italic()
                        .fontWeight(.heavy)
                        .fontDesign(.serif)
                        .font(.system(size: 25))
                        .foregroundStyle(Color.primary)
                        .padding(15)
                    }
                .opacity(inicialScreen ? 0 : 1)
                
            }
            .navigationTitle("Leer QR de la galería")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    
    
    //Lee una UIImage y decodifica su QR si existe, si falla retorna nil
    func detectQRCode(_ image: UIImage?) -> [CIFeature]? {
        if let image = image, let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            let features = qrDetector?.features(in: ciImage, options: options)
            return features

        }
        return nil
    }
   
    
}


#Preview {
    QRLoadFromGaleryView()
}

//
//  QRReader.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 5/2/24.
//

import SwiftUI
import CodeScanner


struct ReadQRCode : View {
    @Environment(\.colorScheme) var theme
    @State private var showQRScanner = false
    @State private var showQRGenerate = false
    @State private var textQR = ""
    //Para el Alert
    @State private var showAlert = false
    @State private var message = ""
    @State private var textArray  = [String]()
    
    
    
    var body: some View {
        
        NavigationStack{
            ZStack{
                
                LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                
                VStack(spacing: 10){
                    
                    Text("El lector le permite obtener el texto de un código QR. Necesita permisos de la cámara")           .fixedSize(horizontal: false, vertical: true)
                        .fontDesign(.serif)
                        .padding(.horizontal, 15)
                        .padding(.bottom, textQR == "" ? 250 : 40)
                    
                    
                    Button{
                        textQR = ""
                        showQRScanner = true
                    }label: {
                        VStack(spacing: 10){
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .tint(theme == .dark ? .white : .primary)
                                .symbolEffect(.pulse, isActive: true)
                            Text("Toque la imagen para escanear")
                                .fontDesign(.serif)
                                .bold()
                                .foregroundStyle(theme == .dark ? .white : .primary)
                        }
                        
                    }
                    
                    ScrollView {
                        Text(textQR)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.orange)
                    }
                    
                    
                    //Grupo de opciones
                    if !textQR.isEmpty {
                        VStack(spacing: 12){
                            Button{
                                //Determinar si la nota tiene un formato de Nota
                                if textArray.count == 4 {
                                    
                                    if NotasModel().addNote(nota: textArray[2], title: textArray[1], isFav:  textArray[3] == "Si" ? true : false){
                                        message = "Se ha importado a Notas"
                                        showAlert = true
                                    }
                                    
                                }else{
                                    if  NotasModel().addNote(nota: textQR, title: "QR_Lector \(Date.now)", isFav: false) {
                                        message = "Se ha importado a Notas"
                                        showAlert = true
                                        
                                    }else{
                                        message = "No se ha podido importar la nota"
                                    }
                                }
                                
                                
                            }label: {
                                Text("Importar a Notas")
                                    .foregroundStyle(.black)
                            }
                            .modifier(GradientButtonStyle(ancho: 200, colors: [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a), SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]))
                            
                            Button{
                                FrasesModel().AddFrase(frase: textQR)
                                self.message = "La frase ha sido importada"
                                showAlert = true
                            }label: {
                                Text("Importar a Frases")
                                    .foregroundStyle(.black)
                            }
                            .modifier(GradientButtonStyle(ancho: 200, colors: [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a), SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]))
                            
                            
                            Button{
                                //Copiar el texto al portapapeles
#if os(iOS)
                                UIPasteboard.general.string = textQR
#endif
                                
#if os(macOS)
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(textQR, forType: .string)
#endif
                            }label: {
                                Text("Copiar al portapales")
                                    .foregroundStyle(.black)
                            }
                            .modifier(GradientButtonStyle(ancho: 200, colors: [SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a), SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)]))
                            .padding(.bottom, 20)
                            
                            
                        }
                        .padding(.bottom, 40)
                    }
                    
                }
            }
            
            .navigationTitle("Lector de código QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button{
                    showQRGenerate = true
                }label: {
                    Image(systemName: "qrcode")
                        .tint(Color.primary)
                }
            }
            .sheet(isPresented: $showQRScanner){
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }
            .sheet(isPresented: $showQRGenerate){
                GenerateQRView(footer: textQR, showImage: true)
            }
            .alert(isPresented: $showAlert){
                Alert(title: Text("Lector de código QR"), message: Text(message))
            }
        }
    }
    
    
    
    func handleScan(result : Result<ScanResult, ScanError>){
        showQRScanner = false
        switch result {
        case .success(let resulta):
            
            //Determinar si el texto es una nota
            let textoArray = resulta.string.components(separatedBy: ">>")
            
            if textoArray.count == 4 {
                if textoArray[0] == "nota" && (textoArray[3] == "isfav:No" || textoArray[3]=="isfav:Si"){
                    // Habilitar el botón de notas
                    textArray.removeAll()
                    textArray = textoArray
                }
            }
            textQR = resulta.string
        case .failure(let error):
            message = "Error al leer el código QR: \(error.localizedDescription)"
            showAlert = true
        }
        
    }
    
    
}

#Preview {
    ReadQRCode()
}


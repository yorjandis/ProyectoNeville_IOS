//
//  ReadQRCode.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Read QR Code

import SwiftUI
import CodeScanner


struct ReadQRCode : View {
    @Environment(\.colorScheme) var theme
    @State private var showQRScanner = false
    @State private var textQR = ""
    //Para el Alert
    @State private var showAlert = false
    @State private var message = ""
    
   
    
    var body: some View {
        
        NavigationStack{
            ZStack{
                
                LinearGradient(colors: [.black.opacity(0.5), .brown.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                
                VStack(spacing: 10){
                    
                Text("El lector le permite obtener el texto de un código QR. Necesita permisos de la cámara")           .fixedSize(horizontal: false, vertical: true)
                        .fontDesign(.serif)
                        .padding(.horizontal, 15)
                    .padding(.bottom, textQR == "" ? 250 : 100)
                
            
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
                    }
                    
                    //Grupo de opciones
                    if !textQR.isEmpty {
                        VStack(spacing: 20){
                            Button{
                                if  NotasModel().addNote(nota: textQR, title: "QR_Lector", isFav: false) {
                                    message = "Se ha importado a Notas"
                                    showAlert = true
                                    
                                }else{
                                    message = "No se ha podido importar la nota"
                                }
                                
                            }label: {
                                Text("Importar a Notas")
                            }
                            .modifier(GradientButtonStyle(ancho: 200))
                            
                            
                            Button("Copiar al portapales"){
                                //Copiar el texto al portapapeles
                                #if os(iOS)
                                UIPasteboard.general.string = textQR
                                #endif
                                
                                #if os(macOS)
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(textQR, forType: .string)
                                #endif
                            }
                            .modifier(GradientButtonStyle(ancho: 200))
                            .padding(.bottom, 20)
                            
                        }
                        .padding(.bottom, 40)
                    }
                    
                }
            }
            
            .navigationTitle("Leer código QR")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQRScanner){
                CodeScannerView(codeTypes: [.qr], completion: handleScan)
            }
            .alert(isPresented: $showAlert){
                Alert(title: Text("Lectura QR"), message: Text(message))
            }
        }
        }
    
    
    
    func handleScan(result : Result<ScanResult, ScanError>){
        showQRScanner = false
        switch result {
        case .success(let resulta):
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



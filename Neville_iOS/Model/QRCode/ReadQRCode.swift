//
//  ReadQRCode.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 6/11/23.
//
//Read QR Code


import CodeScanner
import SwiftUI


struct ReadQRCode : View {
    
    @State private var showQRScanner = false
    @State private var textQR = ""
    
    var body: some View {
        
        NavigationStack{
            VStack(spacing: 10){
                    Text("El lector de QR le permite obtener el texto de un Código QR. Necesita permiso para usar la cámara.")
                    .multilineTextAlignment(.center)
                        .bold()
                        .padding(.horizontal, 10)
                        .padding(.bottom, 200)
                    
                    Button{
                        showQRScanner = true
                    }label: {
                        VStack(spacing: 10){
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 80))
                                .tint(.cyan)
                            Text("Toque la imagen para escanear")
                        }
                        
                    }
                Spacer()
                
                
                VStack(spacing: 10){
                    
                    Button{
                        
                    }label: {
                        Text(textQR)
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    Button{
                        //Importar a notas yor
                        
                    }label: {
                        Text("Importar a Notas")
                    }
                    .modifier(GradientButtonStyle(ancho: 200))
                    .opacity(textQR == "" ? 0 : 1)
                    
                    
                
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
                    .opacity(textQR == "" ? 0 : 1)
                }
                
                
                    
                    
                    
                    
                   
                }
                .frame(alignment: .center)
                .navigationTitle("Leer código QR")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showQRScanner){
                    CodeScannerView(codeTypes: [.qr, .ean13], completion: handleScan)
                }
        }
        
        
      
        
    }
    
    
    func handleScan(result : Result<ScanResult, ScanError>){
        showQRScanner = false
        switch result {
        case .success(let resulta):
            textQR = resulta.string
        case .failure(let error):
            print("No se ha podido leer el código QR: \(error.localizedDescription)")
            
            
        }

    }
    
    
}

#Preview {
    ReadQRCode()
}



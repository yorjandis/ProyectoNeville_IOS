//
//  DescargoResponsabilidad.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 4/11/25.
//

import SwiftUI

//Texto de descargo de responsabilidad
@available(iOS 26.0, macOS 26.0, *)
@MainActor
struct DescargoResponsabilidadIA : View{
    @Environment(\.dismiss) var dismiss
    @AppStorage(AppCons.UD_setting_AceptacionDescargoIA)    var DescargoDeIA : Bool = false // True para aceptar, false para rechazo
    
    //Uso de dismiss
    let VentanaEnSetting: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 15){
            Text(AppCons.DescargoDeResposabilidad)
            .font(.body).fontDesign(.serif)
            HStack{
                if self.DescargoDeIA == false{
                    Button("Acepto"){
                        withAnimation(.easeIn(duration: 0.5)) {
                            self.DescargoDeIA = true
                            if self.VentanaEnSetting == true{
                                #if os(macOS)
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                                #else
                                dismiss()
                                #endif
                            }
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.blue)
                }else{
                    Button("No acepto"){
                            self.DescargoDeIA = false
                        if self.VentanaEnSetting == true{
                            #if os(macOS)
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                            }
                            #else
                            dismiss()
                            #endif
                        }
                    }
                    .buttonStyle(.glass)
                    .tint(.red)
                }
                
            }
            .padding()
            
            Spacer()
            
        }
        .padding()
    }
    
}

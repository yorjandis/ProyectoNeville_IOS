//
//  LogginView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

// Ventana para poner la contraseña que da acceso al Diario y a las notas protegidas en los dispositivos que no admiten autenticación
// biométrica (macMini por ejemplo)

import SwiftUI

enum typeEnte : String{
    case Diario, Notas, AccesoANotasAjustes, AccesoADiarioAjustes
}

struct LogginView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var securityModel : SecurityModel
    
    @AppStorage("setting_DiarioAccesoAjustes") var setting_DiarioAccesoAjustes  : Bool = false

    let ente: typeEnte

    @State private var password: String = ""

    @FocusState private var focus: Bool
    @State private var attempts = 0  // lo usamos para reiniciar la animación

    var body: some View {
        VStack {
            Text("Desbloquear \(self.ente.rawValue)")
                .font(.title) // ente puede ser: "Diario" o "Notas"

            SecureField("", text: self.$password, prompt: Text("Coloque la contraseña"))
                .font(.title)
                .focused(self.$focus)
                .modifier(ShakeEffect(animatableData: CGFloat(attempts))) //Provoca una animación de shake (si entramos mal la contraseña)
                .animation(.default, value: attempts)
                .onSubmit {
                    // Evento de click enter, en macOS
                    validar()
                }
                .onAppear{
                    self.focus = true
                }

            HStack {
                Button("Acceder") {
                    validar()
                }
                .buttonStyle(.bordered)
                .tint(.green)

                Spacer()

                Button("Cancel") {
                    #if os(macOS)
                    if let window = NSApp.keyWindow {
                        closeWindow(window)
                    }
                    #else
                    dismiss()
                    #endif
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .padding()
        #if os(macOS)
        .frame(height: 400)
        #endif
    }

    //Valida la contraseña
    private func validar() {
        if let value = KeychainHelper.shared.getPassword() { //Obteniendo la contraseña del llavero
            if value == self.password { // La contraseña es válida
                
                //self.canOpen = true // Se pasa true al llamador
                
                switch self.ente {
                case .Diario:
                    securityModel.canOpenDiario = true
                case .Notas:
                    securityModel.canOpenNotas = true
                case .AccesoANotasAjustes:
                    print("Acceso a la opción de las notas protegidas en Ajustes")
                case .AccesoADiarioAjustes:
                    self.setting_DiarioAccesoAjustes = true
                    
                }
                
                
                #if os(macOS)
                if let window = NSApp.keyWindow {
                   closeWindow(window)
                }
                
                #else
                dismiss()
                #endif
            } else { // No es válida
                self.attempts += 1 //Animación shake
                
                switch self.ente {
                case .Diario:
                    securityModel.canOpenDiario = false
                case .Notas:
                    securityModel.canOpenNotas = false
                case .AccesoANotasAjustes:
                    print("Acceso protegido a las Notas en Ajustes")
                case .AccesoADiarioAjustes:
                    self.setting_DiarioAccesoAjustes = false
                }
                
                
                self.focus = true
            }
        } else {
            self.attempts += 1 //Animación shake
            
            switch self.ente {
            case .Diario:
                securityModel.canOpenDiario = false
            case .Notas:
                securityModel.canOpenNotas = false
            case .AccesoANotasAjustes:
                print("Acceso protegido a las Notas en Ajustes")
            case .AccesoADiarioAjustes:
                self.setting_DiarioAccesoAjustes = false
            }
            
            self.focus = true
        }
    }
}

// Estructura  que permite establecer un efecto shake sacudida en

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8       // Range of motion
    var shakesPerUnit = 3          // Number of shake
    var animatableData: CGFloat    // Controls the progress of the animation

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(
                translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),  y: 0
            )
        )
    }
}

#Preview {
    // Ejemplo de uso con un binding constante para previsualización.
    LogginView(ente: .Diario)
    
    
}




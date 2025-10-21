//
//  LogginView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

// Ventana para poner la contraeña que da acceso al Diario y a las notas protegidas en los dispositivos que no admiten autenticación
// biométrica (macMini por ejemplo)

import SwiftUI

struct LogginView: View {
    @Environment(\.dismiss) private var dismiss

    let ente: String

    @State private var password: String = ""
    @Binding var canOpen: Bool

    @FocusState private var focus: Bool
    @State private var attempts = 0  // lo usamos para reiniciar la animación

    var body: some View {
        VStack {
            Text("Desbloquear \(self.ente)")
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
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding()
        }
        .padding()
    }

    //Valida la contraseña
    private func validar() {
        if let value = KeychainHelper.shared.getPassword() {
            if value == self.password { // La contraseña es válida
                self.canOpen = true // Se pasa true al llamador para que abra el Diario
                dismiss()
            } else { // No es válida
                self.attempts += 1
                self.canOpen = false // Se pasa false al llamador para que no abra el Diario
                self.focus = true
            }
        } else {
            self.attempts += 1
            self.canOpen = false // Se pasa false al llamador para que no abra el Diario
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
     LogginView(ente: "Diario", canOpen: .constant(false))
    
    
}




//
//  CreatePasswordView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

//esta ventana se encarga de registrar un nuevo pasword. Si existe uno anterior se borra del lllavero del sistema


import SwiftUI

struct CreatePasswordView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var password : String = ""
    @State private var password2 : String = ""
    @State private var showAlert : Bool = false

    
    var body: some View {
        ScrollView {
            VStack(alignment: .center){
                Text("Este dispositivo parece no tener soporte biométrico. El acceso al Diario y las notas protegidas se realizará mediante contraseña. Por favor, introduce una contraseña para habilitar estas funciones:")
                    .font(.title)
                    .padding()
                VStack(alignment: .leading){
                    SecureField("", text: self.$password, prompt: Text("Coloque una contraseña"))
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Repita la contraseña:")
                    SecureField("", text: self.$password2, prompt: Text("Repita la contraseña"))
                        .font(.system(size: 24, weight: .bold))
                }
                
                
                Text("La contraseña se almacena cifrada en el llavero del sistema. Se le pedirá siempre que acceda al diario y para bloquear/desbloquear las notas")
                    .font(.title)
                    .padding()
                
                HStack(){
                    Button("Cancelar"){
                        #if os(macOS)
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                        }
                        #else
                        dismiss()
                        #endif
                    }.buttonStyle(.bordered)
                        .tint(.red)
                    
                    Spacer()
                    
                    Button("Crear Contraseña"){
                        if ( !self.password.isEmpty  && self.password == self.password2){
                            KeychainHelper.shared.savePassword(self.password)
                            #if os(macOS)
                            if let window = NSApp.keyWindow {
                                closeWindow(window)
                            }
                            #else
                            dismiss()
                            #endif
                        }else{
                            //Las cotraseñas no coinciden. Muestra un mensaje de alerta
                            self.showAlert = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.primary)
                }.padding(.vertical, 50)
                
                
                Text("Nota: Si olvida la contraseña, puede recuperarla utilizando el botón Recuperar Contraseña en la ventana de Ajustes (Setting). Este botón solo esta disponible en dispositivos con autenticación biométrica, como un iPhone o una macBook con biometría. Se le pedirá que se autentifique con touchID o FaceID")
                    .font(.title)
                
                Spacer()
                
            }
            .padding()
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("Ups! Contraseña no coinciden"), message: Text("Las contraseñas no coinciden, por favor revise el texto"), dismissButton: .default(Text("Aceptar")) )
            }
        }
        #if os(macOS)
        .frame(width: 550, height: 400)
        #endif
    }
}


#Preview {
    CreatePasswordView()
}

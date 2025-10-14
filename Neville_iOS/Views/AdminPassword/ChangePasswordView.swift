//
//  ChangePasswordView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

import SwiftUI

struct ChangePasswordView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var oldpassWord: String = ""
    @State private var newPassWord: String = ""
    
    @State private var showAlert : Bool = false
    @State private var messageAlert : String = ""
    
    
    var body: some View {
        NavigationStack {
            VStack{
                Text("Si considera que su contraseña anterior no es lo bastante robusta o si ha sido vulnerada. Utilice esta opción para cambiarla")
                    .font(.title)
                
                VStack(alignment: .leading){
                    Section(header: Text("Contraseña actual")){
                        SecureField("Escriba aquí", text: $oldpassWord).font(.system(size: 24))
                    }
                    Section(header: Text("Nueva contraseña")){
                        SecureField("Escriba aquí", text: $newPassWord).font(.system(size: 24))
                    }
                }
                .navigationBarTitle("Cambiar contraseña")
                .padding()
                
                HStack{
                    Button("Guardar"){
                        if let clave = KeychainHelper.shared.getPassword(){
                            
                            if clave == self.oldpassWord{
                                //Cambiando la contraseña
                                KeychainHelper.shared.savePassword(self.newPassWord)
                                self.messageAlert = "La Contraseña ha sido cambiada"
                            }else{
                                self.messageAlert = "La contraseña es incrorrecta"
                            } 
                        }else{
                            self.messageAlert = "No se pudo obtener la contraseña"
                            
                        }
                        
                        self.showAlert = true
                      }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    
                    Spacer()
                    
                    Button("Salir"){
                          dismiss()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }.padding()
               Spacer()
            }
        }
        .alert(isPresented: self.$showAlert) {
            Alert(title: Text("Cambiar Contraseña"), message: Text(self.messageAlert), dismissButton: .default(Text("OK")))
        }
    }
    
}


#Preview {
    ChangePasswordView()
}

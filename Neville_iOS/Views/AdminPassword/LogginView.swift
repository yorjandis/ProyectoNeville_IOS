//
//  LogginView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

//Ventana para poner la contraeña que da acceso al Diario y a las notas protegidas en los dispositivos que no admiten autenticación
//biométrica (macMini por ejemplo)

import SwiftUI


struct LogginView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let ente : String
    
    @State private var password : String = ""
    
    
    @Binding var canOpen : Bool
    
    var body: some View {
        VStack{
            
            Text("Desbloquear \(self.ente)").font(.title) //ente puede ser: "Diario" o "Notas"
            
            SecureField("", text: self.$password, prompt: Text("Coloque la contraseña")).font(.title)
            
            HStack{
                Button("Acceder"){
                    if let value = KeychainHelper.shared.getPassword(){
                        if value == self.password { //La contraseña es válida
                            self.canOpen = true //Se pasa true al llamador para que habra el Diario
                        }else{ //No es válida
                            self.canOpen = false //Se pasa false al llamador para que no habra el Diario
                        }
                    }else{
                        self.canOpen = false //Se pasa false al llamador para que no habra el Diario
                    }
                    
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.green)
                
                Spacer()
                
                Button("Cancel"){
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.red)
               
                
            }.padding()
            
            
        }
        .padding()
    }
}



#Preview {
    //LogginView(ente: "Diario", clave: .constant(true))
}

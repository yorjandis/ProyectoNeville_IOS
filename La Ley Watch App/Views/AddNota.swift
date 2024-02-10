//
//  AddNota.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 8/2/24.
//

import Foundation
import SwiftUI


struct AddNota : View {
    
    @State private var title : String = ""
    @State private var texto : String = ""
    @State private var isfav : Bool = false
    @State private var showAlert = false
    @State private var alertMesage = ""
    @State private var isWorking = false
    
    
    var body: some View {
        ZStack {
            VStack(spacing: 10){
                Text("Nueva Nota")
                    .foregroundStyle(.orange).bold()
                    .padding(.top, 5)
                Divider()
                    .padding(.top, 20)
                ScrollView{
                    
                    TextFieldLink("título: \(title)", prompt: Text("Título de nota")) { str in
                        title = str
                    }
                    .frame(width: .infinity ,  height: 40)
                    .cornerRadius(20)
                    .padding([.leading, .trailing], 5)
                    
                    TextFieldLink("Nota: \(texto)", prompt: Text("Título de nota")) { str in
                        texto = str
                    }
                    .frame(width: .infinity ,  height: 40)
                        .cornerRadius(20)
                        .padding([.leading, .trailing], 5)
                    
                    
                    Toggle(isOn: $isfav, label: {
                        Text("Favorito")
                    })
                    .padding(.horizontal, 10)
                    
                    Button{
                        Task{
                            if title.isEmpty || texto.isEmpty {
                                self.alertMesage = "Debe colocar un titulo y un texto para la nota" ; showAlert = true
                            }else{
                                self.isWorking = true //Oculta el botón
                                let result = await iCloudNotas().add(title: self.title, nota: self.texto, isfav: isfav ? 1 : 0)
                                if  result {
                                    self.alertMesage = "Nota Guardada!" ; showAlert = true
                                }else{
                                    self.alertMesage = "No se ha podido guardar la nota. Inténtelo de nuevo" ; showAlert = true
                                 
                                }
                                self.isWorking = false //Muestra el botón
                                
                            }
                             
                        }
                        
                    }label: {
                        Label("Guardar", systemImage: "plus")
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .opacity(self.isWorking ? 0 : 1)
                    .overlay(content: { if self.isWorking { ProgressView() }
                    })
                    .padding([.horizontal, .vertical])
                    .buttonStyle(PlainButtonStyle())
                }
               
                   
            }
            
        }
        .ignoresSafeArea()
        .alert(isPresented: $showAlert, content: {
            Alert(title: Text("Notas"), message: Text(self.alertMesage))
        })
        
    }
}


#Preview {
    AddNota()
}

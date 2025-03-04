//
//  AddDiario.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 9/2/24.
//

import SwiftUI

struct AddDiario: View {
    private let context  = CoreDataController.shared.context
    @StateObject private var modelWatch = watchModel.shared
    @Environment(\.dismiss) private var dismiss
    
        @State private var title        : String = ""
        @State private var content      : String = ""
        @State private var isfav        : Bool = false
        @State private var selection    = Emoticono.neutral
        @State private var showSheet    = false
        @State private var showAlert    = false
        @State private var alertMessage = ""
        @State private var isWorking    = false
        
        
        var body: some View {
            ZStack {
                VStack(spacing: 10){
                    Text("Nueva Entrada")
                        .foregroundStyle(.orange).bold()
                        .padding(.top, 5)
                    Divider()
                    .padding(.top, 20)
                    ScrollView{
                        HStack{
                            Text(selection.rawValue).font(.system(size: 30))
                                .onTapGesture {
                                    self.showSheet = true
                                }
                            
                            TextFieldLink("título: \(title)", prompt: Text("Título de la entrada")) { str in
                                title = str
                            }
                            .frame(width: .infinity ,  height: 30)
                            .cornerRadius(20)
                            .padding([.leading, .trailing], 5)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal)
                            
                        
                        
                        TextFieldLink("contenido: \(self.content)", prompt: Text("Contenido de la entrada")) { str in
                            self.content = str
                        }
                        .frame(width: .infinity ,  height: 30)
                        .cornerRadius(20)
                        .padding([.leading, .trailing], 5)
                                    
                        
                        Toggle(isOn: $isfav, label: {
                            Text("Favorito")
                        })
                        .padding(.horizontal, 10)
                        
                        Button{
                            Task{
                                if self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    self.alertMessage = "Debe colocar un título y un texto para la entrada"
                                    showAlert = true
                                }else{
                                    //Crear una entrada de Diario y guardarla
                                    let newDiario = Diario(context: self.context)
                                    newDiario.id = UUID()
                                    newDiario.title = self.title
                                    newDiario.content = self.content
                                    newDiario.isFav = self.isfav
                                    newDiario.emotion = self.selection.rawValue
                                    newDiario.fecha = Date.now
                                    newDiario.fechaM = Date.now
                                    
                                    do{
                                        try context.save()
                                    }catch{
                                        context.rollback()
                                    }
                                    //Actualizar el listado
                                    modelWatch.getDiarioEntradas()
                                    dismiss()
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
                        .overlay(content: { if self.isWorking { ProgressView()}})
                        .padding([.horizontal, .vertical])
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    
                }
                
            }
            .ignoresSafeArea()
            .alert(isPresented: $showAlert, content: {
                Alert(title: Text("Diario"), message: Text(self.alertMessage))
            })
            .sheet(isPresented: $showSheet, content: {
                emotico()
            })
            
        }
    
   //Construye una vista de seleccion para los emoticonos
  @ViewBuilder
    func emotico()->some View{
        ScrollView{
            ForEach (Emoticono.allCases, id: \.self) {i in
                 
                Button{
                    selection = i
                    self.showSheet = false
                }label: {
                    HStack{
                        Text(i.rawValue)
                            .font(.system(size: 40))
                            .padding(.vertical, 5)
                        
                        Text(i.txt)
                        Spacer()
                    }.padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    

    enum Emoticono:String, CaseIterable{
        case feliz = "😃", neutral = "🙂", enfadado = "😤", sorpresa = "😲", distraido = "🙄",desanimado = "😔"
        var txt : String{
            switch self{
            case .desanimado : "desanimado"
            case .distraido : "distraido"
            case .enfadado : "enfadado"
            case .feliz : "feliz"
            case .neutral : "neutral"
            case .sorpresa : "sorpresa"
            }
        }
    }
   
}


#Preview {
    AddDiario()
}

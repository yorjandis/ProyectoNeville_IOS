//
//  GamePLay.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/11/23.
//

import SwiftUI

struct GamePLay: View {
    @Environment(\.dismiss) var dimiss


    @State private var Fallos = 0
    @State private var Aciertos = 0
    
    @State private var pregunta = lista().listado.randomElement()?.pregunta
    
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom){
                
                LinearGradient(colors: [.brown, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
                
                VStack{
                    Spacer()
                    
                    Text(pregunta ?? "")
                        .font(.system(size: 40)).bold()
                        .fontDesign(.serif)
                    
                    Spacer()
                    
                    
                    VStack{
                        
                        HStack{
                            Button{
                                withAnimation {
                                    pregunta = lista().listado.randomElement()?.pregunta
                                }
                            }label: {
                                Text("Verdadero")
                                    .foregroundStyle(.white)
                                    
                            }
                            .frame(width: 100)
                            .padding()
                            .background(.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                            Button{
                                withAnimation {
                                    pregunta = lista().listado.randomElement()?.pregunta
                                }
                            }label: {
                                Text("Falso")
                                    .foregroundStyle(.white)
                                    
                            }
                            .frame(width: 100)
                            .padding()
                            .background(.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                            
                        }
                        
                        Button{
                            withAnimation {
                                pregunta = lista().listado.randomElement()?.pregunta
                            }
                        }label: {
                            Text("Siguiente")
                                .foregroundStyle(.white)
                                
                        }
                        .padding()
                        .background(.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                    }
                    
                    
                    
                    
                    
                    HStack(spacing: 20){
                        Text("Fallos:\(Fallos)")
                            
                        Text("Aciertos:\(Aciertos)")
                            
                    }
                    .font(.system(size: 30))
                    .bold()
                }
   
                    }
                }
            }
    
    
    func checkValue(pregunta : Pregunta, buttonSi : Bool ){
        
        if buttonSi {
            if pregunta.isCorrect{
                
                Aciertos += 1
            }else{
                Fallos += 1
            }
        }else{
            
            if !pregunta.isCorrect{
                Aciertos += 1
            }else{
                Fallos += 1
            }
            
        }

    }
    
    
        }
 
    


class Pregunta : ObservableObject, Identifiable{
    var id: UUID = UUID()
    let pregunta : String
    let isCorrect : Bool
    var isVisible : Bool = true
    
    init(pregunta: String, isCorrect: Bool) {
        self.pregunta = pregunta
        self.isCorrect = isCorrect
    }
    
    
}

struct lista{
    

     let listado = [         Pregunta(pregunta: "Imaginar Crea la realidad", isCorrect: true),
                                   Pregunta(pregunta: "La realidad esta sujeta a nuestros sentidos físicos", isCorrect: false),
                                   Pregunta(pregunta: "Podemos cambiar el pasado", isCorrect: true),
                                   Pregunta(pregunta: "La Biblia es un libro de historia antigua", isCorrect: false),
                                   Pregunta(pregunta: "Jesús Cristo vivió hace 2000 años", isCorrect: false)
         ]
    
}



#Preview {
    GamePLay()
}

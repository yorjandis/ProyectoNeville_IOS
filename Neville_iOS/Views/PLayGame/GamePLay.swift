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
    
    @State private var pregunta : Pregunta = Pregunta(pregunta: "", isCorrect: false, comentario: "")
    @State private var listado : [Pregunta] = GameModel().getList()
    @State private var text = ""
    @State private var comentario = ""
    
    //Para circulo
    @State private var total = 0
    @State private var trim : CGFloat = 0
    
    //Salir del texto inicial
    @State private var opaci : Double = 1
    
    @State private var showHide = false
    //Para animación
    @State private var showBubbles = false
    @State private var showAnimation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom){
                    
                LinearGradient(colors: [.brown, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
                
                    .overlay {
                        VStack(spacing : 10){
                            Text("Se mostrará una serie de afirmaciones. Utilice los botones inferiores para decidir si son ciertas o falsas")
                                .foregroundStyle(.black)
                                .font(.system(size: 24)).bold().italic()
                                .fontDesign(.serif)
                                .multilineTextAlignment(.center)
                            Button("Comenzar!"){
                                self.listado.removeAll()
                                self.listado = GameModel().getList()
                                self.total = self.listado.count
                                self.getNextPregunta()
                                self.opaci = 0
                            }
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                                
                        }
                        .padding(5)
                        .opacity(opaci)
                    }
                    
                
                VStack{
                    Spacer()
                    
                    VStack {
                        Text(text)
                            .foregroundStyle(.black)
                            .bold().italic()
                            .fontDesign(.serif)
                            .font(.system(size: 30))
                            
                        .padding(.horizontal, 8)
                        //Texto de comentario: se pone a "" si esta invisible: showHide = false
                        Text(self.showHide ? self.comentario : "")
                            .foregroundStyle(.black)
                            .opacity(self.showHide ? 1 : 0)
                            .onTapGesture {
                                withAnimation {
                                    self.comentario = ""
                                    self.showHide = false
                                }
                                
                            }
                        HStack{
                            Spacer()
                            Button{
                                withAnimation {
                                    self.comentario = self.pregunta.comentario
                                    self.showHide.toggle()
                                }
                            }label: {
                                Image(systemName: "ellipsis")
                                    .foregroundStyle(.black)
                                    .opacity(self.opaci == 1 ? 0 : 1)
                                    
                            }
                        }
                        .padding(.trailing, 25)
                        
                    }
                    
                    Spacer()
                    
                    
                    VStack{
                        
                        HStack{
                            
                            Button{
                                showAnimation = true
                                showBubbles = true
                                
                                
                                if self.opaci != 1 {
                                    checkValue(pregunta: self.pregunta, buttonSi: false)
                                    self.getNextPregunta()
                                }
                            }label: {
                                Text("Falso")
                                    .foregroundStyle(.white)
                                    
                            }
                            .frame(width: 100)
                            .padding()
                            .background(.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))
                            
                            Button{
                                if self.opaci != 1 {
                                    checkValue(pregunta: self.pregunta, buttonSi: true)
                                    self.getNextPregunta()
                                }
                                
                            }label: {
                                Text("Cierto")
                                    .foregroundStyle(.white)
                                    
                            }
                            .frame(width: 100)
                            .padding()
                            .background(.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 20, height: 10)))

                            
                        }
                        
                        HStack(spacing: 20){
                            Text("Fallos:\(Fallos)")
                            Text("Aciertos:\(Aciertos)")
                        }
                        .foregroundStyle(.black)
                        .font(.system(size: 30))
                        .bold()
                    }
                    .opacity(self.opaci == 1 ? 0 : 1)

                }
                
                Circle()
                //.trim(from: 0, to: 0.8)
                    .stroke(lineWidth: 30)
                    .rotation(Angle(degrees: 180))
                    .offset(y: 350)
                    .foregroundStyle(Color.black.opacity(0.3))
                
                Circle()
                    .trim(from: 0, to: trim)
                    .stroke(lineWidth: 30)
                    .rotation(Angle(degrees: 180))
                    .offset(y: 350)
                    .foregroundStyle(Color.black.opacity(0.7))
                
                
                
            }
            .navigationTitle("Compruebe lo que sabe")
            .navigationBarTitleDisplayMode(.inline)
        }
        
        
        
    }

    //Muestra la proxima pregunta y hace los ajustes necesarios
    func getNextPregunta(){
        if listado.count >= 1 {
            if let result = listado.randomElement(){
                let index = listado.firstIndex(of: result)
                listado.remove(at: index!)
                self.pregunta = result
                withAnimation {
                    self.comentario = ""
                    self.showHide = false
                    self.text = result.pregunta
                    self.trim += CGFloat((180/Double(total))/355)
                }
            }
            
        }else{ //terminó la ronda
            
            withAnimation {
                self.text = ""
                self.opaci = 1
                self.trim = 0
                self.Aciertos = 0
                self.Fallos = 0
            }
            
        }
        
        
    }
    
    
    
    //Función que evalua una pregunta
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
 
    






#Preview {
    GamePLay()
}

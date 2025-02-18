//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    
    @State private var selectedTab = 1
    
    var body: some View {
      TabView(selection: $selectedTab) {
          
          NavigationStack{
              VStack{
                  Frases()
                  .ignoresSafeArea()
              }
              
          }.tag(1)
          NavigationStack{
              VStack{
                  DiarioView()
                      .ignoresSafeArea()
              }
              
          }.tag(2)
          
          NavigationStack{
              VStack{
                  NotasView()
                      .ignoresSafeArea()
              }
              
          }.tag(3)
             
      }
      
      .tabViewStyle(.page)
                
                
    }
    
   //Vistas
    struct DiarioView: View {
        
        @StateObject private var modelWatch = watchModel.shared
        
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""
        
        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Diario")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    
                    HStack{
                        Button{
                            Task{
                                modelWatch.getDiarioEntradas()
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        
                        
                        Spacer()
                        
                        Button{
                            self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                             AddDiario()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    
                    List{
                        ForEach(modelWatch.listDiario, id: \.id) {diario in
                            NavigationLink{
                                ScrollView {
                                    Text(diario.content ?? "")
                                }
                            }label: {
                                VStack {
                                    HStack{
                                        Text(emotion(diario.emotion ?? ""))
                                            .font(.system(size: 28))
                                        Text(diario.title ?? "")
                                            .foregroundStyle(.black)
                                        Spacer()
                                    }
                                    Text((diario.fecha ?? Date.now).formatted(date: .long, time: .omitted))
                                        .font(.system(size: 10, weight: .medium, design: .serif)).foregroundStyle(.black)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } 
                            }
                        }
                    }
                }
            }
            .alert(isPresented : $showAlert){
                Alert(title: Text("Diario"), message: Text(self.alertMessage))
            }
            .sheet(isPresented: $showSheetOptionsFilter) {
               FilterByDiarioView()
            }
        }
        
        //Aux: Devuelve el emoticono segun el texto: Para funciones de filtrado
        private func emotion(_ txt: String)->String{
            switch txt {
            case "neutral"      : "🙂"
            case "feliz"        : "😃"
            case "enfadado"     : "😤"
            case "desanimado"   : "😔"
            case "sorpresa"     : "😲"
            case "distraido"    : "🙄"
            default: ""
            }
        }
    }
    

    struct Frases : View {
        @State private var frase : String = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
        var body: some View {
            ZStack{
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack(alignment: .center){
                    Text("La Ley").bold()
                        .padding(.bottom, 10)
                    ScrollView{
                        Text(frase)
                            .italic()
                            .padding(.horizontal, 5)
                            .padding(.bottom, 20)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .onTapGesture {
                                frase = UtilFuncs.FileReadToArray("listfrases").randomElement() ?? ""
                            }
                    }
                    
                }
                .padding(.top, 10)
                .fontDesign(.serif)
                .font(.system(size: 20))
                .foregroundStyle(.black)
            }
            
        }
    }
    
    struct NotasView: View {
        @StateObject private var modelWatch = watchModel.shared
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""
        
        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Notas")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    HStack{
                        Button{
                            Task{
                                modelWatch.getNotas()
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button{
                           self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        } .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                            AddNota()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    
                    List(modelWatch.listNotas, id: \.id){ nota in
                        NavigationLink{
                            ScrollView {
                                Text(nota.nota ?? "")
                            }
                        }label: {
                            Text(nota.title ?? "").fontDesign(.serif).foregroundStyle(.black)
                                .frame(height: 10)
                        }
                        .swipeActions(edge: .trailing){
                            Button{
                                if modelWatch.deleteNota(nota: nota) {
                                    self.alertMessage = "Nota Eliminada"
                                    modelWatch.getNotas() //Actualiza los listados
                                }else{
                                    self.alertMessage = "Error al Eliminar Nota"
                                }
                                
                                self.showAlert = true
                            }label: {
                                Image(systemName: "trash")
                                    .tint(.red)
                            }
                        }
                        
                    }
                    .overlay(content: { //Muestra una barra de progreso si hay una tarea async ejecutándose...
                        if self.asyncIsWorking {
                            ProgressView()
                        }
                    })
                }
                
            }
            .sheet(isPresented: $showSheetOptionsFilter, content: {
                 FilterByNotaView()
            })
            
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("La Ley"), message: Text(self.alertMessage))
            }
        }
        
        
    }
    
}





#Preview {
    ContentView()
}

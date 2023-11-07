//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData

struct DiarioListView: View {
    
    @State private var list : [Diario] = DiarioModel().getAllItem()
    
    let titlesExamples : [(String,String)] = [
    ("Revisión de este día", "neutral"),
    ("¿Como me he sentido hoy?", "nautral" ),
    ("Hoy agradezco:", "feliz"),
    ("¿Que debo mejorar?", "desanimado"),
    ("¿Que he aprendido hoy?","neutral"),
    ("Mi vida es maravillosa porque...", "feliz"),
    ("!Hoy se ha materializado un deseo!","feliz") ]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.cyan , .indigo], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView(.vertical){
                    ForEach($list){ item in
                        cardItem(diario: item, list: $list)
                            .padding(15)             
                            .frame(width: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black , radius: 10)
                            .padding(.horizontal, 15)
                            
                    }
                    
                }
                
                .scrollIndicators(.hidden)
                .navigationTitle("Diario")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    HStack{
                        Button(action: {
                            
                        
                            
                        }, label: {
                            Menu{
                                Button("Nueva Entrada"){
                                    DiarioModel().addItem(title: "Titulo", emocion: "feliz", content: "Esto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de pruebaEsto es un contenido de prueba", isTijeras: true)
                                    withAnimation {
                                        list.removeAll()
                                        list = DiarioModel().getAllItem()
                                    }
                                    
                                }
                                
                                Menu{
                                    ForEach(0..<titlesExamples.count, id: \.self){ value in
                                        Button(titlesExamples[value].0){
                                            DiarioModel().addItem(title: titlesExamples[value].0, emocion: titlesExamples[value].1, content: "Esto es un contenido", isTijeras: true)
                                            withAnimation {
                                                list.removeAll()
                                                list = DiarioModel().getAllItem()
                                            }
                                        }
                                    }
                                }label: {
                                    Label("Sugerrencias", systemImage: "wand.and.rays")
                                }
                                
                            }label:{
                                Image(systemName: "plus")//"wand.and.rays")
                                    .tint(.black)
                            }
                            
                        })
                    }
            }
                    
            }
        }
        
    }
}


//Card Item
struct cardItem: View{
    
    @Binding var diario : Diario
    @Binding var list : [Diario]
    
    @State private var expandText = false
    @State private var isEditing = false
    @State private var textfield = ""

    
    let emociones = ["Neutral","Feliz","Enfadado","Desanimado","Distraido","Sorpresa"]
    
    var body: some View{
        VStack(spacing: 20){
            //EmotioIcon
            HStack{
                Menu{
                    ForEach(0..<6){idx in
                        Button{
                            DiarioModel().UpdateEmoticono(emoticono: emociones[idx].lowercased(), diario: diario)
                            withAnimation {
                                list.removeAll()
                                list = DiarioModel().getAllItem()
                            }
                            
                            
                        }label: {
                            Label(emociones[idx], image: emociones[idx].lowercased() )
                        }
                            
                    }
                    
                    
                }label: {
                    Image(diario.emotion ?? "neutral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .shadow(color: .blue, radius: 5)
                }
                
                
                Text(diario.title ?? "")
                    .font(.headline).bold()
                Spacer()
            }
            
            
                Text(diario.content ?? "")
                    .font(.subheadline)
                    .lineLimit(expandText ? nil :  3)
                    .onTapGesture {
                        withAnimation {
                            expandText.toggle()
                        }
                        
                    }
            
                
            
                    
            
                Divider()
            
                HStack{
                    Text(Date.now, style: .date)
                        .font(.caption2).bold()
                    Text(Date.now, style: .time)
                        .font(.caption2).bold()
                    Spacer()
                    Menu{
                        Button{
                            
                        }label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        
                        Button{
                            
                        }label: {
                            Label("Tijeras Podar", systemImage: "scissors")
                        }
                        
                        Button(role: .destructive){
                            withAnimation {
                                DiarioModel().DeleteItem(diario: diario)
                                list.removeAll()
                                list = DiarioModel().getAllItem()
                            }
                            
                        }label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                        
                    }label: {
                        Image(systemName: "ellipsis")
                            .tint(.black)
                            .frame(width: 20, height: 20)
                    
                }
                
            }
        }
        
    }
}



#Preview {
    DiarioListView()
}

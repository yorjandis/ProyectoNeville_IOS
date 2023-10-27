//
//  gregg.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//

import SwiftUI

struct gregg: View {
    
    let biografia = """
Gregg Braden, nacido el 28 de junio de 1954  es un físico y autor estadounidense de la Nueva Era, conocido por sus apariciones en Ancient Aliens y su programa Missing Links , y otras publicaciones que vinculan la ciencia y la espiritualidad. Sus investigaciones han dado lugar a 15 créditos cinematográficos y 12 libros premiados publicados en más de 40 idiomas.
"""
    
    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(gradient: Gradient(colors: [.green, .orange]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack{
                    Image("greeg")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 120, height: 120)
                        .cornerRadius(20)
                        .padding(10)
                    
                    Text(biografia)
                        .foregroundStyle(.black )
                        .bold()
                        .multilineTextAlignment(.center)
                        .padding(5)
                        .padding(.bottom, 20)
                    
                    Link(destination: URL(string: "https://greggbraden.com/")!, label: {
                        Text("Sitio Web")
                    })
                    .buttonStyle(GradientButtonStyle())
                    
                    Link(destination: URL(string: "https://drive.google.com/file/d/1_fTTJDpyTSqOtZ4shdbsXeEQSVWqpO_a/view?usp=sharing")!, label: {
                        Text("Descargar Libros")
                    })
                    .buttonStyle(GradientButtonStyle())
                    
                    NavigationLink("Ver Videos"){
                        ListVideos()
                    }
                        .buttonStyle(GradientButtonStyle())
                    
                    
                    
                    Spacer()
                    
                }
                
               
                
            }
            .navigationTitle("Videos de Greeg Braden")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    
    struct ListVideos : View{
        
        @State var list  =  UtilFuncs.GetIdVideosFromYoutube(typeContent: .gregg)
        
        var body: some View {
            
            List(list, id: \.0){ item in
                
                NavigationLink{
                    YTVideoView(items: [ItemVideoYoutube(id: item.0, title: item.1)], showFavIcon: true)
                }label: {
                    Text(item.1)
                }
            }
            
        }
        
        
    }
    
    
    
    
    
    struct GradientButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label
                .foregroundColor(Color.white)
                .padding()
                .frame(width: 200, height: 50)
                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.gray]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(15.0)
        }
    }
    
    
    
}

#Preview {
    gregg()
}

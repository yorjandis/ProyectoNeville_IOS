//
//  SideMenuView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 14/9/23.
//

import SwiftUI

struct SideMenuView: View {
    
  
    @State private var show = false
    @Binding var fontSize : CGFloat 
    
    @Binding var colorFondo_a : Color
    @Binding var colorFondo_b : Color
    
    let itemVideoMaestrosNeville = [
        ItemVideoYoutube(id: "YQ9jM5B0-O8", title: "William Blake"),
        ItemVideoYoutube(id: "mgbdcv606Rg", title: "Abdullah"),
    ]
    
    
    var body: some View {
        VStack() {
            
            //Header
                VStack (alignment: HorizontalAlignment.center){
                    Image("appstore")
                        .resizable()
                        .renderingMode(.original)
                        .frame(width: 80, height: 80)
                        .cornerRadius(20)
                        .padding(.top, 10)
                        
                    Text("Imaginar Crea la Realidad")
                        .foregroundStyle(.black)
                    
                }
                
                
           
            //ListItems
            ScrollView(showsIndicators: false ){
                VStack (alignment: .leading, spacing: 10){
                    divider(title: "Sobre Neville")
                    
                    NavigationLink{
                        ContentTxtShowView(fileName: "biografia", title: "Biografía")
                    }label: {
                        TextItem(fontsize: $fontSize, text: "Biografía de Neville")
                    }
                    
                    NavigationLink{
                        galeriaFotosView()
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Galería de Fotos")
                    }
                    
                    NavigationLink{
                        YTVideoView(items: itemVideoMaestrosNeville, showFavIcon: false)
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Los Maestros de neville")
                    }

                    divider(title: "Conferencias")
    
                    NavigationLink{
                        TxtListView(type: .conf, title : "Conferencias")
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Conferencias en Texto")
                    }
                    
                    NavigationLink{
                        YTLisIDstView(type: .video_Conf)
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Conferencias en Videos")
                    }
                    
                    
                    Link(destination: URL(string: "https://www.ivoox.com/escuchar-neville-goddard_nq_102778_1.html")!, label: {
                        TextItem(fontsize: $fontSize,text: "Conferencias en Audios")
                    })
                    
                    divider(title: "Mas Contenido")
                    
                    Link(destination: URL(string: "https://drive.google.com/file/d/1NjUDZfjSOjdPRd6vsyhfDKmjdDus25YM/view?usp=sharing")!, label: {
                        TextItem(fontsize: $fontSize,text: "Descarga de libros neville")
                    })
                    
                    
                    NavigationLink{
                        YTLisIDstView(type: .aud_libros)
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Audio Libros de Neville")
                    }
                    
                    
                    NavigationLink{
                        TxtListView(type: .preg , title: "Preguntas")
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Preguntas y Respuestas")
                    }
                    
                    NavigationLink{
                        TxtListView(type: .citas, title: "Citas")
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Citas de Conferencias")
                    }
                    
                    NavigationLink{
                        TxtListView(type: .ayud, title: "Ayudas")
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Ayudas")
                    }
                    
                    
                    divider(title: "Qué dice la Ciencia Actual", size: 60)
                    
                    
                    NavigationLink{
                        gregg()
                    }label: {
                        TextItem(fontsize: $fontSize,text: "Gregg Braden")
                    }
                    
                    divider(title: "Recursos Externos", size: 86)
                    
                    Link(destination: URL(string: "https://t.me/nevilleGoddardaudios")!, label: {
                        TextItem(fontsize: $fontSize,text: "Audios Neville en Telegram")
                    })
                    
                    Link(destination: URL(string: "https://t.me/NevilleAudiosII")!, label: {
                        TextItem(fontsize: $fontSize,text: "Audios Neville en Telegram II")
                        
                    })
                    
                    Link(destination: URL(string: "https://t.me/+rODRAz2S6nVmMmY0")!, label: {
                        TextItem(fontsize: $fontSize,text: "Canal Neville para Todos")
                    })
                   
                    
                    Link(destination: URL(string: "https://nevilleenespanol.blogspot.com/")!, label: {
                        TextItem(fontsize: $fontSize,text: "Web Neville BlogSpot")
                    })
                    
                    
                    Link(destination: URL(string: "https://neville-espanol.com/")!, label: {
                        TextItem(fontsize: $fontSize,text: "Web Neville en Español")
                    })
                    
                    
            
                    Link(destination: URL(string: "https://realneville.com/")!, label: {
                        TextItem(fontsize: $fontSize,text: "Web Real Neville (inglés)")
                    } )
                    
                    divider(title: "Muchos caminos, una verdad", size: 40)
                    
                    NavigationLink{
                        ShowPlayListYTView()
                    }label: {
                        TextItem(fontsize: $fontSize,text: "10 Lecciones de Sabiduria")
                    }
                    

                    
                    Spacer()
                }
                .padding(.bottom, 10)
                .onSubmit {
                    print("yorjandis")
                }
            }
            
           
        }
        .font(.title)
        .frame(width: 350)
        .background(LinearGradient(colors: [.gray, .brown], startPoint: .topLeading, endPoint: .bottomTrailing))
        //.modifier(mof_ColorGradient(colorInit: $colorFondo_a, colorEnd: $colorFondo_b))
        .cornerRadius(20)
        .padding(.bottom, 60)
        
 
    }
    
    
    
    //Crea una linea divisora
    func divider(title : String, size : CGFloat = 100)-> some View{
        return HStack {
            Rectangle()
                .frame(width: size, height: 1, alignment: .center)
            Text(title)
                .foregroundStyle(.black)
                .font(.subheadline).bold()
            Rectangle()
                .frame(width: size, height: 1, alignment: .center)
               
        }
        .padding(5)
    }
    
    //Crea un Item de menú: para anezar a un navigationLink
    struct TextItem : View{
        @Binding var fontsize : CGFloat
        @State var text : String
        @State var systemImage : String = "command"
        
        var body: some View{
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.black)
                Text(text)
                    .font(.system(size: fontsize))
                    .font(.title2)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.padding(.leading, 10)
        }
    }
    
    
}

#Preview {
   // SideMenuView()
    ContentView()
}


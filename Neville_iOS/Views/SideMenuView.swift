//
//  SideMenuView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 14/9/23.
//

import SwiftUI

struct SideMenuView: View {
    
  
    @State private var show = false
    
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
                    
                }
                
                
           
            //ListItems
            ScrollView(showsIndicators: false ){
                VStack (alignment: .leading, spacing: 10){
                    divider(title: "Sobre Neville")
                    
                    NavigationLink{
                        ContentTxtShowView( fileName: "biografia", title: "Biografía")
                    }label: {
                        TextItem("Biografía de Neville")
                    }
                    
                    NavigationLink{
                        galeriaFotosView()
                    }label: {
                        TextItem("Galería de Fotos")
                    }
                    
                    NavigationLink{
                        YTVideoView(items: itemVideoMaestrosNeville, showFavIcon: false)
                    }label: {
                        TextItem("Los Maestros de neville")
                    }

                    divider(title: "Conferencias")
    
                    NavigationLink{
                        TxtListView(typeContent: .conf)
                    }label: {
                        TextItem("Conferencias en Texto")
                    }
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: .video_Conf)
                    }label: {
                        TextItem("Conferencias en Videos")
                    }
                    
                    
                    Link(destination: URL(string: "https://www.ivoox.com/escuchar-neville-goddard_nq_102778_1.html")!, label: {
                        TextItem("Conferencias en Audios")
                    })
                    
                    divider(title: "Mas Contenido")
                    
                    Link(destination: URL(string: "https://drive.google.com/file/d/1NjUDZfjSOjdPRd6vsyhfDKmjdDus25YM/view?usp=sharing")!, label: {
                        TextItem("Descarga de libros neville")
                    })
                    
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: .aud_libros)
                    }label: {
                        TextItem("Audio Libros de Neville")
                    }
                    
                    
                    NavigationLink{
                        TxtListView(typeContent: .preguntas)
                    }label: {
                        TextItem("Preguntas y Respuestas")
                    }
                    
                    NavigationLink{
                        TxtListView(typeContent: .citas)
                    }label: {
                        TextItem("Citas de Conferencias")
                    }
                    
                    NavigationLink{
                        TxtListView(typeContent: .ayudas)
                    }label: {
                        TextItem("Ayudas")
                    }
                    
                    
                    divider(title: "Qué dice la Ciencia Actual", size: 60)
                    
                    
                    NavigationLink{
                        gregg()
                    }label: {
                        TextItem("Gregg Braden")
                    }
                    
                    divider(title: "Recursos Externos", size: 86)
                    
                    Link(destination: URL(string: "https://t.me/nevilleGoddardaudios")!, label: {
                        TextItem("Audios Neville en Telegram")
                    })
                    
                    Link(destination: URL(string: "https://t.me/NevilleAudiosII")!, label: {
                        TextItem("Audios Neville en Telegram II")
                        
                    })
                    
                    Link(destination: URL(string: "https://t.me/+rODRAz2S6nVmMmY0")!, label: {
                        TextItem("Canal Neville para Todos")
                    })
                   
                    
                    Link(destination: URL(string: "https://nevilleenespanol.blogspot.com/")!, label: {
                        TextItem("Web Neville BlogSpot")
                    })
                    
                    
                    Link(destination: URL(string: "https://neville-espanol.com/")!, label: {
                        TextItem("Web Neville en Español")
                    })
                    
                    
            
                    Link(destination: URL(string: "https://realneville.com/")!, label: {
                        TextItem("Web Real Neville (inglés)")
                    } )
                    
                    divider(title: "Muchos caminos, una verdad", size: 40)
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.espiritualidad)
                    }label: {
                        TextItem(TypeIdVideosYoutube.espiritualidad.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.liderazgo)
                    }label: {
                        TextItem(TypeIdVideosYoutube.liderazgo.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.desarrolloPersonal)
                    }label: {
                        TextItem(TypeIdVideosYoutube.desarrolloPersonal.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.libertadFinanciera)
                    }label: {
                        TextItem(TypeIdVideosYoutube.libertadFinanciera.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.emprendedores)
                    }label: {
                        TextItem(TypeIdVideosYoutube.emprendedores.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.alcanzarExito)
                    }label: {
                        TextItem(TypeIdVideosYoutube.alcanzarExito.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(typeContent: TypeIdVideosYoutube.personasDejaronHuellas)
                    }label: {
                        TextItem(TypeIdVideosYoutube.personasDejaronHuellas.getTitle)
                    }

                    
                    Spacer()
                }.padding(.bottom, 10)
                
            }
            
           
        }
        .font(.title)
        .frame(width: 350)
        .modifier(mof_ColorGradient(colorInit: .gray, colorEnd: .brown, color3: nil))
        .cornerRadius(20)
        .padding(.bottom, 60)
        
 
    }
    
    
    
    //Crea una linea divisora
    func divider(title : String, size : CGFloat = 100)-> some View{
        return HStack {
            Rectangle()
                .frame(width: size, height: 1, alignment: .center)
            Text(title)
                .font(.subheadline).bold()
            Rectangle()
                .frame(width: size, height: 1, alignment: .center)
               
        }
        .padding(5)
    }
    
    //Crea un Item de menú: para anezar a un navigationLink
    func TextItem(_ text : String, _ systemImage : String = "command")->some View{
        return HStack {
            Image(systemName: systemImage)
                .foregroundColor(.black)
            Text(text)
                .font(.title2)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.leading, 10)
    }
    
    
}

#Preview {
   // SideMenuView()
    ContentView()
}


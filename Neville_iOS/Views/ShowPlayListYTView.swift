//
//  ShowPlayListYTView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 31/10/23.
//

import SwiftUI

struct ShowPlayListYTView : View {
    
    @Environment(\.dismiss) var dimiss
    
    var body: some View {
        NavigationStack{
            ZStack{
                
                LinearGradient(colors: [.gray, .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20){
                    Link("Créditos: Youtube - 10 Lecciones de sabiduria", destination: URL(string: "https://www.youtube.com/@leccionesdesabiduria")!)
                        .padding(.vertical)
                        .padding(.leading, 10)
                        .foregroundStyle(.black)
                        .font(.headline)
                    Divider()
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.espiritualidad)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.espiritualidad.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.liderazgo)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.liderazgo.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.desarrolloPersonal)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.desarrolloPersonal.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.libertadFinanciera)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.libertadFinanciera.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.emprendedores)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.emprendedores.getTitle)
                    }
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.alcanzarExito)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.alcanzarExito.getTitle)
                    }
                    
                    NavigationLink{
                        YTLisIDstView(type: YTIdModel.TypeIdVideosYoutube.personasDejaronHuellas)
                    }label: {
                        TextItem(text: YTIdModel.TypeIdVideosYoutube.personasDejaronHuellas.getTitle)
                    }
                        
                    Spacer()
                    Divider()
                    HStack{
                        Spacer()
                        Button{
                            dimiss()
                        }label: {
                            Text("Atrás")
                                .font(.headline)
                                .foregroundStyle(.black)
                                .padding(.trailing, 30)
                        }
                    }
                   
                    
                }
            }
            
            .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/).bold()
            .navigationTitle("Lecciones de Sabiduría")
            .navigationBarTitleDisplayMode(.inline)

        }
    }
}

//Crea un Item de menú: para anezar a un navigationLink
struct TextItem : View{
    @State var text : String
    @State var systemImage : String = "command"
    @State var fontsize : CGFloat = 18
    
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


#Preview {
    ShowPlayListYTView()
}

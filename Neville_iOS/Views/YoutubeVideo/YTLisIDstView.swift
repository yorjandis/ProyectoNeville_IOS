//
//  IDYoutubeListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/9/23.
//
//Muestra un listado de IDs de videos de youtube y los lanza
//La variable typeContent indica el tipo de contenido a cargar
//La variable ListOfVideosIds Almacena el listado

import SwiftUI

struct YTLisIDstView: View {
    
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    @EnvironmentObject var netMonitor : NetworkMonitor
    
    @State private var showAlert = false
    
    
    var type : YTIdModel.TypeIdVideosYoutube = .NA //Tipo de contenido a cargar
    
    @State private var list : [YTvideo] = []
    
    @State var fontSizeList : CGFloat = 18
    
    var body: some View {
        
        NavigationStack{
     
            List(list, id: \.id){ idx in
                HStack{
                    Image(systemName: "video.fill")
                        .padding(.horizontal, 5)
                        //.foregroundStyle(.linearGradient(colors: [.orange, .green], startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.linearGradient(colors: [idx.isfav ? .orange : .gray, idx.nota!.isEmpty ? .gray : .green], startPoint: .leading, endPoint: .trailing))
                    
                    NavigationLink{
                        YTVideoView(items: [ItemVideoYoutube(id: idx.idvideo ?? "", title: idx.titlevideo ?? "")], showFavIcon: true)
                    }label: {
                        Text(idx.titlevideo!.capitalized(with: .autoupdatingCurrent) )
                            .bold()
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)    
                            .font(.system(size: CGFloat(fontSizeList)))
                    }
                }
                .swipeActions(edge: .leading){
                    Button{
                        var temp = idx.isfav
                        temp.toggle()
                        YTIdModel().setFavState(entity: idx, state: temp)
                        withAnimation {
                            let temp2 = list
                            list.removeAll()
                            list = temp2
                        }
                    }label: {
                        Image(systemName: "heart.fill")
                            .tint(.orange)
                            
                    }
                    NavigationLink{
                        EditNote(entidad: idx)
                            .presentationDetents([.medium])
                    }label: {
                        Image(systemName: "bookmark")
                            .tint(.green)
                    }
                }
                
            }
            .onAppear {
                if !netMonitor.isConnected {
                    showAlert = true
                }
                list = YTIdModel().GetAllItems(type: self.type)
                fontSizeList = CGFloat(UserDefaults.standard.integer(forKey: Constant.UD_setting_fontListaSize))//setting
            }
            
            
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                
                Button{
                    dimiss()
                }label: {
                    Text("Atrás")
                }
                .padding(.trailing, 25)
                .padding(.top, 10)
                
            }
            .navigationTitle(type.getTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Menu{
                        Button("Todas las \(type.getTitle)"){
                            list.removeAll()
                            list = YTIdModel().GetAllItems(type: self.type)
                        }
                        Button("\(type.getTitle) favoritas"){
                            let temp = YTIdModel().getAllFavorite(type: self.type)
                            list.removeAll()
                            list = temp
                            
                        }
                        Button("\(type.getTitle) con notas"){
                            let temp = YTIdModel().getAllNota(type: self.type)
                            list.removeAll()
                            list = temp
                        }
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Neville"),
                    message: Text("El contenido de esta sección requiere conección a internet")
                )
            }
        }
        
    }
    

  

}



//Permite ver y editar el campo notya
struct EditNote:View {
    @Environment(\.dismiss) var dimiss
    @State var entidad : YTvideo
    @State private var textfiel = ""

    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.gray, .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(spacing: 15){
                    Text(entidad.titlevideo ?? "")
                        .foregroundStyle(.black)
                        .font(.headline).bold()
                        
                    Divider()
                    TextField("Coloque su nota aqui", text: $textfiel, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .font(.title)
                        .foregroundStyle(.black).italic().bold()
                        .onAppear {
                            textfiel = entidad.nota ?? ""
                        }
                    
                    Spacer()
                }
            }
            .navigationTitle("Notas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Button{
                        YTIdModel().setNota(entity: entidad, nota: textfiel)
                        dimiss()
                    }label: {
                        Text("Guardar")
                            .foregroundStyle(.black).bold()
                    }
                }
            }
            
        }
    }
}


#Preview {
    ContentView()
}

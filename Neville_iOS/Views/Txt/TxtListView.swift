//
//  ConfListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//

//Muestra un listado de elementos txt inbuilt


import SwiftUI

struct TxtListView: View {
    
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    
    var typeContent : TypeOfContent = .NA
    
    @State private var listTxt : [String] = []
    
    
    var body: some View {
 
        VStack {
            List(listTxt , id: \.self) { item in
                HStack{
                    Image(systemName: "fleuron.fill")
                        .foregroundColor(FavModel().isFav(nameFile: item, prefix: typeContent.getPrefix) ? .orange : .gray)
                    
                    NavigationLink{
                        ContentTxtShowView(fileName: "\(item)",  title: item, typeContent: typeContent)
                    }label: {
                        Text(item)
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black )
                            .bold()
                            
                    }
                        
                }
                .swipeActions(edge: .trailing){
                    
                    Button("Favorito"){
                        setFav(nameFile: item, prefix: typeContent.getPrefix)
                        getList()
                    }
                    
                }.tint(.orange)
                
            }//List
            .onAppear{
                getList()
            }
            .background(.ultraThinMaterial)
            
            Divider()
            
            //Barra Inferior (Permitir volver, favorito, etc)
            HStack( spacing: 20){
                Spacer()
                //Show/Hide the fav button
                Button{
                    dimiss()
                }label: {
                    Text("Volver")
                }
                .padding(.trailing, 25)
                .padding(.top, 10)
                
            }
            
            
        }
        .navigationTitle(typeContent.getDescription)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    ///Obtiene el arreglo de ficheros txt
   private  func  listTxtCont()-> [String] {
        var result = [String]()
        var temp : String = ""
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        
        
        
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix(typeContent.getPrefix) {
                    temp = String(item.trimmingPrefix(typeContent.getPrefix))
                        .replacingOccurrences(of: ".txt", with: "")
                        .capitalized(with: .autoupdatingCurrent)
                    
                    result.append(temp)
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        return result
        
    }
    
    

    ///Auxiliar: Alterna entre los estados de fav/NO fav
    private func setFav(nameFile : String, prefix : String){
        if FavModel().isFav(nameFile: nameFile, prefix: prefix){
               FavModel().Delete(nameFile:nameFile.lowercased(), prefix: prefix)
               }else{
                   FavModel().Add(nameFile:nameFile.lowercased(), prefix: prefix)
               }
        
    }
    
    ///Auxiliar: Actualiza el listado
    private func getList(){
        listTxt.removeAll()
        listTxt = listTxtCont()
    }
        
}

#Preview {
    TxtListView()
}

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
    
    
    var body: some View {
 
        VStack {
            List(listTxtCont(), id: \.self) { item in
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
        .navigationTitle(typeContent.getTitleOfContent)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    
    //Obtiene el arreglo de ficheros txt
    func  listTxtCont()-> [String] {
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
    
        
}

#Preview {
    TxtListView()
}

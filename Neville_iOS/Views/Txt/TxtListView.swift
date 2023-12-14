//
//  TxtConfelistadoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//listadoa los elementos TXT de contenido que tienen prefijos: conf_, cita_, preg: y ayud_

import Foundation
import SwiftUI
import CoreData

struct TxtListView: View {
    
    @Environment(\.colorScheme) var theme
    
    let type : TxtContentModel.TipoDeContenido //Tipo de contenido a cargar

    @State var title : String //Es el título
    
    //Para Agregar notas
    @State var showAlertAddNote = false
    @State var textFiel = ""
    
    //Para buscar en texto:
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    
    //Para buscar en titulos
    @State var showAlertSearchInTitle = false
    @State var textFiel3 = ""
    
    
    @State var listado : [TxtCont] = []
    @State private var entidad : TxtCont = TxtCont(context: CoreDataController.dC.context) //Esto es para permitir editar la nota y buscar en txt

    var body: some View {
        
        NavigationStack{
            VStack{
                List(listado){item in
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName: "leaf.fill")
                                .padding(.horizontal, 5)
                                .foregroundStyle(.linearGradient(colors: [item.isfav ? .orange : .gray, item.nota!.isEmpty ? .gray : .green], startPoint: .leading, endPoint: .trailing))
                            
                            NavigationLink{
                                ContentTxtShowView(entidad: item, type: self.type, title: item.namefile ?? "")
                            }label: {
                                Text(item.namefile ?? "")
                            }
                            
                        }
                        //Marcando los elementos como nuevos
                        if item.isnew {
                            Text("Nueva")
                                .font(.footnote).bold()
                                .foregroundStyle(Color.orange)
                                .fontDesign(.serif)
                        }
                    }
                        .swipeActions(edge: .leading){
                            Button{
                                var temp = item.isfav
                                temp.toggle()
                                TxtContentModel().setFavState(entity: item, state: temp)
                                withAnimation {
                                    let temp2 = listado
                                    listado.removeAll()
                                    listado = temp2
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(Color.orange)
                            }
                            NavigationLink{
                                EditNoteTxt(entidad: item)
                            }label: {
                                Image(systemName: "bookmark")
                                    .tint(Color.green)
                            }
                    }
                    
                }
                .onAppear{
                    listado.removeAll()
                    listado = TxtContentModel().GetRequest(type: self.type, predicate: nil)
                }
            }
            .navigationTitle(self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                            HStack{
                                Spacer()
                                Menu{
                                    Button("Todas las \(self.title)"){
                                        listado.removeAll()
                                        listado = TxtContentModel().GetRequest(type: self.type, predicate: nil)
                                    }
                                    Button("\(self.title) favoritas"){
                                        let temp = TxtContentModel().getAllFavorite(type:self.type)
                                        listado.removeAll()
                                        listado = temp
                                        
                                    }
                                    Button("\(self.title) con notas"){
                                        let temp = TxtContentModel().getAllNota(type:self.type)
                                        listado.removeAll()
                                        listado = temp
                                    }
                                    
                                    Button("Buscar en títulos"){
                                        showAlertSearchInTitle = true
                                    }
                                    Button("Buscar en el contenido"){
                                        showAlertSearchInTxt = true
                                    }
                                    Button("\(self.title) recientes"){
                                        let temp = TxtContentModel().getAllNewsElements(type: self.type)
                                        listado.removeAll()
                                        listado = temp
                                    }
                                    if self.title == "\(self.title) recientes" && self.listado.count > 0 {
                                        Button("Desmarcar \(self.title) recientes"){
                                            TxtContentModel().RemoveAllNewFlag(type: self.type)
                                            let temp = self.listado
                                            listado.removeAll()
                                            listado = temp
                                        }
                                    }
                                    
                                    
                                }label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .foregroundStyle(theme ==  .dark ? .white :  .black)
                                }
                            
                            }
                        }
                        .alert("Modificar Nota", isPresented: $showAlertAddNote){
                            TextField("", text: $textFiel, axis: .vertical)
                                .multilineTextAlignment(.leading)
                            Button("Guardar"){
                                TxtContentModel().setNota(entity: self.entidad, nota: textFiel)
                            }
                            Button("Cancelar"){showAlertAddNote = false}
                        }
                        .alert("Buscar un texto", isPresented: $showAlertSearchInTxt){
                            TextField("", text: $textFiel2, axis: .vertical)
                            Button("Cancelar"){showAlertSearchInTxt = false}
                                .multilineTextAlignment(.leading)
                            Button("Buscar"){
                                let temp  =  TxtContentModel().searchInText(list: self.listado , texto: textFiel2)
                                listado.removeAll()
                                listado = temp
                            }
                            
                        }
                        .alert("Buscar en títulos", isPresented: $showAlertSearchInTitle){
                            TextField("", text: $textFiel3, axis: .vertical)
                                .multilineTextAlignment(.leading)
                            Button("Cancelar"){showAlertSearchInTitle = false}
                            Button("Buscar"){
                                let temp  =  TxtContentModel().searchInTitle(list: self.listado , texto: textFiel3)
                                listado.removeAll()
                                listado = temp
                            }
                            
                        }
        }
        
    }
}


//Permite ver y editar el campo notya
struct EditNoteTxt:View {
    @Environment(\.dismiss) var dimiss
    @State var entidad : TxtCont
    @State private var textfiel = ""

    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.gray, .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(){
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
                        TxtContentModel().setNota(entity: entidad, nota: textfiel)
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

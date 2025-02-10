//
//  TxtConfelistadoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//lista los elementos TXT de contenido que tienen prefijos: conf_, cita_, preg: y ayud_

import Foundation
import SwiftUI
import CoreData
import CloudKit

struct TxtListView: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.managedObjectContext) var context
    
    let typeOfContent : TxtContentModel.TipoDeContenido //Tipo de contenido a cargar

    @State var title : String //Es el título
    
    //Para Agregar notas
    @State var showAlertAddNote = false
    @State var textFiel = ""
    
    //Para buscar en texto:
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    
    @State var listado : [TxtCont] = [] //Listado de conferencias txt
    
    @State private var entidad : TxtCont = TxtCont(context: CoreDataController.shared.context) //Esto es para permitir editar la nota y buscar en txt
    
    @State private var textFielSearh = ""
    @FocusState private var focus : Bool
    
    
    private var filteredSearch : [TxtCont]{
        if textFielSearh.isEmpty {return self.listado}
        return self.listado.filter{ $0.namefile?.localizedCaseInsensitiveContains(self.textFielSearh) ?? false}
    }

    var body: some View {
        
        NavigationStack{
            VStack{

                List(self.filteredSearch){item in
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName: "leaf.fill")
                                .padding(.horizontal, 5)
                                .foregroundStyle(.linearGradient(colors: [item.isfav ? .orange : .gray, item.nota!.isEmpty ? .gray : .green], startPoint: .leading, endPoint: .trailing))
                            
                            NavigationLink{
                                ContentTxtShowView(entidad: item, type: self.typeOfContent, title: item.namefile ?? "")
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
                                TxtContentModel().setFavState(context: self.context, entity: item, state: temp)
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
                .task{
                    listado = TxtContentModel().GetRequest(context: self.context, type: self.typeOfContent, predicate: nil)
                }
                .searchable(text: $textFielSearh, placement: .navigationBarDrawer(displayMode: .always)  ,prompt: "Buscar" )
            }
            .navigationTitle(self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Menu{
                        Button("Todas las \(self.title)"){
                            listado.removeAll()
                            listado = TxtContentModel().GetRequest(context: self.context, type: self.typeOfContent, predicate: nil)
                        }
                        Button("\(self.title) favoritas"){
                            let temp = TxtContentModel().getAllFavorite(context: self.context, type:self.typeOfContent)
                            listado.removeAll()
                            listado = temp
                        }
                        Button("\(self.title) con notas"){
                            let temp = TxtContentModel().getAllNota(context: self.context, type:self.typeOfContent)
                            listado.removeAll()
                            listado = temp
                        }

                        Button("Buscar en el contenido"){
                            showAlertSearchInTxt = true
                        }
                        Button("Nuevo contenido!"){
                            let temp = TxtContentModel().getAllNewsElements(context: self.context, type: self.typeOfContent)
                            listado.removeAll()
                            listado = temp
                        }
                        if self.title == "\(self.title) recientes" && self.listado.count > 0 {
                            Button("Desmarcar \(self.title) recientes"){
                                TxtContentModel().RemoveAllNewFlag(context: self.context, type: self.typeOfContent)
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
                    TxtContentModel().setNota(context: self.context, entity: self.entidad, nota: textFiel)
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
        }
        
    }
}


//Permite ver y editar el campo notya
struct EditNoteTxt:View {
    @Environment(\.dismiss) var dimiss
    @State var entidad : TxtCont
    @State private var textfiel = ""
    @Environment(\.managedObjectContext) private var context

    
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
                        TxtContentModel().setNota(context: self.context, entity: entidad, nota: textfiel)
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
    TxtListView(typeOfContent: .conf, title: "Conferencias")
}

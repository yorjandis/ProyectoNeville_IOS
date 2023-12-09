//
//  ReflexListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 29/11/23.
//

import SwiftUI
import CoreData

struct ReflexListView: View {
    
    @Environment(\.colorScheme) private var theme
    @State var list : [Reflex] = []
    
    @State var showAlertSearchInTitle = false
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    @State var textFiel3 = ""
    
    @State var showSheetAddReflex = false
    
    @State var showalertDeleteItem = false
    
    @State private var entityToDelete : Reflex = Reflex()
    
    
    var body: some View {
        NavigationStack{
            VStack{
                List(list){item in
                    VStack(alignment: .leading){
                        NavigationLink{
                            ReflexShowTextView(entity: item)                 
                        }label: {
                            Text(item.title ?? "")
                        }
                        Text(item.autor ?? "")
                            .font(.caption2)
                            .italic()
                            .foregroundStyle(RefexModel().getFavState(fraseID: item.id ?? "") ? Color.orange.opacity(0.7) : Color.gray)
                    }
                    .swipeActions(edge: .leading) {
                            Button{
                                if RefexModel().switchFavState(ReflexID: item.id ?? "") {
                                    withAnimation {
                                        let temp2 = list
                                        list.removeAll()
                                        list = temp2
                                    }
                                    
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(.orange)
                            }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button{
                                entityToDelete = item
                                showalertDeleteItem = true
                            }label: {
                                Image(systemName: "minus.circle")
                                    .tint(.red)
                            }
                    }
                    
                }
                .onAppear {
                    list.removeAll()
                    list = RefexModel().getAllReflex()
                }
                
            }
            .navigationTitle("Reflexiones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                            HStack{
                                Spacer()
                                Menu{
                                    Button("Todas las reflexiones"){
                                        list.removeAll()
                                        list = RefexModel().getAllReflex()
                                    }
                                    Button("Reflexiones favoritas"){
                                        let temp = RefexModel().GetAllFav()
                                        list.removeAll()
                                        list = temp
                                        
                                    }
                                                    
                                    Button("Buscar en títulos"){
                                        showAlertSearchInTitle = true
                                    }
                                    Button("Buscar en el contenido"){
                                        showAlertSearchInTxt = true
                                    }
                                    
                                }label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                        .foregroundStyle(theme ==  .dark ? .white :  .black)
                                }
                                
                                Button{
                                    showSheetAddReflex = true
                                }label: {
                                    Image(systemName: "plus")
                                        .foregroundStyle(theme ==  .dark ? .white :  .black)
                                }
                            
                            }
                        }
            .alert("Buscar un texto", isPresented: $showAlertSearchInTxt){
                TextField("", text: $textFiel2, axis: .vertical)
                Button("Cancelar"){showAlertSearchInTxt = false}
                    .multilineTextAlignment(.leading)
                Button("Buscar"){
                    let temp  =  RefexModel().searchTextInTextoReflex(text: self.textFiel2)
                    list.removeAll()
                    list = temp
                }
                
            }
            .alert("Buscar en títulos", isPresented: $showAlertSearchInTitle){
                TextField("", text: $textFiel3, axis: .vertical)
                    .multilineTextAlignment(.leading)
                Button("Cancelar"){showAlertSearchInTitle = false}
                Button("Buscar"){
                    let temp  =  RefexModel().searchTextInTitleReflex(text: textFiel3)
                    list.removeAll()
                    list = temp
                }
                
            }
            .sheet(isPresented: $showSheetAddReflex, content: {
                AddReflexView(list: $list)
            })
            .alert(isPresented: $showalertDeleteItem){
                    Alert(title: Text("La Ley"),
                      message: Text("Desea eliminar la entrada?"),
                          primaryButton: .destructive(Text("Eliminar"), action: {
                        if RefexModel().deleteEntity(id: entityToDelete.id ?? ""){
                            withAnimation {
                                list.removeAll()
                                list = RefexModel().getAllReflex()
                            }    
                        }
                        
                        }), secondaryButton: .cancel()
                          
                    )
            }
            
        }
    }
    
    
    
    //Permite adicionar una nueva reflexión
    struct AddReflexView : View {
        @Environment(\.dismiss) private var dimiss
        @Binding var list : [Reflex]
        @State private var textFielTitle = ""
        @State private var textFielTexto = ""
        @State private var textFielAutor = ""
        
        @State var showAlert = false
        @State var alertMessage = ""
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 10){
                    Form{
                        Section("Título"){
                            TextField("título", text: $textFielTitle, axis: .vertical)
                                .multilineTextAlignment(.leading)
                                .textFieldStyle(.roundedBorder)
                        }
                        Section("Autor"){
                            TextField("autor", text: $textFielAutor, axis: .vertical)
                                .multilineTextAlignment(.leading)
                                .textFieldStyle(.roundedBorder)
                        }
                        Section("Contenido"){
                            TextField("Texto de la reflexión", text: $textFielTexto, axis: .vertical)
                                .multilineTextAlignment(.leading)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .navigationTitle("Adicionar una reflexión")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    ToolbarItem {
                        Button("Guardar"){
                            if RefexModel().AddReflex(title: self.textFielTitle, reflex: self.textFielTexto, autor: self.textFielAutor){
                                alertMessage = "Se ha guardado la reflexión"
                                showAlert = true
                                list.removeAll()
                                list = RefexModel().getAllReflex()
                                dimiss()
                            }else{
                                alertMessage = "Se ha producido un error al guardar la reflexión"
                                showAlert = true
                            }
                        }
                    }
                }
                .alert(isPresented: $showAlert, content: {
                    Alert(title: Text("La Ley"), message: Text(self.alertMessage))
                })
            }
        }
    }
    
}

#Preview {
    ReflexListView()
}

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
    @State var textFielTitleForSearch = ""
    @State var showSheetAddReflex = false
    @State var showalertDeleteItem = false
    @State private var entity : Reflex?
    @State private var subtitle = "Reflexiones"
    @State var isfav = false
    private var filtered : [Reflex]{
        if self.textFielTitleForSearch.isEmpty {return self.list}
        return self.list.filter{$0.title?.localizedCaseInsensitiveContains(self.textFielTitleForSearch) ?? false}
    }
    
    
    var body: some View {
        NavigationStack{
            VStack{
                List(self.filtered){item in
                    VStack(alignment: .leading){
                        NavigationLink{
                            ReflexShowTextView(entity: item)                 
                        }label: {
                            Text(item.title ?? "")
                        }
                        HStack{
                            Text(item.autor ?? "")
                                .font(.caption2)
                                .italic()
                                .foregroundStyle(item.isfav ? Color.orange.opacity(0.7) : Color.gray)
                            //Marcando los elementos nuevos
                            if item.isnew {
                                Text("Nueva")
                                    .font(.footnote).bold()
                                    .foregroundStyle(Color.orange)
                                    .fontDesign(.serif)
                            }
                            
                        }
                       
                       
                    }
                    .swipeActions(edge: .leading) {
                            Button{           
                                if RefexModel().handleFavState(reflex: item){
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
                                entity = item
                                showalertDeleteItem = true
                            }label: {
                                Image(systemName: "minus.circle")
                                    .tint(.red)
                            }
                    }
                    
                }
                .searchable(text: $textFielTitleForSearch, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar")
                .onAppear {
                    list.removeAll()
                    list = RefexModel().GetRequest(predicate: nil)
                }
                
            }
            .navigationTitle(self.subtitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                            HStack{
                                Spacer()
                                Menu{
                                    Button("Todas las reflexiones"){
                                        list.removeAll()
                                        list = RefexModel().GetRequest(predicate: nil)
                                        self.subtitle = "Reflexiones"
                                    }
                                    Button("Reflexiones favoritas"){
                                        let temp = RefexModel().GetAllFav()
                                        list.removeAll()
                                        list = temp
                                        self.subtitle = "Reflexiones favoritas"
                                        
                                    }
                                                    
                                    Button("Buscar en títulos"){
                                        showAlertSearchInTitle = true
                                        self.subtitle = "Reflexiones"
                                    }
                                    Button("Buscar en el contenido"){
                                        showAlertSearchInTxt = true
                                        self.subtitle = "Reflexiones"
                                    }
                                    Button("Nuevas reflexiones"){
                                        let temp = RefexModel().getAllNewsElements()
                                        self.list.removeAll()
                                        self.list = temp
                                        self.subtitle = "Reflexiones nuevas"
                                    }
                                    
                                    if self.subtitle == "Reflexiones nuevas" && self.list.count > 0 {
                                        Button("Desmarcar reflexiones nuevas"){
                                            RefexModel().RemoveAllNewFlag()
                                            let temp = self.list
                                            list.removeAll()
                                            list = temp
                                        }
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
                        if let tt = self.entity {
                            if RefexModel().deleteEntity(reflex: tt){
                                withAnimation {
                                    list = RefexModel().GetRequest(predicate: nil)
                                }
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
                                list = RefexModel().GetRequest(predicate: nil)
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

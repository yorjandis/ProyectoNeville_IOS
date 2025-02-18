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
    @Environment(\.managedObjectContext) private var context
   @StateObject private var modelReflex : ReflexModel = ReflexModel.shared
    
    
    @State var showAlertSearchInTitle = false
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    @State var textFiel3 = ""
    @State var textFielTitleForSearch = ""
    @State var showSheetAddReflex = false
    @State var showalertDeleteItem = false
    
    @State private var entityForDelete : RefType? //Almacena la entidad que será eliminada


   @AppStorage("isUnicaVezReflex") var isUnicaVezReflex: Bool = true
    
    
    
    var body: some View {
        NavigationStack{
            VStack{
                List(modelReflex.list, id: \.id){item in
                    VStack(alignment: .leading){
                        NavigationLink{
                            EmptyView()
                           ReflexShowTextView(entity: item)
                        }label: {
                            Text(item.title) //title
                        }
                        HStack{
                            Text(item.autor) //Autor
                                .font(.caption2)
                                .italic()
                               .foregroundStyle(item.isfav ? Color.orange : Color.gray)
                        }
                    }
                    .swipeActions(edge: .leading) {
                            Button{
                                
                                var favState = modelReflex.getFavState(title: item.title)
                                favState.toggle()
                                if modelReflex.setFavState(title: item.title, state: favState){
                                    //Actualizar el listado
                                    withAnimation {
                                        modelReflex.getArrayReflexOfTxtFile()
                                    }
                                   print("Yorj: se ha ajustado el favorito: \(item.isfav)")
                                }else{
                                    print("Yorj: NO se ha ajustado el favorito: \(item.isfav)")
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(.orange)
                            }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        //Solo permite eliminar las reflexiones creadas por el usuario
                        if !item.isInbuilt {
                            Button{
                                self.entityForDelete = item
                                showalertDeleteItem = true
                            }label: {
                                Image(systemName: "minus.circle")
                                    .tint(.red)
                            }
                        }
                    }
                    
                }
            }
            .navigationTitle("Reflexiones")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                //Este código limpia la BD de reflexiones una sola vez
                if self.isUnicaVezReflex{
                    modelReflex.eliminarDuplicados(context: self.context)
                    self.isUnicaVezReflex = false //Desactiva el flag
                    print("Yorj: dadasdasdasDas")
                }
            }
            .toolbar{
                            HStack{
                                Spacer()
                                Menu{
                                    Button("Todas las reflexiones"){
                                        modelReflex.getArrayReflexOfTxtFile()
                                    }
                                    Button("Reflexiones Personales"){
                                        modelReflex.list = modelReflex.getAllReflexNoInbuiltGet()
                                    }
                                    Button("Reflexiones favoritas"){
                                        modelReflex.list = modelReflex.getReflexFavoritasGet()
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
                    modelReflex.list = modelReflex.searchInContent(text: self.textFiel2)
                }
               
                
            }
            .sheet(isPresented: $showSheetAddReflex, content: {
                EmptyView()
                AddReflexView()
            })
            .alert(isPresented: $showalertDeleteItem){
                    Alert(title: Text("La Ley"),
                      message: Text("Desea eliminar la entrada?"),
                          primaryButton: .destructive(Text("Eliminar"), action: {
                        if let tt = self.entityForDelete {
                            
                            if modelReflex.deleteReflex(title: tt.title){
                                withAnimation {
                                    modelReflex.getArrayReflexOfTxtFile()
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
        @StateObject private var modelReflex = ReflexModel.shared
        @State private var textFielTitle = ""
        @State private var textFielTexto = ""
        @State private var textFielAutor = ""
        @State private var isfav : Bool = false
        
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
                        Section("Favorito"){
                            Toggle(isOn: self.$isfav) {
                                Label("Favorito", systemImage: "heart.fill")
                                    .foregroundStyle( self.isfav ?  .orange : .primary)
                            }
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
                .preferredColorScheme(.dark)
                .toolbar{
                    ToolbarItem {
                        Button("Guardar"){
                            if modelReflex.savePersonalReflex(title: self.textFielTitle, autor: self.textFielAutor, texto: self.textFielTexto, isfav: self.isfav){
                                alertMessage = "Se ha guardado la reflexión"
                                showAlert = true
                                modelReflex.getArrayReflexOfTxtFile()
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

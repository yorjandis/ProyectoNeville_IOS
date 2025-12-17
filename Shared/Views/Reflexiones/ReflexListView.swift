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

    @AppStorage(AppCons.UD_setting_fontListaSize)  var fontSizeLista : Int = 20
    
   @AppStorage("isUnicaVezReflex") var isUnicaVezReflex: Bool = true
    
    //Obtiene el estado de favorito de la reflexión
    private func getFavState(title : String)->Bool{
        return self.modelReflex.getFavState(title: title)
    }
    
    var body: some View {
        NavigationStack{
            VStack{
                List(modelReflex.list, id: \.id){item in
                    VStack(alignment: .leading){
                        #if os(macOS)
                        HStack{
                            Button{
                                showWindow(for: ReflexShowTextView(entity: item),
                                           environmentObjects: [self.modelReflex],
                                           title: "Reflexión: \(item.title)",
                                           size: AppCons.windows_size_content,
                                           isModal: false
                                )
                                
                               
                            }label: {
                                Text(item.title) //title
                                    .font(.system(size: CGFloat(self.fontSizeLista)))
                            }
                            .buttonStyle(.plain)
                            
                            
                            
                            //En macOS: muestra un botón para eliminar la reflexión
                            if !item.isInbuilt {
                                Spacer()
                                Button{
                                    self.entityForDelete = item
                                    showalertDeleteItem = true
                                }label:{
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(.red)
                                }
                                
                                .padding(.horizontal, 5)
                                Button{
                                    showWindow(for: AddReflexView(reflexionAActualizar: item),
                                               environmentObjects: [self.modelReflex],
                                               title: "Editar una Reflexión",
                                               size: AppCons.windows_size_content,
                                               isModal: true
                                    )
                                        
                                    
                                }label: {
                                    //edit
                                    Image(systemName: "square.and.pencil")
                                        
                                }
                                .padding(.horizontal, 5)
                                .foregroundStyle(.green)
                                
                            }
                        }
                        
                        
                        #else
                        NavigationLink{
                           ReflexShowTextView(entity: item)
                        }label: {
                            Text(item.title) //title
                                .font(.system(size: CGFloat(self.fontSizeLista)))
                        }
                        #endif
                        
                        HStack{
                            Text(item.autor) //Autor
                                .font(.body)
                                .italic()
                               
                            if item.isfav{
                                Image(systemName:"heart.fill")
                                    .foregroundStyle(.orange)
                            }
                            
                        }
                    }
                    .swipeActions(edge: .leading) {
                            Button{
                                var favState = self.getFavState(title: item.title)
                                favState.toggle()
                                if modelReflex.setFavState(title: item.title, state: favState){
                                    //Actualizar el listado
                                    withAnimation {
                                        modelReflex.getArrayReflexOfTxtFile()
                                    }
                                   
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .foregroundStyle(item.isfav ? .orange : .gray)
                            }
                        
                        if item.isInbuilt == false{
                            NavigationLink{
                                AddReflexView(reflexionAActualizar: item)
                                    .environmentObject(self.modelReflex)
                                
                            }label: {
                                //edit
                                Image(systemName: "square.and.pencil")
                            }
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .task {
                //Este código limpia la BD de reflexiones una sola vez
                if self.isUnicaVezReflex{
                    modelReflex.eliminarDuplicados(context: self.context)
                    self.isUnicaVezReflex = false //Desactiva el flag
                }
            }
            .toolbar{
                         
                ToolbarItem {
                    Menu{
                        
                        CreateMenuItemButton(text: "Todas las reflexiones", sysImageStr: "text.magnifyingglass") {
                            modelReflex.getArrayReflexOfTxtFile()
                        }
                        
                        CreateMenuItemButton(text: "Reflexiones Personales", sysImageStr: "text.magnifyingglass") {
                            modelReflex.list = modelReflex.getAllReflexNoInbuiltGet()
                        }
                        
                        CreateMenuItemButton(text: "Reflexiones favoritas", sysImageStr: "text.magnifyingglass") {
                            modelReflex.list = modelReflex.getReflexFavoritasGet()
                        }
                        
                        CreateMenuItemButton(text: "Buscar en el contenido", sysImageStr: "text.magnifyingglass") {
                            showAlertSearchInTxt = true
                        }

                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                }
                        
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer(.fixed)
                }
                               
                ToolbarItem {
                    #if os(macOS)
                    Button{
                        showWindow(for: AddReflexView(reflexionAActualizar: nil),
                                   environmentObjects: [self.modelReflex],
                                   title: "Nueva Reflexión",
                                   size: AppCons.windows_size_content,
                                   isModal: false
                        )
                        
                    }label: {
                        Image(systemName: "plus")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                    #else
                    Button{
                        showSheetAddReflex = true
                    }label: {
                        Image(systemName: "plus")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                    #endif
                    
                
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
                AddReflexView(reflexionAActualizar: nil)
            })
            .alert(isPresented: $showalertDeleteItem){
                    Alert(title: Text("La Ley"),
                      message: Text("Desea eliminar la reflexión?"),
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
    
    

    
}

#Preview {
    ReflexListView()
}

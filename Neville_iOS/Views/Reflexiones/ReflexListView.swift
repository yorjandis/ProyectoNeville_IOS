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
                                           size: .absolute(CGSize(width: 600, height: 450)),
                                           isModal: true
                                )
                                
                               
                            }label: {
                                Text(item.title) //title
                                    .font(.system(size: CGFloat(self.fontSizeLista)))
                            }
                            .buttonStyle(.plain)
                            
                            
                            
                            //En macOS: muestra un botón al final para eliminar la reflexión
                            if !item.isInbuilt {
                                Spacer()
                                Button{
                                    self.entityForDelete = item
                                    showalertDeleteItem = true
                                }label:{
                                    Image(systemName: "xmark.circle")
                                }
                                .foregroundStyle(.red)
                                .padding(.trailing, 10)
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
                        showWindow(for: AddReflexView(),
                                   environmentObjects: [self.modelReflex],
                                   title: "Nueva Reflexión",
                                   size: .absolute(CGSize(width: 600, height: 450)),
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
    
    

    
}

#Preview {
    ReflexListView()
}

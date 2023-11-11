//
//  TxtConfeListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//Lista los elementos TXT de contenido que tienen prefijos: conf_, cita_, preg: y ayud_

import SwiftUI
import CoreData

struct TxtListView: View {
    
    @Environment(\.colorScheme) var theme
    
    let type : TxtContentModel.TipoDeContenido //Tipo de contenido a cargar
    
    @State var list : [TxtCont] = []
    
    @State var title : String //Es el título
    
    //Para Agregar notas
    @State var showAlertAddNote = false
    @State var textFiel = ""
    @State private var entidad : TxtCont = TxtCont(context: CoreDataController.dC.context) //Esto es para permitir editar la nota de la entidad
    
    

    var body: some View {
        
        NavigationStack{
            
            VStack{
                List(list){item in
                    HStack{
                        Image(systemName: "leaf.fill")
                            .padding(.horizontal, 5)
                            //.foregroundStyle(.linearGradient(colors: [.orange, .green], startPoint: .leading, endPoint: .trailing))
                            .foregroundStyle(.linearGradient(colors: [item.isfav ? .orange : .gray, item.nota!.isEmpty ? .gray : .green], startPoint: .leading, endPoint: .trailing))
                        
                        NavigationLink{
                            ContentTxtShowView(fileName: item.namefile ?? "", typeContent: self.type)
                        }label: {
                            Text(item.namefile ?? "")
                        }
                        .swipeActions(edge: .leading){
                            Button{
                                var isfav = item.isfav
                                isfav.toggle()
                                TxtContentModel().setFavState(entity: item, state: isfav)
                                withAnimation {
                                    let temp2 = list
                                    list.removeAll()
                                    list = temp2
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(Color.orange)
                            }
                            
                            NavigationLink{
                                EditNoteTxt(entidad: item)
                                    .presentationDetents([.medium])
                            }label: {
                                Image(systemName: "bookmark")
                                    .tint(.green)
                            }
                            
                        }
                    }
                    
                    
                }
                .onAppear{
                    list.removeAll()
                    list = TxtContentModel().getAllItems(type: self.type)
                    
                }
            }
            .navigationTitle(self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Menu{
                        Button("Todas las \(self.title)"){
                            list.removeAll()
                            list = TxtContentModel().getAllItems(type: self.type)
                        }
                        Button("\(self.title) favoritas"){
                            let temp = TxtContentModel().getAllFavorite(type:self.type)
                            list.removeAll()
                            list = temp
                            
                        }
                        Button("\(self.title) con notas"){
                            let temp = TxtContentModel().getAllNota(type:self.type)
                            list.removeAll()
                            list = temp
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

//
//  ListNotasViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 3/10/23.
//
//Lista todas las notas creadas y permite modificarlas y eliminarlas
// Y buscar dentro de ellas

import SwiftUI
import CoreData





struct ListNotasViews: View {
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    @State private var showAddNoteView = false
    @State private var list : [Notas] = NotasModel().getAllNotas()
    //Buscar en notas
    @State var showAlertSearch = false
    @State var textField = ""
    //Buscar en titulos de notas
    @State var showAlertSearchTitle = false
    @State var textFieldTitle = ""
 
    var body: some View {
        NavigationStack {
            List(list,id: \.id){nota in
               Row(notas: $list, nota: nota)
            }
            Spacer()
            Divider()
            HStack(spacing: 30){
                Spacer()
                
                Button("Volver"){
                    dimiss()
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
            .navigationTitle("Notas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Menu{
                        Button("Todas las notas"){
                            withAnimation {
                                list.removeAll()
                                list = NotasModel().getAllNotas()
                            }
                        }
                        Button("Notas Favoritas"){
                            withAnimation {
                                list.removeAll()
                                list = NotasModel().getFavNotas()
                            }
                            
                        }  
                        Button("Buscar en Notas"){
                            showAlertSearch = true
                        }
                        Button("Buscar en títulos"){
                            showAlertSearchTitle = true
                        }
                        
                        
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                    Button{
                        showAddNoteView = true
                    }label: {
                        Image(systemName: "plus")
                    }
                }
                
            }
            .sheet(isPresented: $showAddNoteView) {
                AddNotasView(notas: $list)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                
            }
            .alert("Buscar en Notas", isPresented: $showAlertSearch){
                TextField("", text: $textField, axis: .vertical)
                Button("Buscar"){
                    let temp = NotasModel().searchTextInNotas(text: textField, donde: .nota)
                    if temp.count > 0 {
                        list.removeAll()
                        list = temp
                    }
                }
            }
            .alert("Buscar en título de Notas", isPresented: $showAlertSearchTitle){
                TextField("", text: $textFieldTitle, axis: .vertical)
                Button("Buscar"){
                    let temp = NotasModel().searchTextInNotas(text: textFieldTitle, donde: .titulo)
                    if temp.count > 0 {
                        list.removeAll()
                        list = temp
                    }
                }
            }
        }
    }
    
    func updateYorj(nota : Notas){
        
        if  NotasModel().updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            print("")
            list.removeAll()
            list.append(contentsOf: NotasModel().getAllNotas())
        }
        
        
    }

}




//Representa un item de la lista
struct Row : View {

    @State private var confirm = false
    @State private var showUpdateNoteView = false
    @Binding var notas : [Notas] //Listado de Notas cargadas
    var nota: Notas //La nota para esta fila
    @State private var showConfirmDialogDeleteNota = false
   
    
    var body: some View {
        NavigationLink{
            ShowNotaView(nota: nota, notass: $notas)
        } label: {
            Text(nota.title ?? "")
        }
        .swipeActions(edge: .leading){
            Button{
                var stateFav = nota.isfav
                stateFav.toggle()
                if  NotasModel().updateFav(NotaID: nota.id ?? "", favState: stateFav) {
                    print("ok")
                }
            }label: {
                Image(systemName: "heart")
                    .tint(.black)
            }
        }
        .swipeActions(edge: .trailing){ //Eliminar una nota
            Button{
                showUpdateNoteView = true
            }label: {
                Image(systemName: "pencil.and.scribble")
                    .tint(.green)
            }
            Button{
                showConfirmDialogDeleteNota = true
            }label: {
                Image(systemName: "minus.circle")
                    .tint(.red)
            }
            
            
        }
        
        //Sheets:
        .sheet(isPresented: $showUpdateNoteView){
            UpdateNotasView(NotaId: nota.id ?? "", title:  nota.title ?? "", nota: nota.nota ?? "", notas: $notas)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
      
        //Dialogo de conformación para elimnar una nota
        .confirmationDialog("Esta seguro?", isPresented: $showConfirmDialogDeleteNota){
            Button("Eliminar Nota", role: .destructive){
                withAnimation {
                    NotasModel().deleteNota(nota: nota)
                      notas.removeAll()
                      notas.append(contentsOf: NotasModel().getAllNotas())
                }

            }
        } message: {
            Text("La nota será removida!!!")
        }

    }
    
}

















#Preview("Home") {
    ContentView()
        .dynamicTypeSize(.xxxLarge)
}

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
    @State private var showAddNoteView = false
    @State private var notas : [Notas] = ManageNotas().getAllNotas()
 
    var body: some View {
        NavigationStack {
            List(notas,id: \.id){nota in
               Row(notas: $notas, nota: nota)
            }
            Spacer()
            Divider()
            HStack(spacing: 30){
                Spacer()
                Button{ //Adicionar una nuena nota
                    showAddNoteView = true
                }label: {
                    Image(systemName: "note.text.badge.plus")
                        .tint(.green)
                        .font(.system(size: 24, weight: .ultraLight))
                }
                Button("Volver"){
                    dimiss()
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
           
            .navigationTitle("Notas")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddNoteView) {
                AddNotasView(notas: $notas)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                
            }
            
            
        }
    }
    
    func updateYorj(nota : Notas){
        
        if  ManageNotas().updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            print("")
            notas.removeAll()
            notas.append(contentsOf: ManageNotas().getAllNotas())
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
                    ManageNotas().deleteNota(nota: nota)
                      notas.removeAll()
                      notas.append(contentsOf: ManageNotas().getAllNotas())
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

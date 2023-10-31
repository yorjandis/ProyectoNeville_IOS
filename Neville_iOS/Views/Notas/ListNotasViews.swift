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
    @State var showAddNoteView = false
    @State var notas : [Notas] = manageNotas().getAllNotas()
 
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
        
        if  manageNotas().updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            print("")
            notas.removeAll()
            notas.append(contentsOf: manageNotas().getAllNotas())
        }
        
        
    }

}




//Representa un item de la lista
struct Row : View {
     var context = CoreDataController.dC.context
    @State var confirm = false
    @State var showUpdateNoteView = false
    @Binding var notas : [Notas] //Listado de Notas cargadas
    var nota: Notas //La nota para esta fila
    @State var showConfirmDialogDeleteNota = false
   
    
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
                deleteNota(nota: nota)
            }
        } message: {
            Text("La nota será removida!!!")
        }

    }
    
    //Función que elimina una nota de la BD
    func deleteNota(nota : Notas){
        let context = CoreDataController.dC.context
        context.delete(nota)
        do {
            if context.hasChanges {
                try context.save()
                notas.removeAll()
                notas.append(contentsOf: manageNotas().getAllNotas())
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
}

















#Preview("Home") {
    ContentView()
        .dynamicTypeSize(.xxxLarge)
}

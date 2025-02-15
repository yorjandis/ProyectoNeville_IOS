//
//  FilterByNotaView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 9/2/24.
//
// sheet que permite filtrar el contenido de las notas

import SwiftUI
/*
struct FilterByNotaView: View {
    @Binding var listRecord : [CKRecord]
    @Binding var showListOptions : Bool //permite cerrar la ventana de opciones de filtro
    @State private var texto : String   = ""
    @State private var showSheetTitulo  = false     //Abre/Cierra sheet
    @State private var showSheetTexto   = false     //Abre/Cierra sheet
    
    var body: some View {
        VStack(spacing: 15){
            Text("Filtrar Notas por...")
            Spacer()
            ScrollView {
                Button("Título"){
                    showSheetTitulo = true
                }
                
                Button("Texto"){
                    showSheetTexto = true
                }
                
                Button("Favoritos"){
                    self.listRecord.removeAll()
                    Task{
                        /*
                        self.listRecord = await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Notas, criterio: .favoritoNota)
                        showListOptions = false
                        */
                        
                    }
                   
                }
                
            }
                
            
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSheetTitulo, content: {
                VStack{
                    TextFieldLink("🔍 Título a buscar",prompt: Text("Texto del título")) { str in
                        listRecord.removeAll()
                        Task{
                            /*
                            listRecord =  await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Notas, criterio: .tituloNota, textoABuscar: str)
                            self.showSheetTitulo = false
                            self.showListOptions = false
                            */
                        }
                    }
                }
           
        })
        .sheet(isPresented: $showSheetTexto, content: {
                VStack{
                    TextFieldLink("🔍 Texto a buscar",prompt: Text("Texto de la nota")) { str in
                        listRecord.removeAll()
                        Task{
                            /*
                            listRecord =  await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Notas, criterio: .textoNota, textoABuscar: str)
                            self.showSheetTitulo = false
                            self.showListOptions = false
                            */
                        }
                    }
                }
           
        })
        
    }
    
    

}

#Preview {
    FilterByNotaView(listRecord: .constant([CKRecord]()), showListOptions: .constant(false))
}
*/

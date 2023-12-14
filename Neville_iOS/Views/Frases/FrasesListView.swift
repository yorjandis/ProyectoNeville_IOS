//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Lista todas las frases que tienen notas

import SwiftUI
import CoreData

struct FrasesListView: View {
    @Environment(\.colorScheme) var theme
    
    @State  var list : [Frases] = FrasesModel().GetRequest(predicate: nil)
    @State  private var showAddFrase = false
    @State private var subtitle = "Todas las Frases"
    //Buscar en frase
    @State private var showAlertSearchInFrase = false
    @State private var textFiel = ""
    //Buscar en notas de frase
    @State private var showAlertSearchInNotaFrase = false
    @State private var textFiel2 = ""
    
    var body: some View {
        NavigationStack{
            VStack {
                Text(subtitle)
                    .font(.caption)
                
                List(list, id: \.id){ frase in
                    VStack(alignment: .leading){
                        Text(frase.frase ?? "")
                        //Marcar las frases nuevas
                        if frase.isnew {
                            Text("Nueva")
                                .font(.footnote).bold()
                                .foregroundStyle(Color.orange)
                                .fontDesign(.serif)
                        }
                    }
                    
                        //Modificar el campo nota de una frase
                        .swipeActions(edge: .leading, allowsFullSwipe: true){
                            NavigationLink{
                                FrasesNotasAddView( frase: frase, nota: frase.nota ?? "")
                            }label: {
                                Image(systemName: "bookmark")
                                    .tint(.green)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true){
                            //Solo se pueden borrar las frases personalas: NoInbuilt
                            NavigationLink{
                                GenerateQRView(footer: frase.frase ?? "")
                            }label: {
                                Image(systemName: "qrcode")
                                    .tint(.brown)
                            }
                            //Ajustar el estado de favorito de una frase
                            Button{
                                var isfav : Bool = frase.isfav
                                isfav.toggle()
                                if FrasesModel().updateFavState(fraseID: frase.id ?? "", statusFav: isfav){
                                    list.removeAll()
                                    list = FrasesModel().GetRequest(predicate: nil)
                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(.orange)
                            }
                            
                            //Solo para frases NO Inbuilt
                            if frase.noinbuilt{
                                NavigationLink{
                                    FrasesUpdateView(frase: frase, list: list)
                                }label: {
                                    Image(systemName: "pencil.and.scribble")
                                        .tint(.green)
                                }
                                Button{
                                    FrasesModel().Delete(frase: frase)
                                    withAnimation {
                                            list.removeAll()
                                            list = FrasesModel().GetRequest(predicate: FrasesModel.PredicatesTypes().getAllPersonalFrases)     
                                    }
                                }label: {
                                    Image(systemName: "trash")
                                        .tint(.red)
                                }
                            }
                            
                        }
                    
                }
                .backgroundStyle(.red)
                .onAppear{
                    list.removeAll()
                    list = FrasesModel().GetRequest(predicate: nil)
                }
                .navigationTitle("Listado de Frases")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    
                    Menu{
                        Button("Todas las Frases"){withAnimation {
                            list.removeAll(); list = FrasesModel().GetRequest(predicate: nil)}
                            subtitle = "Todas las Frases"
                        }
                        Button("Frases Personales"){withAnimation {
                            list.removeAll(); list = FrasesModel().getFrasesNoInbuilt()}
                            subtitle = "Frases Personales"
                        }
                        Button("Frases Favoritas"){withAnimation {
                            list.removeAll(); list = FrasesModel().getAllFavFrases()}
                            subtitle = "Frases Favoritas"
                        }
                        Button("Frases con notas"){withAnimation {
                            list.removeAll(); list = FrasesModel().getAllNotasFrases()}
                            subtitle = "Frases con notas"
                        }
                        Button("Buscar en frase"){
                            subtitle = "Búsqueda en Frase"
                            showAlertSearchInFrase = true
                        }
                        Button("Buscar en nota de frase"){
                            subtitle = "Búsqueda en nota de Frase"
                            showAlertSearchInNotaFrase = true
                        }
                        Button("Frases recién añadidas"){withAnimation {
                            list.removeAll()
                            list = FrasesModel().getAllNewsElements()}
                            subtitle = "Frases nuevas"
                        }
                        if subtitle == "Frases nuevas" {
                            Button("Desmarcar frases nuevas"){
                                FrasesModel().RemoveAllNewFlag()
                            }
                        }
                            
                        }label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundStyle(theme ==  .dark ? .white :  .black)
                        }
                    
                        //Boton Adicionar una frase
                        Button{
                            showAddFrase = true
                        }label: {
                            Image(systemName: "plus")
                                .foregroundStyle(theme ==  .dark ? .white :  .black)
                        }
                    }
                    
                }
                .sheet(isPresented: $showAddFrase){
                    FraseAddView()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
                }
                .alert("Buscar en Frase", isPresented: $showAlertSearchInFrase){
                    TextField("", text: $textFiel)
                    Button("Buscar"){
                        let arrayResult = FrasesModel().searchTextInFrases(text: textFiel)
                        if arrayResult.count > 0 {
                            list.removeAll()
                            list = arrayResult
                        }
                        
                    }
                    
                }
                .alert("Buscar en nota de Frase", isPresented: $showAlertSearchInNotaFrase){
                    TextField("", text: $textFiel2)
                    Button("Buscar"){
                        let arrayResult = FrasesModel().searchTextInNotaFrases(textNota: textFiel2)
                        if arrayResult.count > 0 {
                            list.removeAll()
                            list = arrayResult
                        }
                        
                    }
                    
                }
            }
            
        }
        
    }
    

#Preview {
    ContentView()
}

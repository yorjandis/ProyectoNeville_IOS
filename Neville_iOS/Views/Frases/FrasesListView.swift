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
    
    private let context : NSManagedObjectContext = CoreDataController.dC.context
    
    @State  var frase : Frases = Frases()
    @State  var list : [Frases] = FrasesModel().getAllFrases()
    
    
    @State  private var showAddFrase = false
  
    
    
    var body: some View {
        NavigationStack{
            List(list, id: \.id){ frase in
                Text(frase.frase ?? "")
                    .swipeActions(edge: .trailing, allowsFullSwipe: true){
                        //Solo se pueden borrar las frases personalas: NoInbuilt
                        if FrasesModel().CheckIfNotInbuiltFrase(frase: frase){
                            Button{
                                FrasesModel().Delete(frase: frase)
                                withAnimation {
                                    list.removeAll()
                                    list = FrasesModel().getAllFrases()
                                }
                            }label: {
                                Image(systemName: "trash")
                                    .tint(.red)
                            }
                            
                            NavigationLink{
                                FrasesUpdateView(frase: frase, list: list)
                            }label: {
                                Image(systemName: "pencil.and.scribble")
                                    .tint(.green)
                            }
                            
                            
                            
                        }
                        
                    }
                    
            }
            .navigationTitle("Listado de Frases")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
  
                Menu{
                    Button("Todas las Frases"){withAnimation {
                        list.removeAll(); list = FrasesModel().getAllFrases()}
                    }
                    Button("Frases Personales"){withAnimation {
                        list.removeAll(); list = FrasesModel().getFrasesNoInbuilt()}
                    }
                    Button("Frases Favoritas"){withAnimation {
                        list.removeAll(); list = FrasesModel().getAllFavFrases()}
                    }
                    Button("Frases con notas"){withAnimation {
                        list.removeAll(); list = FrasesModel().getAllNotasFrases()}
                    }
                    
                }label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .tint(.black)
                }
                
                Button{
                    showAddFrase = true
                }label: {
                    Image(systemName: "plus")
                        .foregroundColor(Color.black)
                }
            }
            .sheet(isPresented: $showAddFrase){
                FraseAddView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            
        }
        
    }
    
    
    
    
    
}

#Preview {
    ContentView()
}

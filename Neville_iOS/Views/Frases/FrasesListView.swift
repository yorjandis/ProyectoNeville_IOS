//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Muesta y maneja el listado de frases

import SwiftUI
import CoreData

struct FrasesListView: View {
    @Environment(\.colorScheme) var theme
    @EnvironmentObject private var frasesModel: FrasesModel
    
    @State private var showAddFrase = false
    @State private var subtitle = "Todas las Frases"
    
    //Buscar en la lista actual
    @State private var showAlertSearchInFrase = false
    @State private var textFieldFrase = ""
    @State private var listadoTemporal : [String] =  []
    @FocusState private var focused: Bool
    
    
    //Buscar en todas las frases
    @State private var showAlertSearchInFraseAll = false
    @State private var textFieldFraseAll = ""
    
    //Buscar en notas de frase
    @State private var showAlertSearchInNotaFrase = false
    @State private var textFieldNota = ""
    

    
    var body: some View {
        NavigationStack{
            VStack {
                //Búsqueda:
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar", text: self.$textFieldFrase)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .focused(self.$focused)
                        .onChange(of: self.focused) { oldValue, newValue in
                            //Me aseguro de hacer una copia del listado original una sola vez
                            //Mientras se usa el cuadro de búsqueda
                            if self.textFieldFrase.isEmpty{
                                if newValue{
                                    self.listadoTemporal = self.frasesModel.listfrases
                                }
                            }
                        }
                }
                
                List(frasesModel.listfrases, id: \.self){ frase in
                    VStack(alignment: .leading){
                        Text(frase)
                    }
                    //Modificar el campo nota de una frase
                    .swipeActions(edge: .leading, allowsFullSwipe: true){
                        NavigationLink{
                             FrasesNotasAddView( frase: frase)
                        }label: {
                            Image(systemName: "bookmark")
                                .tint(.green)
                        }
                        if frasesModel.isNoInbuilt(frase: frase){
                            Button{
                                withAnimation {
                                    if frasesModel.DeleteFraseInbuilt(frase: frase){
                                        frasesModel.getfrasesArrayFromTxtFile() //Recargando el listado
                                    }
                                }
                            }label:{
                                Image(systemName: "minus.circle.fill")
                                    .tint(.red.opacity(0.8))
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true){
                        //Solo se pueden borrar las frases personalas: NoInbuilt
                        NavigationLink{
                            GenerateQRView(footer: frase)
                        }label: {
                            Image(systemName: "qrcode")
                                .tint(.brown)
                        }
                        //Ajustar el estado de favorito de una frase
                        Button{
                            var favState = FrasesModel().isFavFrase(frase)
                            favState.toggle()
                            _ = FrasesModel().setFavFrase(frase, favState)
                        }label: {
                            Image(systemName: "heart")
                                .tint(.orange)
                        }
                    }
                    
                }
                .backgroundStyle(.red)
                .task{
                    frasesModel.getfrasesArrayFromTxtFile()
                }
                .onChange(of: self.textFieldFrase, { oldValue, newValue in
                    if self.textFieldFrase.isEmpty{
                        frasesModel.listfrases = self.listadoTemporal //restaura el listado actual
                    }else{ //Ejecuta el filtro
                        let filtro = self.listadoTemporal.filter{$0.lowercased().contains(newValue.lowercased()) }
                        self.frasesModel.listfrases = filtro //Actualiza el listado con el filtro
                    }
                })
                
                .navigationTitle("Listado de Frases")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    Menu{
                        Button("Todas las Frases"){
                            withAnimation {
                                frasesModel.getfrasesArrayFromTxtFile()
                            }
                        }
                        Button("Frases Personales"){
                            withAnimation {
                                frasesModel.listfrases = frasesModel.getFrasesNoInbuilt()
                            }
                            
                        }
                        Button("Frases Favoritas"){
                            withAnimation {
                                frasesModel.listfrases = frasesModel.getAllFavFrases()
                            }
                        }
                        Button("Frases con notas"){
                            withAnimation {
                                frasesModel.listfrases = frasesModel.getFrasesConNotas()
                            }
                        }
                        Button("Buscar en frase"){
                            subtitle = "Búsqueda en Frase"
                            showAlertSearchInFrase = true
                        }
                        Button("Buscar en nota de frase"){
                            subtitle = "Búsqueda en nota de Frase"
                            showAlertSearchInNotaFrase = true
                        }
                        
                    }label: { //Label del Mnú
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
                EmptyView()
                FraseAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
            .alert("Buscar en Frase", isPresented: $showAlertSearchInFraseAll){
                TextField("", text: $textFieldFraseAll)
                Button("Buscar"){
                    frasesModel.listfrases.removeAll()
                    frasesModel.listfrases = FrasesModel().searchTextInFrases(text: textFieldFrase)
                }
                
            }
            .alert("Buscar en nota de Frase", isPresented: $showAlertSearchInNotaFrase){
                TextField("", text: $textFieldNota)
                Button("Buscar"){
                    frasesModel.listfrases.removeAll()
                    frasesModel.listfrases = FrasesModel().searchTextInNotaFrases(textNota: self.textFieldNota)
                }
                
            }
        }
        
    }
        
    }
    

#Preview {
    FrasesListView()
}

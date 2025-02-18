//
//  TxtConfelistadoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//lista los elementos TXT de contenido que tienen prefijos: conf_, cita_, preg: y ayud_

import Foundation
import SwiftUI
import CoreData

struct TxtListView: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var modeloTxt : TxtContentModel
    
    let typeOfContent : TipoDeContenido //Tipo de contenido a cargar

    @State var title : String //Es el título
    
    //Para Agregar notas
    @State var showAlertAddNote = false
    @State var textFiel = ""
    
    //Para buscar en texto:
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    
    //Para buscar en notas:
    @State var showAlertSearchInNotas = false
    @State var textFiel3 = ""
    

    //Buscar en la lista actual
    @State private var showAlertSearchInTitles = false
    @State private var textFieldTxtTitles = ""
    @State private var listadoTemporal : [String] =  []
    @FocusState private var focused: Bool
    
    

    var body: some View {
        
        NavigationStack{
            VStack{
                //Búsqueda:
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar", text: self.$textFieldTxtTitles)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .focused(self.$focused)
                        .onChange(of: self.focused) { oldValue, newValue in
                            //Me aseguro de hacer una copia del listado original una sola vez
                            //Mientras se usa el cuadro de búsqueda
                            if self.textFieldTxtTitles.isEmpty{
                                if newValue{
                                    self.listadoTemporal = modeloTxt.getArrayOfAllFileTxtOfType(type: self.typeOfContent)
                                }
                            }
                        }
                        .onChange(of: self.textFieldTxtTitles, { oldValue, newValue in
                            if newValue.isEmpty{
                                modeloTxt.textList = self.listadoTemporal //restaura el listado actual
                            }else{ //Ejecuta el filtro
                                let filtro = self.listadoTemporal.filter{$0.lowercased().contains(newValue.lowercased()) }
                                modeloTxt.textList = filtro //Actualiza el listado con el filtro
                            }
                        })
                }
                
                List(modeloTxt.textList, id: \.self){nombreTxt in
                    VStack(alignment: .leading) {
                        HStack{
                            Image(systemName: "leaf.fill")
                                .padding(.horizontal, 5)
                                .foregroundStyle(.linearGradient(colors: [
                                    (modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent)) ? .orange : .gray, (modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: typeOfContent)) ? .green : .gray], startPoint: .leading, endPoint: .trailing))
                            
                            //Abrir la conferencia
                            NavigationLink{
                                
                                ContentTxtShowView(title: self.title, nombreTxt: nombreTxt, type: self.typeOfContent)
                                
                            }label: {
                                Text(nombreTxt)
                            }
                        }
                    }
                        .swipeActions(edge: .leading){
                            Button{ //Poner favorito
                                var temp = modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: typeOfContent)
                                temp.toggle()
                                if TxtContentModel().setIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent, isFav: temp){
                                    
                                 self.modeloTxt.getAllFileTxtOfType(type: self.typeOfContent) //Actualizando el listado

                                }
                            }label: {
                                Image(systemName: "heart")
                                    .tint(Color.orange)
                            }
                            NavigationLink{
                                EditNoteTxt(entidad: nombreTxt, typeOfContent: self.typeOfContent)
                            }label: {
                                Image(systemName: "bookmark")
                                    .tint(Color.green)
                            }
                    }
                    
                }
            }
            .navigationTitle(self.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                HStack{
                    Spacer()
                    Menu{
                        Button("Todas las \(self.title)"){
                            withAnimation {
                                modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                            }
                            
                        }
                        Button("\(self.title) favoritas"){
                            withAnimation {
                                modeloTxt.textList = modeloTxt.getArrayFavTxt(type: self.typeOfContent)
                            }
                            
                        }
                        Button("\(self.title) con notas"){
                            withAnimation {
                                modeloTxt.textList = modeloTxt.getArrayNoteTxt(type: self.typeOfContent)
                            }
                           
                        }

                        Button("Buscar en el contenido"){
                            showAlertSearchInTxt = true
                        }
                        
                        Button("Buscar en las notas"){
                            showAlertSearchInNotas = true
                        }
                        
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                    
                }
            }
            .task{
               modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
            }
            .alert("Buscar en contenido", isPresented: $showAlertSearchInTxt){
                TextField("", text: $textFiel2, axis: .vertical)
                Button("Cancelar"){showAlertSearchInTxt = false}
                    .multilineTextAlignment(.leading)
                Button("Buscar"){
                    modeloTxt.textList = modeloTxt.searchInTxt(str: self.textFiel2, type: self.typeOfContent)
                }
                
            }
            .alert("Buscar en las notas", isPresented: $showAlertSearchInNotas){
                TextField("", text: $textFiel3, axis: .vertical)
                Button("Cancelar"){showAlertSearchInNotas = false}
                    .multilineTextAlignment(.leading)
                Button("Buscar"){
                    modeloTxt.textList = modeloTxt.searchInNotesTxt(str: self.textFiel3, type: self.typeOfContent)
                }
                
            }
            
        }
        
    }
}


//Permite ver y editar el campo nota
struct EditNoteTxt:View {
    @Environment(\.dismiss) var dimiss
    @EnvironmentObject var modeloTxt : TxtContentModel
    @State var entidad : String
    @State var typeOfContent : TipoDeContenido
    
    @State private var textfiel = ""
    @Environment(\.managedObjectContext) private var context

    
    var body: some View {
        NavigationStack{
            ZStack{
                LinearGradient(colors: [.black.opacity(0.7), .brown], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                VStack(){
                    TextField("Coloque su nota aqui", text: $textfiel, axis: .vertical)
                        .multilineTextAlignment(.leading)
                        .font(.title)
                        .foregroundStyle(.white).italic().bold()
                        .onAppear {
                            textfiel = modeloTxt.getNotaOfTXT(nombreTxt: self.entidad, type: typeOfContent )
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
                        if modeloTxt.setNotaOfTXT(nombreTxt: entidad, type: self.typeOfContent, nota: textfiel){
                            modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                        }
                        dimiss()
                    }label: {
                        Text("Guardar")
                            .foregroundStyle(.blue).bold()
                    }
                }
            }
        }
    }
}



#Preview {
    TxtListView(typeOfContent: .conf , title: "Lecturas")
}

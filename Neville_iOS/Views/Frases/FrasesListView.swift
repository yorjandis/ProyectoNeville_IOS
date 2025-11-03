//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Muesta y maneja el listado de frases en una ventana dedicada

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
    @FocusState private var focused: Bool
    
    
    //Buscar en todas las frases
    @State private var showAlertSearchInFraseAll = false
    @State private var textFieldFraseAll = ""
    
    //Buscar en notas de frase
    @State private var showAlertSearchInNotaFrase = false
    @State private var textFieldNota = ""
    
    @State var listadoPropio : [String] = []
    
    //Tipos de criteros para filtrar el listado
    enum CriterioFiltro{
        case Buscar
        case ListadoFull
        case FrasesPersonales
        case FrasesFavoritas
        case FrasesConNotas
        case BuscarEnNotas
    }
    
    enum TipoBusqueda{
        case TodasFrases
        case FrasesPersonales
        case FrasesFavoritas
        case FrasesConNotas
        case ResultadosDeBusquedaEnNotas
    }
    @State private var TiposDeBusqueda : TipoBusqueda = .TodasFrases
    
    
    private func FiltrarListado(_ tipo : CriterioFiltro   = .ListadoFull){
        
        switch tipo {
        case .Buscar: //Cuadro de búsqueda general
            if self.textFieldFrase.isEmpty{
                //Si el cuadro de búsqueda esta vacio se restuara el listado según el filtro seleccionado
                switch TiposDeBusqueda {
                case .FrasesPersonales:
                    self.listadoPropio =  frasesModel.getFrasesNoInbuilt()
                case .FrasesFavoritas:
                    self.listadoPropio =   frasesModel.getAllFavFrases()
                case .FrasesConNotas:
                    self.listadoPropio =  frasesModel.getFrasesConNotas()
                case .TodasFrases:
                    self.listadoPropio =  frasesModel.listfrases
                case .ResultadosDeBusquedaEnNotas:
                    print("")
                }
            }else{
                
                switch TiposDeBusqueda {
                case .FrasesPersonales:
                    let temp = frasesModel.getFrasesNoInbuilt()
                    self.listadoPropio =  temp.filter{$0.localizedCaseInsensitiveContains(self.textFieldFrase)}
                case .FrasesFavoritas:
                    let temp = frasesModel.getAllFavFrases()
                    self.listadoPropio =  temp.filter{$0.localizedCaseInsensitiveContains(self.textFieldFrase)}
                case .FrasesConNotas:
                    let temp = frasesModel.getFrasesConNotas()
                    self.listadoPropio =  temp.filter{$0.localizedCaseInsensitiveContains(self.textFieldFrase)}
                case .TodasFrases:
                    let temp = frasesModel.listfrases
                    self.listadoPropio =  temp.filter{$0.localizedCaseInsensitiveContains(self.textFieldFrase)}
                    
                case .ResultadosDeBusquedaEnNotas:
                    print("")
                }
            }
        case .ListadoFull: //Obtiene el listado completo de las frases
            self.listadoPropio =  frasesModel.listfrases
        case .FrasesPersonales:
            self.listadoPropio = frasesModel.getFrasesNoInbuilt()
        case .FrasesFavoritas:
            self.listadoPropio = frasesModel.getAllFavFrases()
        case .FrasesConNotas:
            self.listadoPropio = frasesModel.getFrasesConNotas()
        case .BuscarEnNotas:
            self.listadoPropio = frasesModel.searchTextInNotaFrases(textNota: self.textFieldNota)
            
        }
        
    }
    

    

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
                        .onSubmit {
                            self.FiltrarListado(.Buscar)
                        }
                        
                }
                .padding(.horizontal)
                
                List(self.listadoPropio, id: \.self){ frase in
                    VStack(alignment: .leading){
                        Text(frase)
                    }
                    //Modificar el campo nota de una frase
                    .swipeActions(edge: .leading, allowsFullSwipe: true){
                        
                        //Esta View no se mostrará si Apple Intelligence no esta disponible
                        if #available(iOS 26.0, *) {
                            if IAModelAppleIntelligence.isAvailable() {
                                Menu{
                                    NavigationLink{
                                            RespondView(nameConference: "", texto: frase, tipoSalida: .interpretar )
                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                    NavigationLink{
                                            RespondView(nameConference: "", texto: frase, tipoSalida: .practicaConcreta)
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                    NavigationLink{
                                        ChatView(textoACargar: frase)
                                    }label: {
                                        Label("Charlar con IA", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                }label:{
                                    Image(systemName: "sparkles")
                                }
                                .tint(.purple)
                            }
                            
                            
                        }
                        //Notas de la Frase
                        NavigationLink{
                             FrasesNotasAddView( frase: frase)
                        }label: {
                            Image(systemName: "bookmark")
                                .tint(.green)
                        }
                        
                        //Si la Frase es personal, permite eliminarla
                        if frasesModel.isNoInbuilt(frase: frase){
                            Button{
                                withAnimation {
                                    if frasesModel.DeleteFraseInbuilt(frase: frase){
                                        frasesModel.getAllFrases() //Recargando el listado
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
                            let current = frasesModel.isFavFrase(frase)
                            let newValue = !current
                            if frasesModel.setFavFrase(frase, newValue) {
                                    //Recrear el listado actual solo si estamos en las frases favoritas:
                                    if self.TiposDeBusqueda == .FrasesFavoritas{
                                        withAnimation {
                                            FiltrarListado(.FrasesFavoritas)
                                    }
                                   
                                }
                                
                            }
                        }label: {
                            Image(systemName: "heart")
                                .tint( frasesModel.isFavFrase(frase) ? .orange : .gray)
                        }
                    }
                    
                }
                .backgroundStyle(.red)
                .task{
                    //Cargando el listado completo
                    self.FiltrarListado()
                }
                
                HStack{
                   //Cambia la info en la barra de estado inferior de cuerdo al tipo de busqueda:
                    switch self.TiposDeBusqueda{
                    case .FrasesConNotas:
                        Text("Frases con notas: \(self.listadoPropio.count)")
                    case .TodasFrases:
                        Text("Todas las Frases: \(self.listadoPropio.count)")
                    case .FrasesPersonales:
                        Text("Frases Personales: \(self.listadoPropio.count)")
                    case .FrasesFavoritas:
                        Text("Frases Favoritas: \(self.listadoPropio.count)")
                    case .ResultadosDeBusquedaEnNotas:
                        Text("Resultado de Búsqueda en Notas: \(self.listadoPropio.count)")
                    }
                    Spacer()
                }.padding(.horizontal)
                
                .navigationTitle("Listado de Frases")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    
                    ToolbarItem {
                        Menu{
                            
                            CreateMenuItemButton(text: "Todas las Frases", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusqueda = .TodasFrases
                                withAnimation {
                                    FiltrarListado(.ListadoFull)
                                }
                            }
                            
                            CreateMenuItemButton(text: "Frases Personales", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusqueda = .FrasesPersonales
                                withAnimation {
                                    FiltrarListado(.FrasesPersonales)
                                }
                            }
                           
                            CreateMenuItemButton(text: "Frases Favoritas", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusqueda = .FrasesFavoritas
                                withAnimation {
                                    FiltrarListado(.FrasesFavoritas)
                                }
                            }
                            
                            CreateMenuItemButton(text: "Frases con notas", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusqueda = .FrasesConNotas
                                withAnimation {
                                    FiltrarListado(.FrasesConNotas)
                                }
                            }

                            CreateMenuItemButton(text: "Buscar en nota de frase", sysImageStr: "text.magnifyingglass") {
                                subtitle = "Búsqueda en nota de Frase"
                                showAlertSearchInNotaFrase = true
                            }
                        }label: { //Label del Menú
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundStyle(.primary)
                        }
                    }
                    
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    ToolbarItem{
                        //Boton Adicionar una frase
                        Button{
                            showAddFrase = true
                        }label: {
                            Image(systemName: "plus")
                                .foregroundStyle(theme ==  .dark ? .white :  .black)
                        }
                    }

                    
                }
                
            }

            .sheet(isPresented: $showAddFrase){
                FraseAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
            .alert("Buscar en nota de Frase", isPresented: $showAlertSearchInNotaFrase){
                TextField("", text: $textFieldNota)
                Button("Buscar"){
                    if !self.textFieldNota.isEmpty{
                        self.TiposDeBusqueda = .ResultadosDeBusquedaEnNotas
                        FiltrarListado(.BuscarEnNotas)
                    }
                    
                }
                
            }
        }
        
    }
        
    }
    

#Preview {
    FrasesListView()
}

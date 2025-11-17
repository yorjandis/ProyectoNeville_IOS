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
    @EnvironmentObject private var settingModel: SettingModel
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)     var fontSizeFrases      : Int = 24
    
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
    
    @State private var listadoPropio : [String] = []
    
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
    @State private var TiposDeBusquedaActual : TipoBusqueda = .TodasFrases //Almacena el tipo de listado que hay actualmente
    @State private var CriterioFiltroActual : CriterioFiltro = .ListadoFull //Almacena el tipo de Criterio de filtro  que hay actualmente
    
    
    private func FiltrarListado(_ tipo : CriterioFiltro   = .ListadoFull){
        
        self.listadoPropio.removeAll()
        
        switch tipo {
            //Devuelve una lista de acuerdo al contenido del cuadro de bisqueda
        case .Buscar:
            if self.textFieldFrase.isEmpty{ //No hay una búsqueda activa
                //Si el cuadro de búsqueda esta vacio se restuara el listado según el filtro seleccionado
                switch TiposDeBusquedaActual {
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
                
                switch TiposDeBusquedaActual {
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
                        .font(.system(size: 20))
                        .padding(8)
                        .focused(self.$focused)
                        .onSubmit {
                            self.FiltrarListado(.Buscar)
                        }
                        
                }
                .padding(.horizontal)
                #if os(macOS)
                .background(.windowBackground)
                #endif
                
                List(self.listadoPropio, id: \.self){ frase in
                    LazyVStack(alignment: .leading){
                        #if os(macOS)
                        //Vista de listado de Frases desde macOS, con un Menu al final de cada frase
                        HStack{
                            //Mostrar Un icono de favorito si la frase es favorita
                            if self.frasesModel.isFavFrase(frase) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 5)
                            }
                            Text(frase)
                                .font(.system(size: 22))
                                .foregroundStyle(.primary)
                                .textSelection(.enabled)
                                .padding(.vertical, 15)
                            Spacer()
                            Menu("..."){
                                //Notas de la Frase
                                Button{
                                    showWindow(for: FrasesNotasAddView( frase: frase),
                                               environmentObjects: [self.frasesModel],
                                               title: "Frases",
                                               size: .absolute(CGSize(width: 600, height: 450)),
                                               isModal: true
                                    
                                    )
                                     
                                }label: {
                                    Label("Notas",systemImage: "bookmark")
                                    .tint(.green)
                                    
                                }
                                
                                //Ajustar el estado de favorito de una frase
                                Button{
                                    let current = frasesModel.isFavFrase(frase)
                                    let newValue = !current
                                    if frasesModel.setFavFrase(frase, newValue) {
                                            //Recrear el listado actual solo si estamos en las frases favoritas:
                                        print(self.CriterioFiltroActual)
                                                withAnimation {
                                                    FiltrarListado(self.CriterioFiltroActual)
                                            }
                                        
                                    }
                                }label: {
                                    Label("Favorito", systemImage: "heart.fill")
                                        .tint( frasesModel.isFavFrase(frase) ? .orange : .gray)
                                }
                                
                                
                                //Generando el QR de la frase
                                Button{
                                    showWindow(for: GenerateQRView(footer: frase),
                                               environmentObjects: [self.frasesModel],
                                               title: "Frases",
                                               size: .absolute(CGSize(width: 600, height: 450)),
                                               isModal: true
                                    
                                    )
                                    
                                }label: {
                                    Label("Generar QR", systemImage: "qrcode")
                                        .tint(.brown)
                                }
                                
                                if #available(iOS 26.0, macOS 26.0,  *) {
                                    if IAModelAppleIntelligence.isAvailable() {
                                        
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: frase, tipoSalida: .interpretar),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: .absolute(CGSize(width: 600, height: 450)),
                                                       isModal: true,
                                                       isIAWindows: true)
                                            //RespondView(nameConference: "", texto: self.frase, tipoSalida: .interpretar)
                                        }label: {
                                            Label("Interpretar", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: frase, tipoSalida: .practicaConcreta),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: .absolute(CGSize(width: 600, height: 450)),
                                                       isModal: true,
                                                       isIAWindows: true)
                                            //RespondView(nameConference: "", texto: self.frase, tipoSalida: .practicaConcreta)
                                        }label: {
                                            Label("Aplicación Práctica", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: ChatView(textoACargar: frase),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: .absolute(CGSize(width: 600, height: 450)),
                                                       isModal: false,
                                                       isIAWindows: true)
                                            
                                        }label: {
                                            Label("Charlar con la IA", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                    }
                                }
                                
                                //Si la Frase es personal, permite eliminarla
                                if frasesModel.isNoInbuilt(frase: frase){
                                    Button{
                                        withAnimation {
                                            if frasesModel.DeleteFraseInbuilt(frase: frase){
                                                FiltrarListado(self.CriterioFiltroActual) //Actualizando el listado actual
                                            }
                                        }
                                    }label:{
                                        Label("Eliminar",systemImage: "minus.circle.fill")
                                            .tint(.red.opacity(0.8))
                                    }
                                }
                                
                            }
                        }
                        
                        #else
                        Text(frase)
                            .font(.system(size: 20))
                            .textSelection(.enabled)
                        //SelectableText(frase) //No funciona, no se ve el texto de la frase. Puede ser porque esta embebido en una List
                        #endif
                        
                    }
                    //Modificar el campo nota de una frase
                    .swipeActions(edge: .leading, allowsFullSwipe: true){
                        
                        //Esta View no se mostrará si Apple Intelligence no esta disponible
                        if #available(iOS 26.0, macOS 26.0,  *) {
                            if IAModelAppleIntelligence.isAvailable() {
                                Menu{
                                    NavigationLink{
                                            RespondView(nameConference: "", texto: frase, tipoSalida: .interpretar )
                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
                                    NavigationLink{
                                            RespondView(nameConference: "", texto: frase, tipoSalida: .practicaConcreta)
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
                                    NavigationLink{
                                        ChatView(textoACargar: frase)
                                    }label: {
                                        Label("Charlar con IA", systemImage: "sparkles")
                                    }
                                    .tint(.orange)
                                    
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
                        //Generando el QR de la frase
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
                                    if self.TiposDeBusquedaActual == .FrasesFavoritas{
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
                    self.FiltrarListado() //Por defecto carga todas las Frases
                }
                
                //Actualiza la información de la cantidad de elementos en la barra de estado inferior
                HStack{
                    switch self.TiposDeBusquedaActual{
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
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar{
                    //Aplica varios filtros al listado de Frases
                    ToolbarItem {
                        Menu{
                            
                            CreateMenuItemButton(text: "Todas las Frases", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusquedaActual = .TodasFrases //Almacenando el valor actual
                                self.CriterioFiltroActual = .ListadoFull  //Almacenando el valor actual
                                withAnimation {
                                    FiltrarListado(.ListadoFull)
                                }
                            }
                            
                            CreateMenuItemButton(text: "Frases Personales", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusquedaActual = .FrasesPersonales
                                self.CriterioFiltroActual = .FrasesPersonales
                                withAnimation {
                                    FiltrarListado(.FrasesPersonales)
                                }
                            }
                           
                            CreateMenuItemButton(text: "Frases Favoritas", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusquedaActual = .FrasesFavoritas
                                self.CriterioFiltroActual = .FrasesFavoritas
                                withAnimation {
                                    FiltrarListado(.FrasesFavoritas)
                                }
                            }
                            
                            CreateMenuItemButton(text: "Frases con notas", sysImageStr: "text.magnifyingglass") {
                                self.TiposDeBusquedaActual = .FrasesConNotas
                                self.CriterioFiltroActual = .FrasesConNotas
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
                    
                    if #available(iOS 26.0, macOS 26.0,  *) {
                        ToolbarSpacer(.fixed)
                    }
                    ToolbarItem{
                        //Boton Adicionar una frase
                        Button{
                            #if os(macOS)
                            showWindow(for: FraseAddView(),
                                       environmentObjects: [self.frasesModel],
                                       title: "Adicionar Frase",
                                       size: .absolute(CGSize(width: 600, height: 450)),
                                       isModal: true) {
                                //Si el listado actual es frases personales se actualiza:
                                    Task{ @MainActor in
                                        if self.CriterioFiltroActual == .FrasesPersonales {
                                        FiltrarListado(self.CriterioFiltroActual) //Actualizando...
                                    }
                                }
                            }
                            #else
                            showAddFrase = true
                            #endif
                            
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
                        self.TiposDeBusquedaActual = .ResultadosDeBusquedaEnNotas
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

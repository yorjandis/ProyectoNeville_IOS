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
    @EnvironmentObject private var frasesModel: FrasesModel //El modelo ya viene con la precarga de todas las frases en su inicializador init(){}
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
    
    //Eliminar una frase
    @State private var showConfirmDialogDeleteFrase : Bool = false
    @State private var TextoFraseAEliminar : String?
    
    

    

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
                            Task{
                                print(frasesModel.buscarEn)
                                frasesModel.criterioFiltroActual = .Buscar
                                await frasesModel.FiltrarListado(textAbuscar: self.textFieldFrase)
                            }
                            
                        }
                        
                }
                .padding(.horizontal)
                #if os(macOS)
                .background(.windowBackground)
                #endif
                
                List(frasesModel.listfrases, id: \.self){ frase in
                    VStack(alignment: .leading){
                        #if os(macOS)
                        //Vista de listado de Frases desde macOS, con un Menu al final de cada frase
                        HStack{
                           RowFraseMenu(frase: frase, frasesModel: self.frasesModel, settingModel: self.settingModel)
                            
                            
                            //Mostrar Un icono de favorito si la frase es favorita
                            if self.frasesModel.isFavFrase(frase) {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 5)
                            }
                            Text(frase)
                                .font(.system(size: 22))
                                .fontDesign(.serif)
                                .foregroundStyle(.black).bold()
                                .textSelection(.enabled)
                                .padding(.vertical, 15)
                            
                            Spacer()

                        }

                        #else
                        Text(frase)
                            .font(.system(size: 20))
                            .textSelection(.enabled)
                        //SelectableText(frase) //No funciona, no se ve el texto de la frase. Puede ser porque esta embebido en una List
                        #endif
                        
                    }
                    #if os(iOS) || os(ipadOS)
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
                                self.TextoFraseAEliminar = frase
                                self.showConfirmDialogDeleteFrase = true
                            }label:{
                                Image(systemName: "minus.circle.fill")
                                    .tint(.red.opacity(0.8))
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true){
                        //Editar la frase: Solo si es Personal
                        if let fraseCoreData = self.frasesModel.getFraseCoreData(fraseTexto: frase){
                            if fraseCoreData.noinbuilt == true{
                                NavigationLink{
                                    FrasesUpdateView(frase: fraseCoreData)
                                }label:{
                                    Image(systemName: "square.and.pencil")
                                        .tint(.green)
                                }
                            }
                        }
                        
                        
                        //Generando el QR de la frase
                        NavigationLink{
                            GenerateQRView(footer: frase)
                        }label: {
                            Image(systemName: "qrcode")
                                .tint(.brown)
                        }
                        
                        //Lienzo
                        NavigationLink{
                            LienzoMain(texto: frase)
                        }label: {
                            Image(systemName: "heart.text.square")
                                .tint(.brown)
                        }
                        
                        //Ajustar el estado de favorito de una frase
                        Button{
                            let current = self.frasesModel.isFavFrase(frase)
                            let newValue = !current
                            if self.frasesModel.setFavFrase(frase, newValue) {
                                Task {
                                    await self.frasesModel.FiltrarListado()
                                }
                                
                            }
                        }label: {
                            Image(systemName: "heart")
                                .tint( self.frasesModel.isFavFrase(frase) ? .orange : .gray)
                        }
                    }
                    #endif
                }
                .scrollContentBackground(.hidden)
                
                
                //Actualiza la información de la cantidad de elementos en la barra de estado inferior
                HStack{
                    switch frasesModel.buscarEn{
                    case .FrasesConNotas:
                        Text("Frases con notas: \(self.frasesModel.listfrases.count)")
                    case .TodasFrases:
                        Text("Todas las Frases: \(self.frasesModel.listfrases.count)")
                    case .FrasesPersonales:
                        Text("Frases Personales: \(self.frasesModel.listfrases.count)")
                    case .FrasesFavoritas:
                        Text("Frases Favoritas: \(self.frasesModel.listfrases.count)")
                    case .ResultadosDeBusquedaEnNotas:
                        Text("Resultado de Búsqueda en Notas: \(self.frasesModel.listfrases.count)")
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
                                Task {
                                    frasesModel.criterioFiltroActual = .ListadoFull
                                    frasesModel.buscarEn = .TodasFrases
                                    await frasesModel.FiltrarListado()
                                }
                                
                            }
                            
                            CreateMenuItemButton(text: "Frases Personales", sysImageStr: "text.magnifyingglass") {
                                Task {
                                    frasesModel.criterioFiltroActual = .FrasesPersonales
                                    frasesModel.buscarEn = .FrasesPersonales
                                   await frasesModel.FiltrarListado()
                                }
                            }
                           
                            CreateMenuItemButton(text: "Frases Favoritas", sysImageStr: "text.magnifyingglass") {
                                Task {
                                    frasesModel.criterioFiltroActual = .FrasesFavoritas
                                    frasesModel.buscarEn = .FrasesFavoritas
                                    await frasesModel.FiltrarListado()
                                }
                            }
                            
                            CreateMenuItemButton(text: "Frases con notas", sysImageStr: "text.magnifyingglass") {
                                Task {
                                    frasesModel.criterioFiltroActual = .FrasesConNotas
                                    frasesModel.buscarEn = .FrasesConNotas
                                  await  frasesModel.FiltrarListado()
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
                                       size: AppCons.windows_size_content_small,
                                       isModal: false) {
                                //Si el listado actual es frases personales se actualiza al cerrar la ventana:
                                    Task{ @MainActor in
                                        
                                            await self.frasesModel.FiltrarListado() //Actualizando...
                                    
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
            #if os(macOS)
            .background{
                LinearGradient(colors: [ .blue.opacity(0.6),.blue.opacity(0.7), .blue.opacity(0.5) ], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            #endif
            .sheet(isPresented: $showAddFrase){
                FraseAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
            }
            .alert("Buscar en nota de Frase", isPresented: $showAlertSearchInNotaFrase){
                TextField("", text: $textFieldNota)
                Button("Buscar"){
                    if !self.textFieldNota.isEmpty{
                        self.frasesModel.buscarEn = .ResultadosDeBusquedaEnNotas
                        Task{
                            self.frasesModel.criterioFiltroActual = .BuscarEnNotas
                            self.frasesModel.buscarEn = .ResultadosDeBusquedaEnNotas
                            await frasesModel.FiltrarListado(textAbuscar: self.textFieldNota)
                        }
                        
                       
                    }
                    
                }
                
            }
            //Dialogo de conformación para elimnar una nota
            .confirmationDialog(
                "Confirme que desea Eliminar la Frase",
                isPresented: $showConfirmDialogDeleteFrase
            ) {
                Button("Eliminar", role: .destructive) {
                    eliminarFrase()
                }
            } message: {
                Text("La nota será removida!!!")
            }
            
        }
    }
    
    
    private func eliminarFrase() {
        if let frase = self.TextoFraseAEliminar{
            withAnimation {
                if frasesModel.DeleteFraseInbuilt(frase: frase) {
                    Task {
                        frasesModel.criterioFiltroActual = .FrasesPersonales
                        await frasesModel.FiltrarListado()
                    }
                }
            }
        }
        
    }
    
}

#if os(macOS)
fileprivate struct RowFraseMenu: View {

    let frase: String
    @ObservedObject var frasesModel: FrasesModel
    @ObservedObject var settingModel: SettingModel
    
    @State private var showConfirmDialogDeleteFrase = false
    
    // Cache de valores precalculados
    private let coreData: Frases?
    private let isFav: Bool
    private let esNoInbuilt: Bool
    private let iaDisponible: Bool
    
    /// Inicialización para evitar trabajo en body
    init(frase: String,
         frasesModel: FrasesModel,
         settingModel: SettingModel)
    {
        self.frase = frase
        self.frasesModel = frasesModel
        self.settingModel = settingModel
        
        // Cache de valores
        self.coreData = frasesModel.getFraseCoreData(fraseTexto: frase)
        self.isFav = frasesModel.isFavFrase(frase)
        self.esNoInbuilt = frasesModel.isNoInbuilt(frase: frase)
        
        if #available(iOS 26.0, macOS 26.0, *) {
            self.iaDisponible = IAModelAppleIntelligence.isAvailable()
        } else {
            self.iaDisponible = false
        }
    }
    
    var body: some View {
        
        Menu(""){
            // Editar
            if esNoInbuilt {
                Button {
                    if let core = coreData {
                        showWindow(
                            for: FrasesUpdateView(frase: core),
                            environmentObjects: [frasesModel],
                            title: "Frases",
                            size: AppCons.windows_size_content_small,
                            isModal: true
                        )
                    }
                } label: {
                    Label("Editar Frase", systemImage: "square.and.pencil")
                        .tint(.green)
                }
            }
            
            // Notas
            Button {
                showWindow(
                    for: FrasesNotasAddView(frase: frase),
                    environmentObjects: [frasesModel],
                    title: "Frases",
                    size: AppCons.windows_size_content_small,
                    isModal: true
                )
            } label: {
                Label("Notas", systemImage: "bookmark")
                    .tint(.green)
            }
            
            // Favorito
            Button {
                let nuevoValor = !isFav
                if frasesModel.setFavFrase(frase, nuevoValor) {
                    Task { await frasesModel.FiltrarListado() }
                }
            } label: {
                Label("Favorito", systemImage: "heart.fill")
                    .tint(.gray)
            }
            
            // QR
            Button {
                showWindow(
                    for: GenerateQRView(footer: frase),
                    environmentObjects: [frasesModel],
                    title: "Frases",
                    size: AppCons.windows_size_content,
                    isModal: false
                )
            } label: {
                Label("Generar QR", systemImage: "qrcode")
                    .tint(.brown)
            }
            
            Button{
                showWindow(for: LienzoMain(texto: frase),
                           environmentObjects: [],
                           title: "Lienzo",
                           size: .absolute(CGSize(width: 650, height: 750)),
                           isModal: false
                )
                
            }label:{
                Label("Lienzo", systemImage: "heart.text.square")
            }
            
            
            
            // Inteligencia Artificial
            if #available(iOS 26.0, macOS 26.0, *){
                if iaDisponible {
                    
                    Button {
                        showWindow(
                            for: RespondView(
                                nameConference: "",
                                texto: frase,
                                tipoSalida: .interpretar
                            ),
                            environmentObjects: [frasesModel, settingModel],
                            title: "Interpretar",
                            size: AppCons.windows_size_content,
                            isModal: true,
                            isIAWindows: true
                        )
                    } label: {
                        Label("Interpretar", systemImage: "sparkles")
                    }
                    .tint(.purple)
                    
                    
                    Button {
                        showWindow(
                            for: RespondView(
                                nameConference: "",
                                texto: frase,
                                tipoSalida: .practicaConcreta
                            ),
                            environmentObjects: [frasesModel, settingModel],
                            title: "Aplicación Práctica",
                            size: AppCons.windows_size_content,
                            isModal: true,
                            isIAWindows: true
                        )
                    } label: {
                        Label("Aplicación Práctica", systemImage: "sparkles")
                    }
                    .tint(.purple)
                    
                    
                    Button {
                        showWindow(
                            for: ChatView(textoACargar: frase),
                            environmentObjects: [frasesModel, settingModel],
                            title: "Charlar con la IA",
                            size: AppCons.windows_size_content,
                            isModal: false,
                            isIAWindows: true
                        )
                    } label: {
                        Label("Charlar con la IA", systemImage: "sparkles")
                    }
                    .tint(.purple)
                }
            }
            
            
            
            // Eliminar
            if esNoInbuilt {
                Button(role: .destructive) {
                    showConfirmDialogDeleteFrase = true
                } label: {
                    Label("Eliminar", systemImage: "minus.circle.fill")
                        .tint(.red.opacity(0.8))
                }
            }
        }
        .frame(width: 15)
        .padding(.trailing, 5)
        .confirmationDialog(
            "Confirme que desea Eliminar la Frase",
            isPresented: $showConfirmDialogDeleteFrase
        ) {
            Button("Eliminar", role: .destructive) {
                eliminarFrase()
            }
        } message: {
            Text("La nota será removida!!!")
        }
        
        
       
        
    }
    
    
    // MARK: - Funciones internas (sin extensiones)
    private func eliminarFrase() {
        
            withAnimation {
                if frasesModel.DeleteFraseInbuilt(frase: frase) {
                    Task {
                        frasesModel.criterioFiltroActual = .FrasesPersonales
                        await frasesModel.FiltrarListado()
                    }
                }
            }
        
        
    }
    
}
#endif

//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Muesta y maneja el listado de frases en una ventana dedicada

import SwiftUI
import CoreData
import UniformTypeIdentifiers



struct FrasesListView: View {
    //"nev", "bruceL", "gregg", "jd", "salud"
    enum AutorFrase : String{
        case nev, jd, gregg, bruceL, salud
    }
    
    @Environment(\.colorScheme) private var theme
    @StateObject private var frasesModel: FrasesModel = FrasesModel.shared //El modelo ya viene con la precarga de todas las frases en su inicializador init(){}
    @EnvironmentObject private var settingModel: SettingModel
    @Environment(\.managedObjectContext) private var context
    
    var mostrarFrasesDe : AutorFrase? = nil //Permite filtrar la lista de frases por un autor determinado
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)     var fontSizeFrases      : Int = 24
    
    //Funciones premium
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
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
    @State private var TextoFraseAEliminar : Frases?
    
    
    //Alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var selectionMode = false
    @State private var selectedFraseIDs: Set<String> = []
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "Frases.pdf"
    
    //Mostrar la vista de frases relacionadas
    @State private var showTabViewFrasesRelac: Bool = false
    @State private var ModoListado: Bool = false
    @State private var fraseRelacionadaMain: Frases?
    
    
    
    @AppStorage(AppCons.UD_ProgresoUI_PopulandoFrases, store: UserDefaults(suiteName: "group.com.ypg.nev.group")) private var PopulandoFrases: Bool = false
    

    var body: some View {
        NavigationStack{
            ZStack{
                
                LinearGradient.FondoListado()
                    .ignoresSafeArea()
                
                VStack {
                    
                    //Si esta trabajando en popular las frases, entonces se muestra una barra de progreso
                    if self.PopulandoFrases {
                        
                        ProgressView()
                        
                    }else{
                        //Muestra un panel superior de Frases Relacionadas
                        if self.showTabViewFrasesRelac {
                            
                            if self.fraseRelacionadaMain != nil{
                                FraseRelacionadasTabView(frase: self.fraseRelacionadaMain!, showTabViewFrasesRelac: self.$showTabViewFrasesRelac, ModoListado: self.$ModoListado)
                            }
                            
                         }

                        //Si el modo Listado de frases Relacionadas esta activo:
                        if self.ModoListado {
                            
                            if self.fraseRelacionadaMain != nil {
                                ScrollView{
                                    
                                    FrasesRelacionasListView(fraseMain: self.fraseRelacionadaMain!)
                                }
                                
                            }
                            
                            
                        }else{
                            
                            //Búsqueda:
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.black)
                                
                                TextField("Buscar", text: self.$textFieldFrase)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.primary)
                                    .padding(8)
                                    .focused(self.$focused)
                                    .onSubmit {
                                        Task{
                                            frasesModel.criterioFiltroActual = .Buscar
                                            await frasesModel.FiltrarListado(textAbuscar: self.textFieldFrase)
                                            //Ajustando los valores de resultado de acuerdo a el estado premium:
                                            if !(self.purchaseStatus || self.yorjPremium){
                                                self.frasesModel.listfrases = self.frasesModel.listfrases.filter{
                                                    $0.autor == "nev"
                                                }
                                            }
                                        }
                                        
                                    }
                            }
                            .padding(.horizontal)
                            #if os(macOS)
                            .background(.windowBackground)
                            #endif
                            
                            //Listado de Frases:
                            List(frasesModel.listfrases, id: \.id){ frase in
                                HStack(alignment: .top, spacing: 8) {
                                    if selectionMode {
                                        Image(systemName: selectedFraseIDs.contains(frase.id ?? "") ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(.black)
                                            .padding(.top, 6)
                                    }
                                    FraseRowView(frase: frase, showTabViewFrasesRelac : self.$showTabViewFrasesRelac, fraseRelacionadaMain: self.$fraseRelacionadaMain )
                                        .foregroundStyle(.black).bold()
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    guard selectionMode else { return }
                                    toggleFraseSelection(frase)
                                }
                                .listRowBackground(Color.clear)
                            }
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            
                            //Actualiza la información de la cantidad de elementos en la barra de estado inferior
                            HStack{
                                Text("Frases: \(self.frasesModel.listfrases.count)")
                                    .foregroundStyle(.black)
                                Spacer()
                            }.padding(.horizontal)
                            
                            .navigationTitle("Listado de Frases")
                            #if os(iOS)
                            .navigationBarTitleDisplayMode(.inline)
                            #endif
                             .toolbar{
                                 
                                 if #available(iOS 26.0, macOS 26.0,  *) {
                                     ToolbarSpacer(.fixed)
                                 }
                                 
                                 //Aplica varios filtros al listado de Frases
                                 ToolbarItem {
                                     Menu{
                                         
                                         CreateMenuItemButton(text: "Todas las Frases", sysImageStr: "text.magnifyingglass") {
                                             Task {
                                                 frasesModel.criterioFiltroActual = .ListadoFull //Almacena información acerca del tipo de filtro
                                                 frasesModel.buscarEn = .TodasFrases
                                                 
                                                 if (self.purchaseStatus || self.yorjPremium){
                                                     self.frasesModel.getAllFrases()
                                                 }else{
                                                     self.frasesModel.listfrases = self.frasesModel.getAllFrasesGet().filter{
                                                         $0.autor == "nev"
                                                     }
                                                 }
                                                 
                                             }
                                             
                                         }
                                         
                                         
                                         
                                         CreateMenuItemButton(text: "Frases Personales", sysImageStr: "text.magnifyingglass") {
                                             Task {
                                                 frasesModel.criterioFiltroActual = .FrasesPersonales
                                                 frasesModel.buscarEn = .FrasesPersonales
                                                 
                                                 self.frasesModel.listfrases = self.frasesModel.getFrasesNoInbuilt()
                                             }
                                         }
                                        
                                         CreateMenuItemButton(text: "Frases Favoritas", sysImageStr: "text.magnifyingglass") {
                                             Task {
                                                 frasesModel.criterioFiltroActual = .FrasesFavoritas
                                                 frasesModel.buscarEn = .FrasesFavoritas
                                                 
                                                 if (self.purchaseStatus || self.yorjPremium){
                                                     self.frasesModel.listfrases = self.frasesModel.getAllFavFrases()
                                                 }else{
                                                     self.frasesModel.listfrases = self.frasesModel.getAllFavFrases().filter{
                                                         $0.autor == "nev"
                                                     }
                                                 }
                                             }
                                         }
                                         
                                         CreateMenuItemButton(text: "Frases con notas", sysImageStr: "text.magnifyingglass") {
                                             Task {
                                                 frasesModel.criterioFiltroActual = .FrasesConNotas
                                                 frasesModel.buscarEn = .FrasesConNotas
                                                 
                                                 if (self.purchaseStatus || self.yorjPremium){
                                                     self.frasesModel.listfrases = self.frasesModel.getFrasesConNotas()
                                                 }else{
                                                     self.frasesModel.listfrases = self.frasesModel.getFrasesConNotas().filter{
                                                         $0.autor == "nev"
                                                     }
                                                 }
                                             }
                                         }

                                         CreateMenuItemButton(text: "Buscar en nota de frase", sysImageStr: "text.magnifyingglass") {
                                             subtitle = "Búsqueda en nota de Frase"
                                             showAlertSearchInNotaFrase = true
                                         }

                                         CreateMenuItemButton(text: "Exportar PDF (manual)", sysImageStr: "doc.richtext") {
                                             exportSelectedFrasesToPDFOrEnableSelection()
                                         }
                                         
                                         //Crea un Menú para filtrar por todos los Autores Disponibles
                                         Menu{
                                             let autores = self.frasesModel.getAllAutoresList()
                                             ForEach(autores.sorted(by: { $0.key < $1.key }), id: \.key) { autorRaw, autorNombre in
                                                 Button(autorNombre){
                                                     if (self.purchaseStatus || self.yorjPremium){
                                                         self.frasesModel.listfrases = self.frasesModel.getListFrasesByAutor(autor: autorRaw)
                                                     }else{
                                                         if (autorRaw == "nev"){
                                                             self.frasesModel.listfrases = self.frasesModel.getListFrasesByAutor(autor: autorRaw)
                                                         }else{
                                                             self.alertMessage = " Las Frases de \(autorNombre) están presentes en la Versión Extendida"
                                                             self.showAlert = true
                                                         }
                                                     }
                                                     
                                                     
                                                 }
                                             }
                                             
                                         }label: {
                                             Label("Por Autor", systemImage: "text.quote")
                                         }
                                         
                                         //Crea un Menu para filtrar por contextos disponibles:
                                         Menu{
                                             let autores = self.frasesModel.getAllContextosList()
                                             ForEach(autores, id: \.self) { contexto in
                                                 Button(contexto){
                                                     if (self.purchaseStatus || self.yorjPremium){
                                                         self.frasesModel.listfrases = self.frasesModel.getFrasesByContexto(contexto: contexto)
                                                     }else{
                                                         self.frasesModel.listfrases = self.frasesModel.getFrasesByContexto(contexto: contexto).filter{
                                                             $0.autor == "nev"
                                                         }
                                                     }
                                                    
                                                 }
                                             }
                                             
                                         }label: {
                                             Label("Por Contexto", systemImage: "text.quote")
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
                                     Button(selectionMode ? "Cancelar" : "Seleccionar") {
                                         withAnimation {
                                             selectionMode.toggle()
                                             if !selectionMode {
                                                 selectedFraseIDs.removeAll()
                                             }
                                         }
                                     }
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
                         Task{
                             self.frasesModel.criterioFiltroActual = .BuscarEnNotas
                             
                             if (self.purchaseStatus || self.yorjPremium){
                                 self.frasesModel.listfrases = self.frasesModel.searchTextInNotaFrases(textNota: self.textFieldNota)
                             }else{
                                 self.frasesModel.listfrases = self.frasesModel.searchTextInNotaFrases(textNota: self.textFieldNota).filter{
                                     $0.autor == "nev"
                                 }
                             }
                         }
                     }
                     
                 }
                 
             }
             .alert(isPresented: self.$showAlert){
                 Alert(title: Text("La Ley"), message: Text(self.alertMessage))
             }
             .fileExporter(
                isPresented: $showPDFExporter,
                document: exportedPDFDocument,
                contentType: .pdf,
                defaultFilename: exportedPDFFileName
             ) { _ in }
             .task {
                 //Carga todas las Frases al inicio:
                 if self.mostrarFrasesDe != nil{
                     self.frasesModel.listfrases = self.frasesModel.getListFrasesByAutor(autor: self.mostrarFrasesDe!.rawValue)
                 }else{
                     //Al iniciarse, la ventana se carga todas las frases (Versión Extebndida) o solo las de neville
                     if (self.purchaseStatus || self.yorjPremium){
                         self.frasesModel.getAllFrases()
                     }else{
                         self.frasesModel.listfrases = self.frasesModel.getListFrasesByAutor(autor: AutorFrase.nev.rawValue)
                     }
                     
                 }
                 
             }
             
            
            
        }
    }

    private func toggleFraseSelection(_ frase: Frases) {
        guard let id = frase.id else { return }
        if selectedFraseIDs.contains(id) {
            selectedFraseIDs.remove(id)
        } else {
            selectedFraseIDs.insert(id)
        }
    }

    private func exportSelectedFrasesToPDFOrEnableSelection() {
        guard purchaseStatus || yorjPremium else {
            alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
            showAlert = true
            return
        }
        if !selectionMode {
            withAnimation {
                selectionMode = true
            }
            alertMessage = "Selecciona las frases y vuelve a pulsar 'Exportar PDF (manual)'."
            showAlert = true
            return
        }

        let selected = frasesModel.listfrases.filter { frase in
            guard let id = frase.id else { return false }
            return selectedFraseIDs.contains(id)
        }

        guard !selected.isEmpty else {
            alertMessage = "No hay frases seleccionadas para exportar."
            showAlert = true
            return
        }

        let lines: [PDFExportLine] = selected.map { frase in
            let content = (frase.frase ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let author = (frase.autor ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return PDFExportLine(
                title: content.isEmpty ? "Sin contenido" : content,
                detail: author.isEmpty ? "Autor desconocido" : author
            )
        }
        let section = PDFExportSection(title: "Frases seleccionadas", lines: lines)
        let descriptor = PDFExportDocumentDescriptor(
            title: "Frases - Exportación Manual",
            subtitle: "Generado el \(Date().formatted(date: .abbreviated, time: .shortened))",
            sections: [section]
        )

        do {
            let data = try PDFExportModule.render(descriptor)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "Frases-Manual-\(dateLabel)"
            showPDFExporter = true
        } catch {
            alertMessage = "No se pudo generar el PDF."
            showAlert = true
        }
    }
    
    
}





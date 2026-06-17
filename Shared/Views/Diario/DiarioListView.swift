//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct DiarioListView: View {

    @Environment(\.dismiss) var dimiss
    @Environment(\.managedObjectContext) var context

    @StateObject private var modelDiario = DiarioModel.shared
    @StateObject private var securityModel : SecurityModel = SecurityModel.shared
    
    
    //Para filtros en fechas
    enum TypeOfSearch{case fix, interval}
    
    //Para Buscar en títulos
    @State private var showAlertFilterByTitles = false
    @State private var textfielTitles = ""
    //Para Buscar en contenido
    @State private var showAlertFilterByContent = false
    //Para buscar en fechas:
    @State private var showSheetFecha       = false
    @State private var showSheetRangoFecha  = false
    @State private var typeOfFechaSearch : TypeFecha = .FechaCreacion
    @State private var fecha1 = Date.now
    @State private var fecha2 = Date.now
    
    @State private var datepicker : Date = Date.now
    @State private var textfielContent = ""
    

    
    let titlesExamples : [(String,String)] = [
    ("Revisión de este día", "neutral"),
    ("¿Como me he sentido hoy?", "neutral" ),
    ("Hoy agradezco:", "feliz"),
    ("¿Que debo mejorar?", "desanimado"),
    ("¿Que he aprendido hoy?","neutral"),
    ("Mi vida es maravillosa porque...", "feliz"),
    ("!Hoy se ha materializado un deseo!","feliz"),
    ("!No es maravillo si...!","feliz"),
    ("Hoy nace un deseo!","feliz"),
    ("!Lo he logrado!","feliz")]
    

    //@State var canOpenDiario : Bool = false
    @State var claveAcceso : String? = nil //Clave para acceder al Diario en dispisitivos son biometría
    
    //Alert:
    @State var showAlert = false
    @State var alertMessage = ""
    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    
    
    @State private var showCalendar: Bool = false   //Mostrar/Ocultar el calendario. Por defecto aparece oculto
    @State private var showDiarioStats: Bool = false
    @State private var selectedCalendarDate: Date? = nil
    @State private var calendarRefreshTrigger: Int = 0
    @State private var showNewEntryEditor: Bool = false
    @State private var newEntryTitle: String = ""
    @State private var newEntryContent: String = ""
    @State private var newEntryEmotion: Emociones = .neutral
    @State private var newEntryDate: Date = Date.now
    @State private var showPDFExporter = false
    @State private var exportedPDFDocument: ExportedPDFDocument?
    @State private var exportedPDFFileName: String = "Diario.pdf"
    @State private var showExportRangeSheet = false
    @State private var showManualExportSheet = false
    @State private var exportFromDate = Date.now
    @State private var exportToDate = Date.now
    @State private var manuallySelectedDiarioIDs: Set<UUID> = []
    @State private var isBatchSelectionMode = false
    @State private var batchSelectedDiarioIDs: Set<UUID> = []
    @State private var showBatchDeleteConfirmation = false
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    
    
    //Ordenar las entradas del Diario por fechaCreación/fechaModificación
    @AppStorage(AppCons.UD_setting_OrdenarEntradaDiario) var ordenarEntradaDiario : Bool = true // true es fechaCreación; false es fecha de modificación
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false //Para poder manejar el acceso al diario
 
    //Almacena la contraeña de acceso en el Llavero, si existe:
    @State private var hasPassword = false

    private var hasPremiumPDFAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient(colors: [Color(red:0.45, green:0.50, blue: 0.50), .orange], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                    .onAppear{
                        //Lee la contraseña de acceso del diario
                        hasPassword = KeychainHelper.shared.getPassword() != nil
                    }
                
                
                if self.securityModel.canOpenDiario{
                    VStack{
                        Text("") //Para que las entradas no sobrepasen el area segura superior
                        
                        //Calendario:
                        if self.showCalendar {
                            VStack{
                                    DiarioCalendarView(
                                        refreshTrigger: calendarRefreshTrigger,
                                        onMonthEntriesLoaded: { _ in
                                            selectedCalendarDate = nil
                                        },
                                        onRequestCreateEntry: { date in
                                            openNewEntryEditor(
                                                title: "",
                                                content: "",
                                                emocion: .neutral,
                                                date: date
                                            )
                                        }
                                    ) { date in
                                        withAnimation {
                                            selectedCalendarDate = Calendar.current.startOfDay(for: date)
                                            modelDiario.list = modelDiario.searchPorFecha(for: date)
                                        }
                                    }
                            }
                            .background(Color.black.opacity(0.05))
                        }

                        if isBatchSelectionMode {
                            batchSelectionToolbar
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                            ScrollView(){
                                if self.securityModel.canOpenDiario {
                                        LazyVStack{
                                            ForEach(modelDiario.list) { item in
                                                diarioCard(for: item)
                                            }
                                        }
                                    }
                                }
                            .scrollIndicators(.hidden)
                    }
                    .onAppear{
                        selectedCalendarDate = nil
                        self.modelDiario.getAllItem()
                    }
                    .onChange(of: modelDiario.list.map { $0.id }) { _, ids in
                        let visibleIDs = Set(ids.compactMap { $0 })
                        batchSelectedDiarioIDs = batchSelectedDiarioIDs.intersection(visibleIDs)
                    }
                    
                }else{ //Ventana de Autenticación
                    
                    VStack{
                        Text("El Diario le permite llevar un registro de las actividades y hechos del día. Está protegido y solo usted tiene acceso.")
                            .multilineTextAlignment(.center)
                            .italic()
                            .fontWeight(.heavy)
                            .fontDesign(.serif)
                            .font(.system(size: 25))
                            .foregroundStyle(.black)
                            .padding(15)
                            
                        
                        if BiometryCheckerSupport.checkBiometricSupport() == .available{ //Hay soporte para biometría
                            Button{
                                UtilFuncs.autent(HabilitarContenido: self.$securityModel.canOpenDiario)
                                
                            }label:{
                                Image(systemName: "key.viewfinder")
                                    .font(.system(size: 60))
                                    .foregroundStyle(Color.black.opacity(0.7))
                                    .symbolEffect(.pulse, isActive: true)
                            }
                            Text("Toque la imagen para acceder.").font(.footnote).padding()
                            #if os(macOS)
                            Button("Acceder por contraseña"){
                                showWindow(for: LogginView(ente: .Diario),
                                           environmentObjects: [self.securityModel],
                                           title: "Acceder Por contraseña",
                                           size: AppCons.windows_size_content_small,
                                           isModal: true
                                
                                )
                             
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .padding(.vertical, 25)
                            
                            #else
                            NavigationLink("Acceder por contraseña"){
                                    LogginView(ente: .Diario)
                                        .environmentObject(self.securityModel)
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .padding(.vertical, 25)
                            #endif
                            
                            
                        }else{
                            //NO hay soporte para Biometria
                            VStack{
                                //Chequeamos si hay una clave guardada:
                                if self.hasPassword{ //Hay una clave
                                    Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para entrar por contraseña.")
                                    
                                    #if os(macOS)
                                    Button("Acceder por contraseña"){
                                        showWindow(for: LogginView(ente: .Diario),
                                                   environmentObjects: [self.securityModel],
                                                   title: "Acceder Por contraseña",
                                                   size: AppCons.windows_size_content_small,
                                                   isModal: true)
                                       
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black)
                                    .padding()
                                    
                                    #else
                                    
                                    NavigationLink("Acceder por contraseña"){
                                        LogginView(ente: .Diario)
                                       
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black)
                                    .padding()
                                    
                                    #endif
                                    
                                    
                                    
                                    Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                                        .font(.footnote)
                                    
                                }else{ //No hay una clave almacenada
                                    Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para crear una contraseña para acceder al Diario.")
                                    //No existe una clave guardada. Permitir crear una la primera vez
                                    NavigationLink("Crear una Contraseña"){
                                        CreatePasswordView()
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.black)
                                    .padding()
                                    
                                    Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                                        .font(.footnote)
                                }
     
                            }.padding()
                        }
                    }
                }
            }
            .onDisappear{
                //Al cerrar la ventana del Diario se chequea si la opción de mentener la ventana abierta.
                //De estar activada, se mantiene la variable canOpenDiario activa
                //De lo contrario, la variable canOpenDiario se pone a false, bloqueando el diario.
                if (self.setting_DiarioSiempreOpenFaceID == true){
                    self.securityModel.canOpenDiario = true
                   
                }else{
                    self.securityModel.canOpenDiario = false
                }
            }
            .toolbar{
                
                //Permite embeber en Details la ventana actualmente activa
                #if os(macOS)
                ToolbarItem {
                    Button{
                       
                    }label:{
                      Image(systemName: "gear")
                    }
                }
                
                #endif
                
                
                if self.securityModel.canOpenDiario {
                    ToolbarItem {
                        Button {
                            self.showDiarioStats = true
                        } label: {
                            Label("Estadísticas", systemImage: "chart.xyaxis.line")
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }

                    ToolbarItem {
                        Button {
                            toggleBatchSelectionMode()
                        } label: {
                            Label(isBatchSelectionMode ? "Cancelar selección" : "Seleccionar", systemImage: isBatchSelectionMode ? "xmark.circle" : "checklist")
                        }
                    }

                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem {
                        Button{
                            withAnimation {
                                self.showCalendar.toggle()
                                //Si oculta el calendario se muestra todos los items
                                if self.showCalendar == false {
                                    selectedCalendarDate = nil
                                    modelDiario.getAllItem()
                                }
                            }
                            
                        }label:{
                            Label( self.showCalendar ? "Ocultar Calendario" : "Mostrar calendario", systemImage: "calendar")
                        }
                    }
                    
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem{
                        
                        Menu{
                            
                            //Ordenar por fecha de creación/modificación
                            Button{
                                self.ordenarEntradaDiario.toggle()
                                selectedCalendarDate = nil
                                modelDiario.getAllItem()
                            }label:{
                                Label("Ordenar Por fecha de \(self.ordenarEntradaDiario ? "Modificación" : "Creación")", systemImage: "text.magnifyingglass")
                            }
                            
                            //Mostrar todas las entradas
                            Button{
                                withAnimation {
                                    selectedCalendarDate = nil
                                    modelDiario.getAllItem()
                                }
                                
                            }label:{
                                Label("Todas las entradas", systemImage: "text.magnifyingglass")
                            }
                            
                            //Mostrar las favoritas
                            Button{
                                modelDiario.list =  modelDiario.filterByFav()
                            } label:{
                                Label("Mostrar favoritas", systemImage: "text.magnifyingglass")
                            }
                            
                            
                            
                            Menu{
                                ForEach(Emociones.allCases, id: \.self) { emocion in
                                    Button {
                                        withAnimation {
                                            modelDiario.list = modelDiario.filterByEmoticono(criterio: emocion.rawValue)
                                        }
                                    } label: {
                                        HStack {
                                            Text(emocion.rawValue.capitalized)
                                            Text(emocion.emoji)
                                        }
                                    }
                                }
                            }label: {
                                Label("Por emoción", systemImage: "face.smiling")
                            }
                            
                            //Buscar en los títulos
                            Button{
                                showAlertFilterByTitles = true
                            }label:{
                                Label("Buscar en Títulos", systemImage: "text.magnifyingglass")
                            }
                            
                            //Buscar en el contenido
                            Button{
                                showAlertFilterByContent = true
                            }label:{
                                Label("Buscar en el Contenido", systemImage: "text.magnifyingglass")
                            }
                            
                            
                            //Filtrar por tipos de fechas: Creación y modificación
                            Menu{
                                Button("Fecha"){
                                    self.typeOfFechaSearch = .FechaCreacion
                                    self.showSheetFecha = true
                                }
                                Button("Intervalo"){
                                    self.typeOfFechaSearch = .FechaCreacion
                                    self.showSheetRangoFecha = true
                                }
                                Menu{
                                    Button("Tres días"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .tresDias, typeFecha: .FechaCreacion)
                                    }
                                    Button("Semana anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .semana, typeFecha: .FechaCreacion)
                                    }
                                    Button("Quincena anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .quincena, typeFecha: .FechaCreacion)
                                    }
                                    Button("Mes anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .mes, typeFecha: .FechaCreacion)
                                    }
                                    Button("Dos meses"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .dosMeses, typeFecha: .FechaCreacion)
                                    }
                                    Button("Seis meses"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .seisMeses, typeFecha: .FechaCreacion)
                                    }
                                    Button("Un año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .unAno, typeFecha: .FechaCreacion)
                                    }
                                    Button("Dos año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .dosAnos, typeFecha: .FechaCreacion)
                                    }
                                    Button("Tres año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .tresAnos, typeFecha: .FechaCreacion)
                                    }
                                    Button("Cinco año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .cincoAnos, typeFecha: .FechaCreacion)
                                    }
                                    Button("Diez año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .diezAnos, typeFecha: .FechaCreacion)
                                    }
                                }label:{
                                    Text("Sugerencias")
                                }
                                
                                
                            }label:{
                                Label("Fecha de Creación", systemImage: "text.magnifyingglass")
                                
                            }
                            Menu{
                                Button("Fecha"){
                                    self.typeOfFechaSearch = .FechaModificacion
                                    self.showSheetFecha = true
                                }
                                Button("Intervalo"){
                                    self.typeOfFechaSearch = .FechaModificacion
                                    self.showSheetRangoFecha = true
                                }
                                Menu{
                                    Button("Tres días"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .tresDias, typeFecha: .FechaModificacion)
                                    }
                                    Button("Semana anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .semana, typeFecha: .FechaModificacion)
                                    }
                                    Button("Quincena anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .quincena, typeFecha: .FechaModificacion)
                                    }
                                    Button("Mes anterior"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .mes, typeFecha: .FechaModificacion)
                                    }
                                    Button("Dos meses"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .dosMeses, typeFecha: .FechaModificacion)
                                    }
                                    Button("Seis meses"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .seisMeses, typeFecha: .FechaModificacion)
                                    }
                                    Button("Un año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .unAno, typeFecha: .FechaModificacion)
                                    }
                                    Button("Dos año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .dosAnos, typeFecha: .FechaModificacion)
                                    }
                                    Button("Tres año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .tresAnos, typeFecha: .FechaModificacion)
                                    }
                                    Button("Cinco año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .cincoAnos, typeFecha: .FechaModificacion)
                                    }
                                    Button("Diez año"){
                                        modelDiario.list = modelDiario.searchPorAntiguedad(for: .diezAnos, typeFecha: .FechaModificacion)
                                    }
                                }label:{
                                    Text("Sugerencias")
                                }
                                
                                
                            }label:{
                                Label("Fecha de Modificación", systemImage: "text.magnifyingglass")
                            }

                            exportDiarioPDFMenu()
                        }label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .tint(.black)
                            
                        }
                        
                    }
                    
                    //Establecer una separación entre los items de los menus
                    if #available(iOS 26.0, macOS 26.0, *) {
                        ToolbarSpacer(.fixed)
                    }
                    
                    ToolbarItem{
                            Menu{
                                Button {
                                    openNewEntryEditor(
                                        title: "",
                                        content: "",
                                        emocion: .neutral,
                                        date: Date.now
                                    )
                                } label: {
                                    Label("Nueva Entrada", systemImage: "square.and.pencil")
                                }
                                
                                Menu{
                                    ForEach(0..<titlesExamples.count, id: \.self){ value in
                                        Button(titlesExamples[value].0) {
                                            openNewEntryEditor(
                                                title: titlesExamples[value].0,
                                                content: "",
                                                emocion: modelDiario.getEmocionesFromStr(value: titlesExamples[value].1),
                                                date: Date.now
                                            )
                                        }
                                    }
                                }label: {
                                    Label("Sugerencias", systemImage: "wand.and.rays")
                                }
                                
                            }label:{
                                Image(systemName: "plus")//"wand.and.rays")
                                    .tint(.black)
                            }
                    }
                }
                    
                
            }
            .navigationTitle("Diario")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("Filtrar por Título", isPresented: $showAlertFilterByTitles) {
                TextField("", text: $textfielTitles)
                Button("Cancelar"){
                    textfielTitles = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        modelDiario.list = modelDiario.filterByTitle(criterio: textfielTitles)
                    }
                    textfielTitles = ""
                }
                
            }
            .alert("Filtrar por Contenido", isPresented: $showAlertFilterByContent) {
                TextField("", text: $textfielContent)
                Button("Cancelar"){
                    textfielContent = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        modelDiario.list = modelDiario.filterByContent(criterio: textfielContent)
                    }
                    
                    textfielContent = ""
                }
            }
            .sheet(isPresented: $showSheetFecha){
                VStack{
                    DatePicker("Fecha de creación", selection: $fecha1, displayedComponents: [.date])
                        .padding(.top, 50)
                    Button{
                        Task{
                            modelDiario.list = modelDiario.searchPorFecha(for: self.fecha1, typeFecha: self.typeOfFechaSearch)
                        }
                    }label: {
                        Text("Buscar")
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding([.vertical, .horizontal])
                    .buttonStyle(PlainButtonStyle())
                    
                }
                
                .ignoresSafeArea()
                
            }
            .sheet(isPresented: $showSheetRangoFecha){
                ScrollView{
                    DatePicker("Fecha Inicio", selection: $fecha1, displayedComponents: [.date])
                        .frame(height: 70)
                        .padding(.top, 30)
                    
                    DatePicker("Fecha final", selection: $fecha2, displayedComponents: [.date])
                        .frame(height: 70)
                    
                    Button{
                        Task{
                            modelDiario.list = modelDiario.searchPorRangoFecha(from: self.fecha1, to: self.fecha2, typeFecha: self.typeOfFechaSearch)
                        }
                    }label: {
                        Text("Buscar")
                            .padding(.vertical, 10)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .background(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding([.vertical, .horizontal])
                    .buttonStyle(PlainButtonStyle())
                    
                }
                .ignoresSafeArea()
                
            }
            .sheet(isPresented: $showNewEntryEditor) {
                NewDiarioEntryView(
                    title: newEntryTitle,
                    content: newEntryContent,
                    emocion: newEntryEmotion,
                    fechaCreacion: newEntryDate
                ) { savedDate in
                    refreshAfterEntryCreation(savedDate)
                }
            }
            .sheet(isPresented: self.$sheetShowFeedBackReview, content: {
                FeedbackView(showTextBotton: true)
            })
            .sheet(isPresented: $showDiarioStats) {
                DiarioStatsView()
            }
            .sheet(isPresented: $showExportRangeSheet) {
                VStack(spacing: 16) {
                    DatePicker("Desde", selection: $exportFromDate, displayedComponents: [.date])
                    DatePicker("Hasta", selection: $exportToDate, displayedComponents: [.date])
                    Button("Exportar PDF") {
                        exportDiarioRangeToPDF(from: exportFromDate, to: exportToDate)
                        showExportRangeSheet = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .sheet(isPresented: $showManualExportSheet) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selecciona entradas para exportar")
                        .font(.headline)
                    List {
                        ForEach(modelDiario.list) { item in
                            Button {
                                toggleManualDiarioSelection(item)
                            } label: {
                                HStack {
                                    Image(systemName: manuallySelectedDiarioIDs.contains(item.id ?? UUID()) ? "checkmark.circle.fill" : "circle")
                                    Text(item.title ?? "Sin título")
                                    Spacer()
                                    if let date = item.fecha {
                                        Text(date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button("Exportar PDF") {
                        let selected = modelDiario.list.filter { item in
                            guard let id = item.id else { return false }
                            return manuallySelectedDiarioIDs.contains(id)
                        }
                        exportDiarioToPDF(selected, scopeName: "Manual")
                        showManualExportSheet = false
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .fileExporter(
                isPresented: $showPDFExporter,
                document: exportedPDFDocument,
                contentType: .pdf,
                defaultFilename: exportedPDFFileName
            ) { _ in }
            .alert("Diario", isPresented: $showAlert) {
                
            } message: {
                Text(self.alertMessage)
            }
            .alert("¿Desea eliminar las entradas seleccionadas?", isPresented: $showBatchDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {}
                Button("Eliminar", role: .destructive) {
                    deleteSelectedEntries()
                }
            } message: {
                Text("Esta acción no puede deshacerse.")
            }
  
         }
    }

    private var batchSelectionToolbar: some View {
        HStack(spacing: 12) {
            Text("\(batchSelectedDiarioIDs.count) seleccionadas")
                .font(.subheadline.bold())
                .foregroundStyle(.black)

            Spacer()

            Button {
                toggleVisibleEntriesSelection()
            } label: {
                Label(areAllVisibleEntriesSelected ? "Ninguna" : "Todas", systemImage: areAllVisibleEntriesSelected ? "minus.circle" : "checkmark.circle")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .tint(.black)
            .help(areAllVisibleEntriesSelected ? "Deseleccionar visibles" : "Seleccionar visibles")

            Menu {
                ForEach(Emociones.allCases, id: \.self) { emocion in
                    Button {
                        updateSelectedEntriesEmotion(emocion)
                    } label: {
                        HStack {
                            Text(emocion.rawValue.capitalized)
                            Text(emocion.emoji)
                        }
                    }
                }
            } label: {
                Label("Cambiar emoción", systemImage: "face.smiling")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .tint(.black)
            .disabled(batchSelectedDiarioIDs.isEmpty)
            .help("Cambiar emoción")

            Button(role: .destructive) {
                showBatchDeleteConfirmation = true
            } label: {
                Label("Borrar", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(batchSelectedDiarioIDs.isEmpty)
            .help("Borrar seleccionadas")
        }
        .padding(10)
        .background(.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 3)
    }

    @ViewBuilder
    private func diarioCard(for item: Diario) -> some View {
        let isSelected = isDiarioSelected(item)

        cardItemDiario(
            diario: item,
            onEntryDeleted: { deletedDate in
                withAnimation {
                    refreshAfterEntryDeletion(deletedDate)
                }
            },
            onEntryUpdated: { updatedDate in
                withAnimation {
                    refreshAfterEntryUpdate(updatedDate)
                }
            },
            isSelectionMode: isBatchSelectionMode,
            isSelected: isSelected,
            onSelectionToggle: {
                toggleBatchSelection(item)
            }
        )
        .padding(15)
        .frame(maxWidth: .infinity)
        .foregroundStyle(Color.black)
        .background(.white.opacity(0.7))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
    }

    private var visibleDiarioIDs: Set<UUID> {
        Set(modelDiario.list.compactMap { $0.id })
    }

    private var areAllVisibleEntriesSelected: Bool {
        let ids = visibleDiarioIDs
        return !ids.isEmpty && ids.isSubset(of: batchSelectedDiarioIDs)
    }

    private func toggleBatchSelectionMode() {
        withAnimation {
            isBatchSelectionMode.toggle()
            if !isBatchSelectionMode {
                batchSelectedDiarioIDs.removeAll()
            }
        }
    }

    private func isDiarioSelected(_ item: Diario) -> Bool {
        guard let id = item.id else { return false }
        return batchSelectedDiarioIDs.contains(id)
    }

    private func toggleBatchSelection(_ item: Diario) {
        guard let id = item.id else { return }
        if batchSelectedDiarioIDs.contains(id) {
            batchSelectedDiarioIDs.remove(id)
        } else {
            batchSelectedDiarioIDs.insert(id)
        }
    }

    private func toggleVisibleEntriesSelection() {
        let ids = visibleDiarioIDs
        if areAllVisibleEntriesSelected {
            batchSelectedDiarioIDs.subtract(ids)
        } else {
            batchSelectedDiarioIDs.formUnion(ids)
        }
    }

    private func deleteSelectedEntries() {
        let idsToDelete = batchSelectedDiarioIDs
        guard !idsToDelete.isEmpty else { return }

        withAnimation {
            modelDiario.DeleteItems(ids: idsToDelete)
            finishBatchOperation()
            refreshAfterEntryDeletion(nil)
        }
    }

    private func updateSelectedEntriesEmotion(_ emotion: Emociones) {
        let idsToUpdate = batchSelectedDiarioIDs
        guard !idsToUpdate.isEmpty else { return }

        withAnimation {
            modelDiario.UpdateEmoticono(emoticono: emotion, ids: idsToUpdate)
            finishBatchOperation()
            refreshAfterEntryUpdate(nil)
        }
    }

    private func finishBatchOperation() {
        batchSelectedDiarioIDs.removeAll()
        isBatchSelectionMode = false
        calendarRefreshTrigger += 1
    }

    private func openNewEntryEditor(title: String, content: String, emocion: Emociones, date: Date) {
        newEntryTitle = title
        newEntryContent = content
        newEntryEmotion = emocion
        newEntryDate = Calendar.current.startOfDay(for: date)

#if os(macOS)
        showWindow(
            for: NewDiarioEntryView(
                title: newEntryTitle,
                content: newEntryContent,
                emocion: newEntryEmotion,
                fechaCreacion: newEntryDate
            ) { savedDate in
                refreshAfterEntryCreation(savedDate)
            },
            environmentObjects: [self.modelDiario],
            title: "Nueva Entrada",
            size: AppCons.windows_size_content,
            isModal: true
        )
#else
        showNewEntryEditor = true
#endif
    }

    private func refreshAfterEntryCreation(_ savedDate: Date) {
        calendarRefreshTrigger += 1
        selectedCalendarDate = Calendar.current.startOfDay(for: savedDate)
        modelDiario.list = modelDiario.searchPorFecha(for: savedDate)

        if FeedBackModel.checkReviewRequest() {
            #if os(macOS)
            showWindow(
                for: FeedbackView(showTextBotton: false),
                environmentObjects: [],
                title: "Enviar una Reseña a la App Store",
                size: AppCons.windows_size_content_small,
                isModal: true
            )
            #else
            sheetShowFeedBackReview = true
            #endif
        }
    }

    private func refreshAfterEntryDeletion(_ : Date?) {
        calendarRefreshTrigger += 1

        if let selectedCalendarDate {
            modelDiario.list = modelDiario.searchPorFecha(for: selectedCalendarDate)
            return
        }

        modelDiario.getAllItem()
    }

    private func refreshAfterEntryUpdate(_ : Date?) {
        if let selectedCalendarDate {
            modelDiario.list = modelDiario.searchPorFecha(for: selectedCalendarDate)
            return
        }

        modelDiario.getAllItem()
    }

    @ViewBuilder
    private func exportDiarioPDFMenu() -> some View {
        Menu {
            Button("Manual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                manuallySelectedDiarioIDs.removeAll()
                showManualExportSheet = true
            }
            Button("Semana actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                exportDiarioToPDF(diarioCurrentWeek(), scopeName: "Semana")
            }
            Button("Mes actual") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                exportDiarioToPDF(diarioCurrentMonth(), scopeName: "Mes")
            }
            Button("Rango de fechas") {
                guard hasPremiumPDFAccess else {
                    alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
                    showAlert = true
                    return
                }
                showExportRangeSheet = true
            }
        } label: {
            Label("Exportar PDF", systemImage: "doc.richtext")
        }
    }

    private func toggleManualDiarioSelection(_ item: Diario) {
        guard let id = item.id else { return }
        if manuallySelectedDiarioIDs.contains(id) {
            manuallySelectedDiarioIDs.remove(id)
        } else {
            manuallySelectedDiarioIDs.insert(id)
        }
    }

    private func diarioCurrentWeek() -> [Diario] {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return diarioInRange(from: interval.start, to: interval.end)
    }

    private func diarioCurrentMonth() -> [Diario] {
        let calendar = Calendar.current
        let now = Date()
        guard let interval = calendar.dateInterval(of: .month, for: now) else { return [] }
        return diarioInRange(from: interval.start, to: interval.end)
    }

    private func diarioInRange(from start: Date, to end: Date) -> [Diario] {
        modelDiario.list.filter { item in
            guard let date = item.fecha else { return false }
            return date >= start && date < end
        }
    }

    private func exportDiarioRangeToPDF(from start: Date, to end: Date) {
        let items = modelDiario.searchPorRangoFecha(from: start, to: end, typeFecha: .FechaCreacion)
        exportDiarioToPDF(items, scopeName: "Rango")
    }

    private func exportDiarioToPDF(_ entries: [Diario], scopeName: String) {
        guard hasPremiumPDFAccess else {
            alertMessage = "La exportación a PDF está disponible en la Versión Extendida."
            showAlert = true
            return
        }
        guard !entries.isEmpty else {
            alertMessage = "No hay entradas para exportar en \(scopeName.lowercased())."
            showAlert = true
            return
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.fecha ?? Date.distantPast)
        }

        let sections: [PDFExportSection] = grouped.keys.sorted().map { day in
            let dayEntries = (grouped[day] ?? []).sorted { ($0.fecha ?? .distantPast) < ($1.fecha ?? .distantPast) }
            let lines: [PDFExportLine] = dayEntries.map { item in
                let title = (item.title ?? "").isEmpty ? "Sin título" : (item.title ?? "Sin título")
                let emotion = Emociones.emoji(from: item.emotion)
                let content = (item.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let detail = content.isEmpty ? "Estado: \(emotion)" : "Estado: \(emotion)\n\(content)"
                return PDFExportLine(title: title, detail: detail)
            }
            return PDFExportSection(title: day.formatted(date: .complete, time: .omitted), lines: lines)
        }

        let descriptor = PDFExportDocumentDescriptor(
            title: "Diario - \(scopeName)",
            subtitle: "Generado el \(Date().formatted(date: .abbreviated, time: .shortened))",
            sections: sections
        )

        do {
            let data = try PDFExportModule.render(descriptor)
            exportedPDFDocument = ExportedPDFDocument(data: data)
            let dateLabel = Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-")
            exportedPDFFileName = "Diario-\(scopeName)-\(dateLabel)"
            showPDFExporter = true
        } catch {
            alertMessage = "No se pudo generar el PDF."
            showAlert = true
        }
    }

}




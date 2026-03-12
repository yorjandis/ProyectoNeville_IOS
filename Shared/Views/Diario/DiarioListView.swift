//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData

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
    
    
    //Ordenar las entradas del Diario por fechaCreación/fechaModificación
    @AppStorage(AppCons.UD_setting_OrdenarEntradaDiario) var ordenarEntradaDiario : Bool = true // true es fechaCreación; false es fecha de modificación
    @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false //Para poder manejar el acceso al diario
 
    //Almacena la contraeña de acceso en el Llavero, si existe:
    @State private var hasPassword = false

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
                            ScrollView(){
                                if self.securityModel.canOpenDiario {
                                        LazyVStack{
                                            ForEach(modelDiario.list) { item in
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
                                                    }
                                                )
                                                    .padding(15)
                                                    .frame(maxWidth: .infinity)
                                                    .foregroundStyle(Color.black)
                                                    .background(.white.opacity(0.7))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .shadow(radius: 5)
                                                    .padding(.horizontal, 15)
                                                    .padding(.vertical, 8)
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
                                Button{
                                    if  modelDiario.addItem(title: "Título", emocion: .neutral, content: "Nuevo Contenido!") {
                                        withAnimation {
                                            modelDiario.getAllItem()
                                        }
                                        if FeedBackModel.checkReviewRequest() {
                                            self.sheetShowFeedBackReview = true
                                        }
                                    }
                                }label:{
                                    Label("Nueva Entrada", systemImage: "square.and.pencil")
                                }
                                
                                Menu{
                                    ForEach(0..<titlesExamples.count, id: \.self){ value in
                                        Button(titlesExamples[value].0){
                                            if  modelDiario.addItem(title: titlesExamples[value].0, emocion: modelDiario.getEmocionesFromStr(value: titlesExamples[value].1) , content: "Nuevo contenido!"){
                                                
                                                withAnimation {
                                                    modelDiario.getAllItem()
                                                }
                                                if FeedBackModel.checkReviewRequest() {
                                                    #if os(macOS)
                                                    showWindow(for: FeedbackView(showTextBotton: false),
                                                               environmentObjects: [],
                                                               title: "Enviar una Reseña a la App Store",
                                                               size: AppCons.windows_size_content_small,
                                                               isModal: true
                                                    )
                                                    #else
                                                    self.sheetShowFeedBackReview = true
                                                    #endif
                                                    
                                                }
                                            }
                                            
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
            .sheet(isPresented: self.$sheetShowFeedBackReview, content: {
                FeedbackView(showTextBotton: true)
            })
            .sheet(isPresented: $showDiarioStats) {
                DiarioStatsView()
            }
            .alert("Diario", isPresented: $showAlert) {
                
            } message: {
                Text(self.alertMessage)
            }
  
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

}









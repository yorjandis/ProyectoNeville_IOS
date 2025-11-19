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
    
    @EnvironmentObject var securityModel : SecurityModel //Hay que pasar esta clave de entorno (macOS)
    
    //Para filtros en fechas
    enum TypeOfSearch{case fix, interval}
    
    //Para Buscar en títulos
    @State private var showAlertFilterByTitles = false
    @State private var textfielTitles = ""
    //Para Buscar en contenido
    @State private var showAlertFilterByContent = false
    //Para buscar eb fechas:
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
    
    
    //Ordenar las entradas del Diario por fechaCreación/fechaModificación
    @AppStorage(AppCons.UD_setting_OrdenarEntradaDiario) var ordenarEntradaDiario : Bool = true // true es fechaCreación; false es fecha de modificación
   @AppStorage(AppCons.UD_setting_DiarioSiempreOpenFaceID) var setting_DiarioSiempreOpenFaceID  : Bool = false //Para poder manejar el acceso al diario
 
    

    var body: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient(colors: [Color(red:0.45, green:0.50, blue: 0.50), .orange], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                if self.securityModel.canOpenDiario{
                    VStack{
                        Text("") //Para que las entradas no sobrepasen el area segura superior
                        
                        //Calendario:
                        if self.showCalendar {
                            VStack{
                                    DiarioCalendarView { date in
                                        withAnimation {
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
                                                cardItem(diario: item)
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
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .padding(.vertical, 25)
                            #endif
                            
                            
                        }else{
                            //NO hay soporte para Biometria
                            VStack{
                                //Chequeamos si hay una clave guardada:
                                if KeychainHelper.shared.getPassword() != nil{ //Hay una clave
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
                //Al cerrar la ventana del Diario se chequea si la opción de mentener la ventana abierta y se ha obtenido efectivamente
                //acceso al Diario estan en true: entonces, la variable observable que da acceso al Diario permanece en true.
                //De lo contrario, la variable observable que da acceso al Diario se pone a false y se tiene que loggear para entrar al Diario
                if (self.setting_DiarioSiempreOpenFaceID == true && self.securityModel.canOpenDiario == true){
                    self.securityModel.canOpenDiario = true
                    print("Yorjandis: 1")
                }else{
                    self.securityModel.canOpenDiario = false
                    print("Yorjandis: 2")
                }
                //nota: La otra parte de esta función está en la raíz de la app: al abrirse la app siempre se restablece la
                //variable observable que da acceso al Diario a false. Esto es para poder entrar por loguien en cada sesión de la app.
                //Esta opción de mantener la ventana abierta/cerrada del Diario esta en Ajustes bajo un flag booleano.
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
                        Button{
                            withAnimation {
                                self.showCalendar.toggle()
                                //Si oculta el calendario se muestra todos los items
                                if self.showCalendar == false {
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
                                modelDiario.getAllItem()
                            }label:{
                                Label("Ordenar Por fecha de \(self.ordenarEntradaDiario ? "Modificación" : "Creación")", systemImage: "text.magnifyingglass")
                            }
                            
                            //Mostrar todas las entradas
                            Button{
                                withAnimation {
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
                                Button{withAnimation {
                                    modelDiario.list =  modelDiario.filterByEmoticono(criterio: Emociones.feliz.rawValue)
                                }
                                }label: {
                                    #if os(macOS)
                                    HStack{
                                        Text(Emociones.feliz.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.feliz.rawValue)
                                    }
                                    #else
                                    Label(Emociones.feliz.rawValue.capitalized, image: Emociones.feliz.rawValue)
                                    #endif
                                    
                                }
                                Button{withAnimation {
                                    modelDiario.list = modelDiario.filterByEmoticono(criterio: Emociones.neutral.rawValue)
                                }
                                }label: {
                                #if os(macOS)
                                    HStack{
                                        Text(Emociones.neutral.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.neutral.rawValue)
                                    }
                                    #else
                                    Label(Emociones.neutral.rawValue.capitalized, image: Emociones.neutral.rawValue)
                                    #endif
                                }
                                Button{ withAnimation {
                                    modelDiario.list = modelDiario.filterByEmoticono(criterio: Emociones.desanimado.rawValue)
                                }
                                }label: {
                                #if os(macOS)
                                    HStack{
                                        Text(Emociones.desanimado.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.desanimado.rawValue)
                                    }
                                #else
                                    Label(Emociones.desanimado.rawValue.capitalized, image: Emociones.desanimado.rawValue)
                                #endif
                                }
                                Button{withAnimation {
                                    modelDiario.list = modelDiario.filterByEmoticono(criterio: Emociones.enfado.rawValue)
                                }
                                }label: {
                                #if os(macOS)
                                    HStack{
                                        Text(Emociones.enfado.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.enfado.rawValue)
                                    }
                                #else
                                    Label(Emociones.enfado.rawValue.capitalized, image: Emociones.enfado.rawValue)
                                #endif
                                }
                                Button{withAnimation {
                                    modelDiario.list = modelDiario.filterByEmoticono(criterio: Emociones.distraido.rawValue)
                                }
                                }label: {
                                #if os(macOS)
                                    HStack{
                                        Text(Emociones.distraido.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.distraido.rawValue)
                                    }
                                #else
                                    Label(Emociones.distraido.rawValue.capitalized, image: Emociones.distraido.rawValue)
                                #endif
                                }
                                Button{withAnimation {
                                    modelDiario.list = modelDiario.filterByEmoticono(criterio: Emociones.sorpresa.rawValue)
                                }
                                }label: {
                                #if os(macOS)
                                    HStack{
                                        Text(Emociones.sorpresa.rawValue.capitalized)
                                        iconoRedimensionado(nombre: Emociones.sorpresa.rawValue)
                                    }
                                #else
                                    Label(Emociones.sorpresa.rawValue.capitalized, image: Emociones.sorpresa.rawValue)
                                #endif
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
            .alert("Diario", isPresented: $showAlert) {
                
            } message: {
                Text(self.alertMessage)
            }
  
         }
    }
    


}





//Card Item
struct cardItem: View{
    @Environment(\.colorScheme) var theme
    
    @State var diario : Diario //Entrada a mostrar
    
    @StateObject private var diarioModel = DiarioModel.shared
    
    @State private var expandText = false //Permite expandir/contraer el texto de una entrada
    @State private var isEditing = false
    @State private var textfield = ""
    //Alert: Modificar titulo
    @State private var showAlert = false
    @State private var title = ""
    //Alert Eliminar Entrada
    @State private var showAlertDeleteEntry = false
    //Edit Content
    @State private var showSheet = false
    //favorito
    @State private var isfav : Bool = false
    //Animation
    @State private var animValue = 0
    

   private let emociones : [Emociones] = [.neutral,.feliz,.enfado,.desanimado,.distraido,.sorpresa]
    
    
    var body: some View{
        VStack(spacing: 20){
            //EmotioIcon
            HStack{
                Menu{
                    ForEach(0..<6){idx in
                        Button{
                            diarioModel.UpdateEmoticono(emoticono:  emociones[idx], diario: diario)
                            withAnimation {
                                diarioModel.getAllItem()
                            }
                            
                            
                        }label: {
                            #if os(macOS)
                            HStack{
                                Text(emociones[idx].rawValue)
                                iconoRedimensionado(nombre: emociones[idx].rawValue)
                            }
                            #else
                            Label(emociones[idx].rawValue, image: emociones[idx].rawValue )
                            #endif
                            
                        }
                            
                    }
                    
                    
                }label: {
                    
                    #if os(macOS)
                    iconoRedimensionado(nombre: diario.emotion ?? "neutral")
                    
                    #else
                    Image(diario.emotion ?? "neutral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .shadow(radius: 5)
                    
                    #endif
                    
                    
                }
                
                //Título
                Text(diario.title ?? "")
                    .font(.headline).bold()
                    .onTapGesture(count: 2) {
                        #if os(macOS)
                        showWindow(for: VStack{
                            TextField("Nuevo título", text: $title)
                                .foregroundStyle(theme == .dark ? .white : .black)
                            Button("Cancelar"){
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                            }
                            Button("Guardar"){
                                diarioModel.UpdateTitle(title: title, diario: diario)
                                diarioModel.getAllItem()
                                //Saliendo
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                            }
                        }.padding(10),
                                   environmentObjects: [self.diarioModel],
                                   title: "Editar Entrada Diario",
                                   size: AppCons.windows_size_content_small,
                                   isModal: true
                        
                        )
                        #else
                        showAlert = true
                        #endif
                        
                    }
                Spacer()
                
            }
            
            
            //Contenido
                Text(diario.content ?? "")
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
                    .italic()
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .lineLimit(self.diarioModel.expandirEntrada == self.diario.fecha?.formatted() ? nil :  1) //Aquí es donde se contrae o se expande las lineas
                    .onTapGesture{
                        withAnimation {
                            if self.diarioModel.expandirEntrada == self.diario.fecha?.formatted(){
                                self.diarioModel.expandirEntrada = ""
                            }else{
                                self.diarioModel.expandirEntrada = self.diario.fecha?.formatted() ?? ""
                            }
                        }
                    }
                    .onTapGesture(count: 2) {
                        
                        #if os(macOS)
                        showWindow(for: editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")),
                                   environmentObjects: [self.diarioModel],
                                   title: "Editar entrada Diario",
                                   size: AppCons.windows_size_content,
                                   isModal: false
                        
                        )
                        
                        #else
                        self.showSheet = true
                        #endif
                        
                        
                       
                    }

            
            
                
            
            //Fecha, fav y ContextMenu
            VStack {
                Divider()
                HStack{
                    VStack{
                        HStack{
                            Text("Modificado:")
                            .font(.system(size: 10))
                            Text(diario.fechaM ?? Date.now, style: .date)
                                .font(.caption2).bold()
                            Text(diario.fechaM ?? Date.now, style: .time)
                                .font(.caption2).bold()
                        }
                        HStack{
                            Text("       Creado:")
                            .font(.system(size: 10))
                            Text(diario.fecha ?? Date.now, style: .date)
                                .font(.caption2).bold()
                            Text(diario.fecha ?? Date.now, style: .time)
                                .font(.caption2).bold()
                        }
   
                    }
                    Spacer()
                    //Favorito
                    Button{
                        isfav.toggle()
                        diarioModel.UpdateFav(isFav: isfav, diario: diario)
                        animValue += 1
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred() //Leve vibración al tocal el boton
                        #endif
                        
                    }label: {
                        Image(systemName: isfav ? "heart.fill" : "heart")
                            .foregroundStyle(.black)
                            .padding(.trailing, 10)
                            .symbolEffect(.bounce, value: animValue)
                    }
                    .buttonStyle(.plain)
                    .onAppear{
                        isfav = diario.isFav
                    }

                    Menu{
                        Button{
                            #if os(macOS)
                            showWindow(for: editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")),
                                       environmentObjects: [self.diarioModel],
                                       title: "Editar entrada Diario",
                                       size: AppCons.windows_size_content,
                                       isModal: true
                                       
                            )
                            
                            #else
                            self.showSheet = true
                            #endif
                        }label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive){
                            showAlertDeleteEntry = true
                        }label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                    }label: {
                        Image(systemName: "ellipsis")
                            .tint(.black)
                            .frame(width: 20, height: 20)
                    
                }//menu
                .buttonStyle(.plain)
                    
                }
            }
        }

        .alert("Modificar Título", isPresented: $showAlert){
            TextField("Nuevo título", text: $title)
                .foregroundStyle(theme == .dark ? .white : .black)
            Button("Cancelar"){
                showAlert = false
            }
            Button("Guardar"){
                diarioModel.UpdateTitle(title: title, diario: diario)
                diarioModel.getAllItem()
            }
            
        }
        .alert("¿Desea eliminar la entrada? \n Esta acción no puede deshacerse", isPresented: $showAlertDeleteEntry, actions: {
            Button("Eliminar", role: .destructive){
                withAnimation {
                    diarioModel.DeleteItem(diario: diario)
                    diarioModel.getAllItem()
                }
            }
        })
        .sheet(isPresented: $showSheet){
            editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral"))
        }
        
    }
}


//View: Editar el contenido de una entrada del diario
struct editContent : View {
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    @StateObject private var diarioModel = DiarioModel.shared
    
    @Binding var diario : Diario
    
    @State  var textTitle : String
    @State  var textContent : String
    @State  var emoticono : Emociones
    
    private let emociones : [Emociones] = [.neutral,.feliz,.enfado,.desanimado,.distraido,.sorpresa]
    
    enum Focustext{
        case title
        case content
    }
    @FocusState private var focus: Focustext?
    
    var body: some View {
        NavigationStack {
            List{
                Section("Título"){
                    HStack(spacing: 5){
                        Menu{
                            ForEach(0..<6){idx in
                                Button{
                                    emoticono = emociones[idx]
                                    
                                }label: {
                                    
                                     #if os(macOS)
                                     HStack{
                                         Text(emociones[idx].rawValue)
                                         iconoRedimensionado(nombre: emociones[idx].rawValue)
                                     }
                                     #else
                                     Label(emociones[idx].rawValue, image: emociones[idx].rawValue )
                                     #endif
                                }
                                
                            }
                        }label: {
                            
                             #if os(macOS)
                            iconoRedimensionado(nombre: emoticono.rawValue)
                             #else
                             Image(emoticono.rawValue)
                                 .resizable()
                                 .scaledToFit()
                                 .frame(width: 50)
                                 .shadow(radius: 5)
                             #endif
                             
                             
                            
                            
                        }
                        
                        
                        TextField("", text: $textTitle, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .focused(self.$focus, equals: .title)
                            
                    }
                    
                }
                
                Section("Contenido"){
                    
                        TextField("", text: $textContent, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                            .focused(self.$focus, equals: .content)
                }
                
                
            }
            //Al inicio actualiza el icono de emocion
            .foregroundStyle(theme == .dark ? .white : .black)
            .onAppear{
                emoticono = diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")
            }
            .onChange(of: self.focus) { oldValue, newValue in
               switch newValue {
               case .title:
                   if self.textTitle == "Título"{
                       self.textTitle = ""
                   }
               case .content:
                   if self.textContent == "Nuevo Contenido!" {
                       self.textContent = ""
                   }
               default:
                   self.focus = nil
                }
            }
            .navigationTitle("Modificar Entrada")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar{
                
                #if os(macOS)
                ToolbarItem(placement: .principal) {
                    Button{
                        if let window = NSApp.keyWindow {
                            closeWindow(window)
                        }
                    }label:{
                        //close
                        Image(systemName: "xmark.circle")
                            
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.plain)
                }
                
                #endif
                
                ToolbarItem {
                    Button(action: {
                        diarioModel.UpdateItem(diario: diario, title: textTitle, content: textContent, emoticono: emoticono)
                        diarioModel.getAllItem()
                        dimiss()
                    }) {
                        Text("Guardar")
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Color.blue
                            )
                            .clipShape(Capsule())
                            .compositingGroup()

                    }
                    .buttonStyle(PlainButtonStyle())
                    .tint(.clear)
                }
                
                
            }
        }
    }
}


#if os(macOS)

/// Crea un `Image` redimensionado a partir de un recurso `NSImage`.
/// - Parameters:
///   - nombre: Nombre del recurso de imagen en tus assets.
///   - tamaño: Altura deseada en puntos (el ancho se ajusta manteniendo la proporción).
///   - imagenPorDefecto: Nombre de una imagen por defecto si no se encuentra el recurso.
/// - Returns: Un `Image` de SwiftUI redimensionado.
func iconoRedimensionado(nombre: String?, tamaño: CGFloat = 24, imagenPorDefecto: String = "b_carpeta") -> Image {
    // Cargar la imagen de recursos
    guard let nsImage = NSImage(named: nombre ?? imagenPorDefecto) else {
        return Image(nsImage: NSImage()) // Imagen vacía en caso de error
    }
    
    // Mantener proporción
    let ratio = nsImage.size.height / nsImage.size.width
    nsImage.size.height = tamaño
    nsImage.size.width = tamaño / ratio
    
    // Devolver como Image de SwiftUI
    return Image(nsImage: nsImage)
}

#endif




#Preview {
    DiarioListView()
}


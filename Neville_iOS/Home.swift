//
//  Home.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/11/23.
//

import SwiftUI
import CoreData

struct Home: View {

    @EnvironmentObject private var settingModel : SettingModel
    @Environment(\.scenePhase) private var scenePhase
    
    @AppStorage("MostrarMetasEnHome") var MostrarMetasEnHome: Bool = false
    
    @State  private var showAddNoteList = false //Abre la view AddNota
    
    @State  private var fontSize : CGFloat = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize)) //Setting para Frases
    @State  private var fontSizeMenu : CGFloat = 24 //Setting para menu

    //Lanzar Ventana de novedades:
    @State private var showNovedades: Bool = false
    
    
    //Pruebas
    @State private var showCrearRecordatorio: Bool = false
    @State private var showListaRecordatorios: Bool = false


    //Recordatorios Witget:
    @StateObject private var modelRecordatorios: SelectedReminderModel = .init() //Inicia el modelo de los recordatorios de Widgets

    // Fuerza la recreación del gadget de metas cuando Home reaparece.
    @State private var goalsGadgetRefreshID = UUID()
    @State private var showRitualMatutino: Bool = false
    @State private var showAgenda: Bool = false
    @State private var showPremium: Bool = false
    @State private var now = Date()

    @AppStorage("Home_RitualMatutino_HiddenDayKey") private var ritualMatutinoHiddenDayKey: String = ""
    @AppStorage("Home_ShowAgendaButton") private var showAgendaButtonInHome: Bool = true
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    private let ritualButtonTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private struct RitualSessionVisibilityDTO: Decodable {
        let sessionDateEpochDay: Int
        let completed: Bool
    }

    private var ritualTodayEpochDay: Int {
        let start = Calendar.current.startOfDay(for: now)
        return Int(start.timeIntervalSince1970 / 86_400)
    }

    private var ritualCompletedToday: Bool {
        let defaults = UserDefaults(suiteName: AppCons.AppGroupName) ?? .standard
        guard let data = defaults.data(forKey: "morning_ritual_sessions"),
              let sessions = try? JSONDecoder().decode([RitualSessionVisibilityDTO].self, from: data) else {
            return false
        }

        return sessions.contains { $0.completed && $0.sessionDateEpochDay == ritualTodayEpochDay }
    }

    private var ritualCurrentDayKey: String {
        let calendar = Calendar.current
        let adjustedDate = calendar.date(byAdding: .hour, value: -3, to: now) ?? now
        let components = calendar.dateComponents([.year, .month, .day], from: adjustedDate)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var shouldShowRitualButton: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 3
            && ritualMatutinoHiddenDayKey != ritualCurrentDayKey
            && !ritualCompletedToday
    }

    private var shouldShowAgendaButton: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 3 && showAgendaButtonInHome
    }

    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                
                LinearGradient(gradient: Gradient(colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack{
                    
                    //Muestra el logo de la App dentro de un rectángulo áureo
                    GoldenLogoNeville()
                    
                    //Muestra un texto para felicitar a neville por su cumpleños(19 Frebrero)
                    MostrarCumpleaños()
                    
                    //Muestra si estamos en modo debug. Solo aparecerá en la fase de desarrollo
                   //MostrarModoDebug()

                    //Muestra el texto para indicar nueva actualización
                    ViewIfNewUpdateAvailable()
                    
                    Spacer()

                    FrasesHomeView()


                    Spacer()

                    /*
                     #if DEBUG
                     NavigationLink("Color_Tools"){
                         ColorTool_Helper()
                     }
                     #endif
                     */
                    
                    
                    
                    //Barra de gadgets de Metas:
                    if self.MostrarMetasEnHome {
                        GoalsGadgetWidgetListView()
                            .id(goalsGadgetRefreshID)
                    }
                    

                    //Barra de Recordatorios:
                   ReminderWidgetList_View()


                    //Botones de acceso rápido: Ritual Matutino / Agenda
                    if shouldShowRitualButton || shouldShowAgendaButton {
                        HStack(spacing: 10) {
                            if shouldShowRitualButton {
                                Button {
                                    showRitualMatutino = true
                                } label: {
                                    Label("Ritual Matutino", systemImage: "sunrise.fill")
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(.white.opacity(0.82))
                                        .clipShape(Capsule())
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        ritualMatutinoHiddenDayKey = ritualCurrentDayKey
                                    } label: {
                                        Label("Ocultar por hoy", systemImage: "eye.slash")
                                    }
                                }
                            }

                            if shouldShowAgendaButton {
                                Button {
                                    if purchaseStatus || yorjPremium {
                                        showAgenda = true
                                    } else {
                                        showPremium = true
                                    }
                                } label: {
                                    Label("Agenda", systemImage: "calendar")
                                        .font(.headline)
                                        .foregroundStyle(.black)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(.white.opacity(0.82))
                                        .clipShape(Capsule())
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        showAgendaButtonInHome = false
                                    } label: {
                                        Label("Ocultar", systemImage: "eye.slash")
                                    }
                                }
                            }
                        }
                    }

                    TabButtonBar(
                        fontFrasesSize: $fontSize,
                        fontMenuSize: $fontSizeMenu,
                        colorFrase:  Binding(get:  { self.settingModel.colorfrase }, set: { self.settingModel.colorfrase = $0 }),
                        colorFondo_a: Binding(get: { self.settingModel.colorFondo_a }, set: { self.settingModel.colorFondo_a = $0 }),
                        colorFondo_b: Binding(get: { self.settingModel.colorFondo_b }, set: { self.settingModel.colorFondo_b = $0 })
                    )
                }
   
            }
            .onAppear {
                now = Date()

                // Refresca el gadget de metas cada vez que Home vuelve a aparecer.
                goalsGadgetRefreshID = UUID()

                //Ejecutar Lógica la primera vez que se instala o se actualiza la función 
                switch RunFirstTimeModel.CheckStatusAppRun(){
                case .firstLaunchApp:
                    msg("Primera vez que se instala la App")
                    //Actualiza las variables iniciales del Lienzo:
                    UserDefaults.standard.set(true,forKey: LienzoModel.key_visibilidadTextoSecundario) //Visibilidad de Imagen
                    UserDefaults.standard.set(true, forKey: LienzoModel.key_visibilidadImagenLienzo)
                    LienzoModel.shared.saveColorTextoSecundario(colorTexttoSecundario: .black) //Color del Texto Secundario
                    
                    
                     //Popula la Tabla Frases Si es la primera Vez que se instala la App:
                     let frasesModel = FrasesModel.shared
                     Task{
                         await frasesModel.ImportadorDeFrases()
                     }

                    
                    //Muestra la ventana de Resultados
                    self.showNovedades = true
                case .updateApp:
                    msg("La App se ha Actualizado")
                    //Muestra la ventana de resultados
                    self.showNovedades = true
                    
                    
                     //Popula la Tabla Frases al actualizar si nunca se ha realizado:
                     let frasesModel = FrasesModel.shared
                     Task{
                         await frasesModel.ImportadorDeFrases()
                     }
                     
                    
                    
                default:
                    msg("La App ni se ha instalado ni se ha actualizado: Se ha iniciado en modo debug en Xcode")
                    
                    #if DEBUG
                     //Popula la Tabla Frases al actualizar si nunca se ha realizado:
                     let frasesModel = FrasesModel.shared
                     Task{
                         await frasesModel.ImportadorDeFrases()
                     }
                    #endif
                     
                     
                    
                }
                
            }
            .onReceive(ritualButtonTimer) { value in
                now = value
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    now = Date()
                }
            }
            
        }
        .sheet(isPresented: self.$showNovedades) {
            Novedades()
        }
        .sheet(isPresented: $showRitualMatutino) {
            MorningRitualMainView()
        }
        .sheet(isPresented: $showAgenda) {
            AgendaMainView()
        }
        .sheet(isPresented: $showPremium) {
            PurchaseView()
        }
        
    }
    

}//struct










//CustomTabView
struct TabButtonBar : View{
    
    @EnvironmentObject private var frasesModel : FrasesModel
    @EnvironmentObject private var securityModel : SecurityModel
    @EnvironmentObject private var clipBoardModel : ClipboardObserver
    
    @State      var showOptionView = false
    @Binding    var fontFrasesSize : CGFloat //Setting
    @Binding    var fontMenuSize : CGFloat //Setting$
    
    @Binding    var colorFrase : Color
    
    @Binding    var colorFondo_a : Color
    @Binding    var colorFondo_b : Color
    

    @State private var showSetting = false
    
    
    @State private var sellectionTab = 1
    

    @State var  tabButtons = ["book.pages.fill","note.text","house.circle.fill","book", "gear"]
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        VStack{
            HStack{
                ForEach(tabButtons, id:\.self){idx in
                    switch idx{
                    case "book.pages.fill": //Listado de Conferencias
                        NavigationLink{
                            TxtListView(typeOfContent: .conf, title: "Lecturas")
                                .environmentObject(self.clipBoardModel)
                        }label: {
                            makeItemlabel(image: idx)
                        }
                        
                    case "note.text":
                        NavigationLink{
                           ListNotasViews()
                        }label: {
                            makeItemlabel(image: idx)
                        }
                    
                    case "house.circle.fill":
                        Button{
                           showOptionView = true
                        }label: {
                            makeItemlabel(image: idx)
                                .font(.system(size: 30))
                        }
                        
                    case "book":
                        NavigationLink{
                            DiarioListView()
                                .environmentObject(securityModel)
                        }label: {makeItemlabel(image: idx)}
                        
                    case "gear":
                        if #available(iOS 26.0, *){
                            if IAModelAppleIntelligence.isAvailable(){
                                NavigationLink{
                                    ChatView(textoACargar: nil)
                                }label: {
                                    Image(systemName: "ellipsis.message")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.black.opacity(0.7))
                                        .padding(8)
                                }
                            }else{
                                Button{ showSetting = true
                                }label: {
                                    makeItemlabel(image: idx)
                                    
                                }
                            }
                        }else{
                            Button{ showSetting = true
                            }label: {
                                makeItemlabel(image: idx)
                                
                            }
                        }
                        

                    default: EmptyView()
                        
                    }

                    
                    //Insertando un espaciado para mantener la distancia entre los items
                    if idx != tabButtons.last {
                        Spacer(minLength: 0)
                    }
                    
                }//ForEach
                
            }
            .padding(.horizontal, 25)
            .background(LinearGradient(colors: [.gray, .cyan], startPoint: .top, endPoint: .bottom))
            //.modifier(mof_ColorGradient(colorInit: $colorFondo_a, colorEnd: $colorFondo_b))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 5, y: 5)
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: -5, y: -5)
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
        .sheet(isPresented: $showOptionView) {
            optionView()
               .presentationDetents([.height(280)])
               .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSetting, content: {
            Ajustes()
        })
    }
    
    //Create UI for reusability
    func makeItemlabel(image : String)->some View{
        return Image(systemName: image)
            .renderingMode(.template)
            .foregroundColor( Color.black.opacity(0.4))
            .padding(10)
        
    }
    
}



//View: Permite guardar una nueva nota en la BD
struct AddNotasViewInbuilt: View {
    @Environment(\.dismiss) var dimiss
    
    @State var title : String = ""
    @State var nota : String = ""
    
    
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Título"){
                    TextField("", text: $title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    
                }
                Section("Nota"){
                    TextField("", text: $nota, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle("Adicionar una nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !save() {
                            msg("se ha producido un error al guardar la nota")
                        }
                        
                        dimiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar"){
                        dimiss()
                    }
                }
            }
        }
        
    }
    
    ///Guardar un valor y actualiza el arreglo de notas pasado como @Binding
    ///- Returns : true si exito, false otherwise
    func save()-> Bool{
        let title = title.trimmingCharacters(in: .whitespaces)
        let nota = nota.trimmingCharacters(in: .whitespaces)
        
        if (nota.isEmpty || title.isEmpty) {return false}
        
        if  NotasModel().addNote(nota: nota, title: title) {
            return true
        }else{
            return false
        }
    }
    
}








#Preview {
    ContentView()
}

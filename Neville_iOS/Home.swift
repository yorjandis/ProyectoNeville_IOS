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
    @Environment(\.colorScheme) private var colorScheme
    
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
    @StateObject private var agendaViewModel = AgendaViewModel()
    @StateObject private var ritualNavigation = RitualNavigationCoordinator.shared

    // Fuerza la recreación del gadget de metas cuando Home reaparece.
    @State private var goalsGadgetRefreshID = UUID()
    @State private var showRitualMatutino: Bool = false
    @State private var showAgenda: Bool = false
    @State private var showPresence: Bool = false
    @State private var showPremium: Bool = false
    @State private var now = Date()
    @State private var renderAlternativeHomeDesign: Bool = false

    @AppStorage("Home_ShowAlternativeHomeDesign") private var showAlternativeHomeDesign: Bool = false
    @AppStorage("Home_RitualMatutino_HiddenDayKey") private var ritualMatutinoHiddenDayKey: String = ""
    @AppStorage("Home_ShowMyDayButton") private var showMyDayButtonInHome: Bool = true
    @AppStorage("Home_ShowAgendaButton") private var showAgendaButtonInHome: Bool = true
    @AppStorage("Home_AgendaBadge_HiddenDayKey") private var agendaBadgeHiddenDayKey: String = ""
    @AppStorage("Home_ShowPresenceButton") private var showPresenceButtonInHome: Bool = true
    @AppStorage(AppCons.UD_setting_HomeAlternativoShowHealingCenterCard) private var showHealingCenterCardInHome: Bool = true
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    private let quickAccessButtonBackgroundOpacity = 0.90 //Opacidad de los botones de acceso: Ritual, Agenda y Presencia.
    
    private let ritualButtonTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var ritualTodayEpochDay: Int {
        let start = Calendar.current.startOfDay(for: now)
        return Int(start.timeIntervalSince1970 / 86_400)
    }

    private var ritualCompletedToday: Bool {
        hasStoredRitual(kind: "morning", requiresCompletion: true)
    }

    private var eveningReviewCompletedToday: Bool {
        hasStoredRitual(kind: "evening", requiresCompletion: false)
    }

    private var eveningReviewNeedsUpdateToday: Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "RitualSessionEntity")
        request.predicate = NSPredicate(
            format: "kind == %@ AND sessionDateEpochDay == %lld",
            "evening", Int64(ritualTodayEpochDay)
        )
        request.fetchLimit = 1
        guard let review = try? CoreDataController.shared.context.fetch(request).first else { return false }
        let snapshot = EveningDaySnapshot.load()
        return Int(review.value(forKey: "agendaCompletedCount") as? Int32 ?? 0) != snapshot.agendaCompleted.count
            || Int(review.value(forKey: "agendaTotalCount") as? Int32 ?? 0) != snapshot.agendaTotalCount
            || Int(review.value(forKey: "goalUnitsCompletedCount") as? Int32 ?? 0) != snapshot.completedGoalUnits.count
            || Int(review.value(forKey: "presenceReturns") as? Int32 ?? 0) != snapshot.presenceReturns
            || Int(review.value(forKey: "automaticPilotEvents") as? Int32 ?? 0) != snapshot.automaticPilotEvents
            || Int(review.value(forKey: "coherenceSessionsCount") as? Int32 ?? 0) != snapshot.coherenceSessionsCount
    }

    private func hasStoredRitual(kind: String, requiresCompletion: Bool) -> Bool {
        let context = CoreDataController.shared.context
        let request = NSFetchRequest<NSManagedObject>(entityName: "RitualSessionEntity")
        var predicates: [NSPredicate] = [
            NSPredicate(format: "kind == %@", kind),
            NSPredicate(format: "sessionDateEpochDay == %lld", Int64(ritualTodayEpochDay))
        ]
        if requiresCompletion {
            predicates.append(NSPredicate(format: "completed == YES"))
        }
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.fetchLimit = 1
        return ((try? context.count(for: request)) ?? 0) > 0
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

    private var agendaBadgeCurrentDayKey: String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: now)
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

    private var shouldShowEveningReviewButton: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 18 && !eveningReviewCompletedToday
    }

    private var shouldShowAgendaButton: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 3 && showAgendaButtonInHome
    }

    private var shouldShowPresenceButton: Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= 3 && showPresenceButtonInHome
    }

    private var todayAgendaActivitiesCount: Int {
        agendaViewModel.items.filter {
            Calendar.current.isDate($0.fechaActividad, inSameDayAs: now)
        }.count
    }

    private var shouldShowAgendaBadge: Bool {
        todayAgendaActivitiesCount > 0 && agendaBadgeHiddenDayKey != agendaBadgeCurrentDayKey
    }

    private var isRunningForPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private var alternativeHomeVariant: HomeAlternativoVariant {
        colorScheme == .dark ? .oscura : .clara
    }

    private var homeTransitionAnimation: Animation {
        .easeInOut(duration: 0.56)
    }

    private func showAlternativeHome() {
        renderAlternativeHomeDesign = true

        DispatchQueue.main.async {
            withAnimation(homeTransitionAnimation) {
                showAlternativeHomeDesign = true
            }
        }
    }

    private func showFrasesHome() {
        withAnimation(homeTransitionAnimation) {
            showAlternativeHomeDesign = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.58) {
            if !showAlternativeHomeDesign {
                renderAlternativeHomeDesign = false
            }
        }
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


                    //Botones de acceso rápido: apoyo inmediato y herramientas contextuales.
                    if !showAlternativeHomeDesign {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                if showHealingCenterCardInHome {
                                    NavigationLink {
                                        CentroSanadorView()
                                    } label: {
                                        Label("Apoyo ahora", systemImage: "cross.case.fill")
                                            .font(.headline)
                                            .foregroundStyle(.indigo)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(.cyan.opacity(0.30), lineWidth: 1))
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            showHealingCenterCardInHome = false
                                        } label: {
                                            Label("Ocultar", systemImage: "eye.slash")
                                        }
                                    }
                                }

                                if shouldShowRitualButton {
                                    Button {
                                        if purchaseStatus || yorjPremium {
                                        showRitualMatutino = true
                                        } else {
                                            showPremium = true
                                        }
                                            
                                    } label: {
                                        Label("Ritual", systemImage: "sunrise.fill")
                                            .font(.headline)
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
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

                                if shouldShowEveningReviewButton {
                                    Button {
                                        if purchaseStatus || yorjPremium {
                                            showRitualMatutino = true
                                        } else {
                                            showPremium = true
                                        }
                                    } label: {
                                        Label("Cierre", systemImage: "moon.stars.fill")
                                            .font(.headline)
                                            .foregroundStyle(.indigo)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                            .overlay(Capsule().stroke(.indigo.opacity(0.25), lineWidth: 1))
                                    }
                                }

                                if eveningReviewCompletedToday && eveningReviewNeedsUpdateToday {
                                    Button {
                                        ritualNavigation.open(.eveningReview)
                                    } label: {
                                        Label("Actualizar cierre", systemImage: "arrow.triangle.2.circlepath")
                                            .font(.headline)
                                            .foregroundStyle(.orange)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                    }
                                }

                                if showMyDayButtonInHome {
                                    Button {
                                        if purchaseStatus || yorjPremium {
                                            ritualNavigation.open(.wellbeingDashboard)
                                        } else {
                                            showPremium = true
                                        }
                                    } label: {
                                        Label("Mi día", systemImage: "chart.xyaxis.line")
                                            .font(.headline)
                                            .foregroundStyle(.indigo)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            showMyDayButtonInHome = false
                                        } label: {
                                            Label("Ocultar", systemImage: "eye.slash")
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
                                        Label(String(localized: "Agenda"), systemImage: "calendar")
                                            .font(.headline)
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                            .overlay(alignment: .topTrailing) {
                                                if shouldShowAgendaBadge {
                                                    Text(todayAgendaActivitiesCount > 99 ? "99+" : "\(todayAgendaActivitiesCount)")
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundStyle(.white)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.7)
                                                        .frame(width: 22, height: 22)
                                                        .background(Circle().fill(.red.opacity(0.88)))
                                                        .offset(x: 5, y: -1)
                                                }
                                            }
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            showAgendaButtonInHome = false
                                        } label: {
                                            Label("Ocultar", systemImage: "eye.slash")
                                        }

                                        if todayAgendaActivitiesCount > 0 {
                                            Button {
                                                if shouldShowAgendaBadge {
                                                    agendaBadgeHiddenDayKey = agendaBadgeCurrentDayKey
                                                } else {
                                                    agendaBadgeHiddenDayKey = ""
                                                }
                                            } label: {
                                                Label(
                                                    shouldShowAgendaBadge ? "Ocultar indicador por hoy" : "Mostrar indicador",
                                                    systemImage: shouldShowAgendaBadge ? "bell.badge.slash" : "bell.badge"
                                                )
                                            }
                                        }
                                    }
                                }

                                if shouldShowPresenceButton {
                                    Button {
                                        if purchaseStatus || yorjPremium {
                                            showPresence = true
                                        } else {
                                            showPremium = true
                                        }
                                    } label: {
                                        Label("Presencia", systemImage: "sparkles")
                                            .font(.headline)
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(.white.opacity(quickAccessButtonBackgroundOpacity))
                                            .clipShape(Capsule())
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            showPresenceButtonInHome = false
                                        } label: {
                                            Label("Ocultar", systemImage: "eye.slash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    TabButtonBar(
                        fontFrasesSize: $fontSize,
                        fontMenuSize: $fontSizeMenu,
                        colorFrase:  Binding(get:  { self.settingModel.colorfrase }, set: { self.settingModel.colorfrase = $0 }),
                        colorFondo_a: Binding(get: { self.settingModel.colorFondo_a }, set: { self.settingModel.colorFondo_a = $0 }),
                        colorFondo_b: Binding(get: { self.settingModel.colorFondo_b }, set: { self.settingModel.colorFondo_b = $0 }),
                        settingModel: settingModel,
                        isShowingAlternativeHome: showAlternativeHomeDesign,
                        toggleHomeScreen: {
                            if showAlternativeHomeDesign {
                                showFrasesHome()
                            } else {
                                showAlternativeHome()
                            }
                        }
                    )
                }
                .opacity(showAlternativeHomeDesign ? 0 : 1)
                .scaleEffect(showAlternativeHomeDesign ? 0.985 : 1)
                .offset(y: showAlternativeHomeDesign ? -10 : 0)
                .blur(radius: showAlternativeHomeDesign ? 1.2 : 0)
                .allowsHitTesting(!showAlternativeHomeDesign)
                .animation(homeTransitionAnimation, value: showAlternativeHomeDesign)

                if showAlternativeHomeDesign || renderAlternativeHomeDesign {
                    Group {
                        HomeAlternativoView(variant: alternativeHomeVariant)
                            .ignoresSafeArea()

                        VStack {
                            Spacer()

                            TabButtonBar(
                                fontFrasesSize: $fontSize,
                                fontMenuSize: $fontSizeMenu,
                                colorFrase:  Binding(get:  { self.settingModel.colorfrase }, set: { self.settingModel.colorfrase = $0 }),
                                colorFondo_a: Binding(get: { self.settingModel.colorFondo_a }, set: { self.settingModel.colorFondo_a = $0 }),
                                colorFondo_b: Binding(get: { self.settingModel.colorFondo_b }, set: { self.settingModel.colorFondo_b = $0 }),
                                settingModel: settingModel,
                                isShowingAlternativeHome: showAlternativeHomeDesign,
                                toggleHomeScreen: {
                                    if showAlternativeHomeDesign {
                                        showFrasesHome()
                                    } else {
                                        showAlternativeHome()
                                    }
                                }
                            )
                        }
                    }
                    .opacity(showAlternativeHomeDesign ? 1 : 0)
                    .scaleEffect(showAlternativeHomeDesign ? 1 : 0.985)
                    .offset(y: showAlternativeHomeDesign ? 0 : 10)
                    .blur(radius: showAlternativeHomeDesign ? 0 : 1.2)
                    .allowsHitTesting(showAlternativeHomeDesign)
                    .animation(homeTransitionAnimation, value: showAlternativeHomeDesign)
                    .zIndex(1)
                }
   
            }
            .onAppear {
                renderAlternativeHomeDesign = showAlternativeHomeDesign
                now = Date()
                agendaViewModel.load()

                // Refresca el gadget de metas cada vez que Home vuelve a aparecer.
                goalsGadgetRefreshID = UUID()

                guard !isRunningForPreviews else { return }
                
                
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
                    agendaViewModel.load()
                }
            }
            .onChange(of: showAgenda) { _, isPresented in
                if !isPresented {
                    agendaViewModel.load()
                }
            }
            
        }
        .sheet(isPresented: self.$showNovedades) {
            Novedades()
        }
        .sheet(isPresented: $showRitualMatutino) {
            MorningRitualMainView()
        }
        .sheet(item: $ritualNavigation.destination) { destination in
            switch destination {
            case .eveningReview:
                RitualEveningReviewEntryView()
            case .wellbeingDashboard:
                WellbeingDashboardView()
            }
        }
        .sheet(isPresented: $showAgenda) {
            AgendaMainView()
        }
        .sheet(isPresented: $showPresence) {
            PresenciaView()
        }
        .sheet(isPresented: $showPremium) {
            PurchaseView()
        }
        
    }
    

}//struct











//CustomTabView
struct TabButtonBar : View{

    @State      var showOptionView = false
    @Binding    var fontFrasesSize : CGFloat //Setting
    @Binding    var fontMenuSize : CGFloat //Setting$
    
    @Binding    var colorFrase : Color
    
    @Binding    var colorFondo_a : Color
    @Binding    var colorFondo_b : Color

    @ObservedObject var settingModel: SettingModel

    let isShowingAlternativeHome: Bool
    let toggleHomeScreen: () -> Void

    @AppStorage(AppCons.UD_setting_BottomBarShortcuts)
    private var storedShortcuts = BottomBarShortcutConfiguration.defaultStorageValue

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName))
    private var yorjPremium: Bool = false

    @State private var showPremium = false
    @State private var showEspacioCalmaFullScreen = false
    @State private var showCardioCoherenciaFullScreen = false

    private var shortcuts: [TipeViewOptionTab] {
        BottomBarShortcutConfiguration.shortcuts(from: storedShortcuts)
    }
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        VStack{
            HStack{
                ForEach(0..<5, id: \.self) { position in
                    if position == 2 {
                        Button {
                            showOptionView = true
                        } label: {
                            makeItemlabel(image: "house.circle.fill", isPrimary: true)
                        }
                        .accessibilityLabel("Inicio y opciones")
                    } else {
                        let shortcutIndex = position < 2 ? position : position - 1
                        shortcutButton(for: shortcuts[shortcutIndex])
                    }

                    if position < 4 {
                        Spacer(minLength: 0)
                    }
                }
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
            optionView(
                settingModel: settingModel,
                isShowingAlternativeHome: isShowingAlternativeHome,
                toggleHomeScreen: {
                    toggleHomeScreen()
                    showOptionView = false
                }
            )
               .presentationDetents([.height(280)])
               .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showPremium) {
            PurchaseView()
        }
        .fullScreenCover(isPresented: $showEspacioCalmaFullScreen) {
            EspacioCalmaView()
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCardioCoherenciaFullScreen) {
            CardioCoherenceWelcomeFlowView()
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func shortcutButton(for shortcut: TipeViewOptionTab) -> some View {
        if shortcut == .premium {
            Button {
                showPremium = true
            } label: {
                makeItemlabel(image: shortcut.systemImage)
            }
            .accessibilityLabel(shortcut.title)
        } else if shortcut.requiresPremium && !purchaseStatus && !yorjPremium {
            Button {
                showPremium = true
            } label: {
                makeItemlabel(image: shortcut.systemImage)
            }
            .accessibilityLabel(shortcut.title)
        } else if shortcut == .espacioCalma {
            Button {
                showEspacioCalmaFullScreen = true
            } label: {
                makeItemlabel(image: shortcut.systemImage)
            }
            .accessibilityLabel(shortcut.title)
        } else if shortcut == .cardioCoherencia {
            Button {
                showCardioCoherenciaFullScreen = true
            } label: {
                makeItemlabel(image: shortcut.systemImage)
            }
            .accessibilityLabel(shortcut.title)
        } else {
            NavigationLink {
                OptionAccessDestinationView(option: shortcut, settingModel: settingModel)
            } label: {
                makeItemlabel(image: shortcut.systemImage)
            }
            .accessibilityLabel(shortcut.title)
        }
    }
    
    //Create UI for reusability
    func makeItemlabel(image: String, isPrimary: Bool = false) -> some View {
        return Image(systemName: image)
            .renderingMode(.template)
            .font(.system(size: isPrimary ? 30 : 22, weight: isPrimary ? .semibold : .medium))
            .foregroundColor(Color.black.opacity(isPrimary ? 0.72 : 0.5))
            .padding(10)
            .scaleEffect(isPrimary ? 1.16 : 1.08)
            .shadow(color: Color.black.opacity(isPrimary ? 0.18 : 0.0), radius: 3, y: 1)
        
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



#if DEBUG
private struct HomePreviewHost: View {
    @StateObject private var settingModel = SettingModel()
    @StateObject private var modelTxt = TxtContentModel.shared
    @StateObject private var modelFrases = FrasesModel.shared
    @StateObject private var securityModel = SecurityModel.shared
    @StateObject private var clipBoardModel = ClipboardObserver()

    init() {
        UserDefaults.standard.set(false, forKey: "MostrarMetasEnHome")
        UserDefaults.standard.set(true, forKey: "Home_ShowMyDayButton")
        UserDefaults.standard.set(true, forKey: "Home_ShowAgendaButton")
        UserDefaults.standard.set(true, forKey: "Home_ShowPresenceButton")
        UserDefaults.standard.set("", forKey: "Home_RitualMatutino_HiddenDayKey")
        UserDefaults.standard.set(true, forKey: "purchaseStatus")
    }

    var body: some View {
        Home()
            .environmentObject(settingModel)
            .environmentObject(modelTxt)
            .environmentObject(modelFrases)
            .environmentObject(securityModel)
            .environmentObject(clipBoardModel)
            .environment(\.managedObjectContext, CoreDataController.shared.context)
    }
}

#Preview("Home") {
    HomePreviewHost()
}
#endif

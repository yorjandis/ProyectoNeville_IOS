//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var modelWatch = watchModel.shared
    @StateObject private var goalNotificationRouter = WatchGoalNotificationRouter.shared
    @AppStorage("AtajosiOS") private var atajoWatch: String = ""
    @State private var selectedTab: String = WatchScreen.inicio.rawValue
    @State private var screenOrder: [WatchScreen] = ScreenOrderStore.load()
    @State private var didSetInitialTab = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(availableScreenOrder) { screen in
                NavigationStack {
                    screenView(for: screen)
                        .ignoresSafeArea()
                }
                .tag(screen.rawValue)
            }

            NavigationStack {
                SettingsView(screenOrder: $screenOrder)
                    .ignoresSafeArea()
            }
            .tag(WatchScreen.ajustes.rawValue)
        }
        .tabViewStyle(.page)
        .onAppear {
            modelWatch.refreshPremiumAccessState()
            screenOrder = ScreenOrderStore.normalize(screenOrder)
            if !didSetInitialTab {
                selectedTab = WatchScreen.inicio.rawValue
                didSetInitialTab = true
            } else if !availableScreenOrder.map(\.rawValue).contains(selectedTab) && selectedTab != WatchScreen.ajustes.rawValue {
                selectedTab = WatchScreen.inicio.rawValue
            }
            handleShortcutNavigation(atajoWatch)
            handleGoalNotificationNavigation()
        }
        .onChange(of: screenOrder) { _, newValue in
            let normalized = ScreenOrderStore.normalize(newValue)
            if normalized != newValue {
                screenOrder = normalized
                return
            }
            ScreenOrderStore.save(normalized)
            if !availableScreenOrder.map(\.rawValue).contains(selectedTab) && selectedTab != WatchScreen.ajustes.rawValue {
                selectedTab = WatchScreen.inicio.rawValue
            }
        }
        .onChange(of: atajoWatch) { _, newValue in
            handleShortcutNavigation(newValue)
        }
        .onChange(of: goalNotificationRouter.shouldOpenGoals) { _, shouldOpen in
            guard shouldOpen else { return }
            handleGoalNotificationNavigation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            // Al abrir desde una notificación, onAppear puede consumir la ruta
            // antes de que scenePhase llegue a .active. No sobrescribir Metas
            // con Inicio en esa segunda fase del arranque.
            if selectedTab != WatchScreen.metas.rawValue {
                selectedTab = WatchScreen.inicio.rawValue
            }
            handleShortcutNavigation(atajoWatch)
            handleGoalNotificationNavigation()
        }
    }

    private var availableScreenOrder: [WatchScreen] {
        screenOrder
    }

    private func handleShortcutNavigation(_ shortcut: String) {
        switch shortcut {
        case "abrirDiario":
            selectedTab = WatchScreen.diario.rawValue
        case "abrirNotas":
            selectedTab = WatchScreen.notas.rawValue
        case "abrirRamdonConf":
            selectedTab = WatchScreen.frases.rawValue
        default:
            return  
        }

        atajoWatch = ""
    }

    private func handleGoalNotificationNavigation() {
        guard goalNotificationRouter.shouldOpenGoals else { return }
        selectedTab = WatchScreen.metas.rawValue
        goalNotificationRouter.consumeRequest()
    }

    @ViewBuilder
    private func screenView(for screen: WatchScreen) -> some View {
        switch screen {
        case .inicio:
            WatchHomeView(
                screens: availableScreenOrder.filter { $0 != .inicio } + [.ajustes],
                selectedTab: $selectedTab
            )
        case .frases:
            Frases()
        case .diario:
            DiarioView()
        case .notas:
            NotasView()
        case .agenda:
            if modelWatch.hasAgendaPremiumAccess {
                AgendaWatchView()
            } else {
                PremiumFeatureLockedView(title: "Agenda")
            }
        case .presencia:
            if modelWatch.hasPresencePremiumAccess {
                PresenceWatchView()
            } else {
                PremiumFeatureLockedView(title: "Presencia")
            }
        case .quickNote:
            QuickAddNotaByLocationView()
        case .metas:
            WatchGoalsView()
        case .ajustes:
            EmptyView()
        }
    }

    struct WatchHomeView: View {
        let screens: [WatchScreen]
        @Binding var selectedTab: String

        private var orbitScreens: [WatchScreen] {
            screens.filter { $0 != .ajustes }
        }

        var body: some View {
            ZStack {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.43, blue: 0.82),
                            Color(red: 0.24, green: 0.65, blue: 0.50),
                            Color(red: 0.14, green: 0.38, blue: 0.82)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.68, blue: 0.96).opacity(0.34),
                            Color.clear,
                            Color(red: 0.10, green: 0.54, blue: 0.88).opacity(0.28)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            Color(red: 0.36, green: 0.82, blue: 0.54).opacity(0.34),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 128
                    )
                }
                .saturation(0.94)
                .ignoresSafeArea()

                GeometryReader { proxy in
                    let size = min(proxy.size.width, proxy.size.height)
                    let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    let orbitRadius = max(62, size * 0.36)
                    let itemSize = max(58, min(68, size * 0.35))
                    let centerSize = max(32, min(38, size * 0.18))

                    ZStack {
                        ForEach(Array(orbitScreens.enumerated()), id: \.element.id) { index, screen in
                            let angle = angleForItem(at: index, total: orbitScreens.count)
                            let position = CGPoint(
                                x: center.x + cos(angle) * orbitRadius,
                                y: center.y + sin(angle) * orbitRadius
                            )

                            WatchHomeIconButton(
                                screen: screen,
                                size: itemSize,
                                selectedTab: $selectedTab
                            )
                            .position(position)
                        }

                        WatchHomeIconButton(
                            screen: .ajustes,
                            size: centerSize,
                            selectedTab: $selectedTab
                        )
                        .position(center)
                    }
                }
            }
        }

        private func angleForItem(at index: Int, total: Int) -> CGFloat {
            guard total > 0 else { return 0 }
            return (-CGFloat.pi / 2) + (2 * CGFloat.pi * CGFloat(index) / CGFloat(total))
        }
    }

    struct WatchHomeIconButton: View {
        let screen: WatchScreen
        let size: CGFloat
        @Binding var selectedTab: String

        var body: some View {
            Button {
                selectedTab = screen.rawValue
            } label: {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.94))
                        .overlay {
                            Circle()
                                .fill(screen.tintColor.opacity(0.10))
                        }
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.86), lineWidth: 1.2)
                        }
                        .overlay {
                            Circle()
                                .stroke(.black.opacity(0.30), lineWidth: 0.6)
                                .padding(1)
                        }
                        .shadow(color: .black.opacity(0.42), radius: 3, y: 2)

                    VStack(spacing: screen == .ajustes ? 0 : 3) {
                        Image(systemName: screen.symbolName)
                            .font(.system(
                                size: size * (screen == .ajustes ? 0.46 : 0.40),
                                weight: .heavy
                            ))
                            .foregroundStyle(screen.tintColor)

                        if screen != .ajustes {
                            Text(screen.shortName)
                                .font(.system(size: size * 0.15, weight: .regular))
                                .foregroundStyle(.black.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(width: size, height: size)
            }
            .buttonStyle(.plain)
        }
    }
    
   //Vistas
    struct DiarioView: View {
        
        @StateObject private var modelWatch = watchModel.shared
        
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""
        @State private var showActionsDialog = false
        @State private var diarioPendingActions: Diario?
        @State private var showDeleteConfirmation = false
        @State private var diarioPendingDelete: Diario?
        
        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Diario")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    
                    HStack{
                        Button{
                            Task{
                                modelWatch.getDiarioEntradas()
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        
                        
                        Spacer()
                        
                        Button{
                            self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }.buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                             AddDiario()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    
                    List{
                        ForEach(modelWatch.listDiario, id: \.id) {diario in
                            ZStack(alignment: .trailing) {
                                NavigationLink{
                                    ScrollView {
                                        Text(diario.content ?? "")
                                    }
                                }label: {
                                    VStack {
                                        HStack{
                                            Text(emotion(diario.emotion ?? ""))
                                                .font(.system(size: 28))
                                            Text(diario.title ?? "")
                                                .foregroundStyle(.black)
                                            Spacer()
                                        }
                                        Text((diario.fecha ?? Date.now).formatted(date: .long, time: .omitted))
                                            .font(.system(size: 10, weight: .medium, design: .serif)).foregroundStyle(.black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.trailing, 28)
                                }

                                Button {
                                    diarioPendingActions = diario
                                    showActionsDialog = true
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .foregroundStyle(.black)
                                        .font(.system(size: 14))
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 2)
                            }
                        }
                    }
                }
            }
            .alert(isPresented : $showAlert){
                Alert(title: Text("Diario"), message: Text(self.alertMessage))
            }
            .confirmationDialog("Opciones de entrada", isPresented: $showActionsDialog, titleVisibility: .visible) {
                Button("Borrar", role: .destructive) {
                    diarioPendingDelete = diarioPendingActions
                    diarioPendingActions = nil
                    showDeleteConfirmation = true
                }
                Button("Cancelar", role: .cancel) {
                    diarioPendingActions = nil
                }
            }
            .alert("Eliminar entrada", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {
                    diarioPendingDelete = nil
                }
                Button("Borrar", role: .destructive) {
                    guard let diario = diarioPendingDelete else { return }
                    if modelWatch.deleteDiarioEntry(diario) {
                        alertMessage = WatchL10n.exact("Entrada eliminada")
                    } else {
                        alertMessage = WatchL10n.exact("Error al eliminar la entrada")
                    }
                    diarioPendingDelete = nil
                    showAlert = true
                }
            } message: {
                Text("¿Seguro que deseas borrar esta entrada?")
            }
            .sheet(isPresented: $showSheetOptionsFilter) {
               FilterByDiarioView()
            }
            .task {
                modelWatch.getDiarioEntradas()
            }
        }
        
        //Aux: Devuelve el emoticono segun el texto: Para funciones de filtrado
        private func emotion(_ txt: String)->String{
            switch txt {
            case "neutral"      : "🙂"
            case "feliz"        : "😃"
            case "enfadado"     : "😤"
            case "desanimado"   : "😔"
            case "sorpresa"     : "😲"
            case "distraido"    : "🙄"
            default: ""
            }
        }
    }
    

    struct Frases : View {
        @StateObject private var modelWatch = watchModel.shared
        @State private var frase: String = ""
        
        @State private var showAlert: Bool = false

        var body: some View {
            ZStack{
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)

                VStack(alignment: .center){
                    Text("La Ley").bold()
                        .padding(.bottom, 10)

                    ScrollView{
                        Text(frase)
                            .italic()
                            .padding(.horizontal, 5)
                            .padding(.bottom, 8)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                    }
                    .onTapGesture {
                       cargarNuevaFrase()
                    }

                }
                .padding(.top, 10)
                .fontDesign(.serif)
                .font(.system(size: 20))
                .foregroundStyle(.black)
            }
            .onAppear {
                if frase.isEmpty {
                    cargarNuevaFrase()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: watchModel.phraseSourceDidChangeNotification)) { _ in
                cargarNuevaFrase()
            }
            .alert(isPresented: self.$showAlert){
                Alert(title: Text("Prueba"), message: Text("\(String(describing: modelWatch.yorjPremiumAccessValue))"))
            }
        }

        private func cargarNuevaFrase() {
            frase = modelWatch.getRandomFraseDisplayForHome()
        }
    }
    
    struct NotasView: View {
        @StateObject private var modelWatch = watchModel.shared
        @State var showSheetOptionsFilter = false
        @State var runTask = true //Para cargar la lista la primera vez que se muestra la vista
        @State var asyncIsWorking = false //Indica que hay una tarea async ejecutandose
        @State private var showAlert = false
        @State private var alertMessage = ""
        @State private var showActionsDialog = false
        @State private var notePendingActions: Notas?
        @State private var showDeleteConfirmation = false
        @State private var notePendingDelete: Notas?
        @State private var showEditSheet = false
        @State private var showCategorySheet = false
        @State private var notePendingEditID = ""
        @State private var editTitle = ""
        @State private var editCategoria = ""
        @State private var editNota = ""
        
        var body: some View {
            
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                
                VStack {
                    Text("Notas")
                        .fontDesign(.serif).foregroundStyle(.black).bold()
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, 5)
                    Divider()
                    HStack{
                        Button{
                            Task{
                                modelWatch.getNotas()
                            }
                        }label: {
                            Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        Button{
                           self.showSheetOptionsFilter = true
                        }label: {
                            Image(systemName: "text.magnifyingglass").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        } .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        NavigationLink{
                            AddNota()
                        }label: {
                            Image(systemName: "plus").foregroundColor(.black)
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Divider()
                    
                    
                    List(modelWatch.listNotas, id: \.id){ nota in
                        ZStack(alignment: .trailing) {
                            NavigationLink{
                                ScrollView {
                                    Text(nota.nota ?? "")
                                }
                            }label: {
                                Text(nota.title ?? "").fontDesign(.serif).foregroundStyle(.black)
                                    .frame(height: 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.trailing, 28)
                            }

                            Button {
                                notePendingActions = nota
                                showActionsDialog = true
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .foregroundStyle(.black)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 2)
                        }
                    }
                    .overlay(content: { //Muestra una barra de progreso si hay una tarea async ejecutándose...
                        if self.asyncIsWorking {
                            ProgressView()
                        }
                    })
                }
                
            }
            .sheet(isPresented: $showSheetOptionsFilter, content: {
                 FilterByNotaView()
            })
            
            .alert(isPresented: self.$showAlert) {
                Alert(title: Text("La Ley"), message: Text(self.alertMessage))
            }
            .confirmationDialog("Opciones de nota", isPresented: $showActionsDialog, titleVisibility: .visible) {
                Button("Editar") {
                    guard let nota = notePendingActions else { return }
                    notePendingEditID = nota.id ?? ""
                    editTitle = nota.title ?? ""
                    editCategoria = nota.value(forKey: "categoria") as? String ?? ""
                    editNota = nota.nota ?? ""
                    showEditSheet = true
                    notePendingActions = nil
                }
                Button("Cambiar categoría") {
                    guard let nota = notePendingActions else { return }
                    notePendingEditID = nota.id ?? ""
                    editTitle = nota.title ?? ""
                    editCategoria = nota.value(forKey: "categoria") as? String ?? ""
                    editNota = nota.nota ?? ""
                    showCategorySheet = true
                    notePendingActions = nil
                }
                Button("Borrar", role: .destructive) {
                    notePendingDelete = notePendingActions
                    notePendingActions = nil
                    showDeleteConfirmation = true
                }
                Button("Cancelar", role: .cancel) {
                    notePendingActions = nil
                }
            }
            .alert("Eliminar nota", isPresented: $showDeleteConfirmation) {
                Button("Cancelar", role: .cancel) {
                    notePendingDelete = nil
                }
                Button("Borrar", role: .destructive) {
                    guard let nota = notePendingDelete else { return }
                    if modelWatch.deleteNota(nota: nota) {
                        self.alertMessage = WatchL10n.exact("Nota eliminada")
                        modelWatch.getNotas()
                    } else {
                        self.alertMessage = WatchL10n.exact("Error al eliminar la nota")
                    }
                    notePendingDelete = nil
                    self.showAlert = true
                }
            } message: {
                Text("¿Seguro que deseas borrar esta nota?")
            }
            .sheet(isPresented: $showEditSheet) {
                EditNotaSheetView(
                    title: $editTitle,
                    categoria: $editCategoria,
                    nota: $editNota,
                    onCancel: {
                        showEditSheet = false
                    },
                    onSave: {
                        let updated = modelWatch.updateNota(
                            noteID: notePendingEditID,
                            title: editTitle,
                            nota: editNota,
                            categoria: editCategoria
                        )

                        if updated {
                            alertMessage = WatchL10n.exact("Nota actualizada")
                            showEditSheet = false
                        } else {
                            alertMessage = WatchL10n.exact("Error al actualizar la nota")
                        }
                        showAlert = true
                    }
                )
            }
            .sheet(isPresented: $showCategorySheet) {
                EditNotaCategorySheetView(
                    categoria: $editCategoria,
                    onCancel: {
                        showCategorySheet = false
                    },
                    onSave: {
                        let updated = modelWatch.updateNota(
                            noteID: notePendingEditID,
                            title: editTitle,
                            nota: editNota,
                            categoria: editCategoria
                        )

                        alertMessage = WatchL10n.exact(updated ? "Categoría actualizada" : "Error al actualizar la categoría")
                        showCategorySheet = false
                        showAlert = true
                    }
                )
            }
            .task {
                modelWatch.getNotas()
            }
        }
    }

    struct EditNotaSheetView: View {
        @Binding var title: String
        @Binding var categoria: String
        @Binding var nota: String
        let onCancel: () -> Void
        let onSave: () -> Void
        @StateObject private var modelWatch = watchModel.shared
        @State private var showCategoryOptions = false

        var body: some View {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    Text("Editar Nota")
                        .fontDesign(.serif)
                        .foregroundStyle(.black)
                        .bold()

                    TextField("Título", text: $title)
                    .frame(height: 38)

                    TextField("Nota", text: $nota)
                        .textFieldStyle(.plain)
                    .frame(height: 38)

                    TextField("Categoría", text: $categoria)
                    .frame(height: 38)

                    Button {
                        showCategoryOptions = true
                    } label: {
                        Label("Elegir categoría", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 8) {
                        Button("Cancelar") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)

                        Button("Guardar") {
                            onSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding(.horizontal, 10)
            }
            .confirmationDialog("Elegir categoría", isPresented: $showCategoryOptions, titleVisibility: .visible) {
                Button("Sin categoría") {
                    categoria = ""
                }
                ForEach(modelWatch.getNotaCategorias(), id: \.self) { category in
                    Button(category) {
                        categoria = category
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    struct EditNotaCategorySheetView: View {
        @Binding var categoria: String
        let onCancel: () -> Void
        let onSave: () -> Void
        @StateObject private var modelWatch = watchModel.shared
        @State private var showCategoryOptions = false

        var body: some View {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    Text("Categoría")
                        .fontDesign(.serif)
                        .foregroundStyle(.black)
                        .bold()

                    TextField("Categoría", text: $categoria)
                    .frame(height: 38)

                    Button {
                        showCategoryOptions = true
                    } label: {
                        Label("Elegir categoría", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)

                    HStack(spacing: 8) {
                        Button("Cancelar") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)

                        Button("Guardar") {
                            onSave()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding(.horizontal, 10)
            }
            .confirmationDialog("Elegir categoría", isPresented: $showCategoryOptions, titleVisibility: .visible) {
                Button("Sin categoría") {
                    categoria = ""
                }
                ForEach(modelWatch.getNotaCategorias(), id: \.self) { category in
                    Button(category) {
                        categoria = category
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    struct PremiumFeatureLockedView: View {
        let title: String

        var body: some View {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                VStack(spacing: 8) {
                    Text(WatchL10n.exact(title))
                        .fontDesign(.serif)
                        .foregroundStyle(.black)
                        .bold()
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.black)
                    Text("Requiere Premium")
                        .font(.footnote)
                        .foregroundStyle(.black)
                }
            }
        }
    }

    struct SettingsView: View {
        @Binding var screenOrder: [WatchScreen]
        @StateObject private var modelWatch = watchModel.shared
        @State private var selectedPhraseSource: WatchPhraseSource = watchModel.shared.selectedPhraseSource()
        @State private var showPremiumAlert = false

        var body: some View {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                VStack(spacing: 8) {
                    Text("Ajustes")
                        .fontDesign(.serif)
                        .foregroundStyle(.black)
                        .bold()
                    Text("Orden de pantallas")
                        .font(.footnote)
                        .foregroundStyle(.black)

                    List {
                        Section {
                            ForEach(WatchPhraseSource.allCases) { source in
                                Button {
                                    selectPhraseSource(source)
                                } label: {
                                    HStack {
                                        Image(systemName: selectedPhraseSource == source ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(.black)
                                        Text(source.displayName)
                                            .foregroundStyle(.black)
                                        Spacer()
                                        if source.requiresPremium && !modelWatch.hasAgendaPremiumAccess {
                                            Image(systemName: "lock.fill")
                                                .foregroundStyle(.black.opacity(0.72))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            Text("Frases")
                        }

                        ForEach(screenOrder) { screen in
                            Text(settingsDisplayName(for: screen))
                                .foregroundStyle(.black)
                        }
                        .onMove(perform: moveScreens)
                    }
                }
            }
            .onAppear {
                modelWatch.refreshPremiumAccessState()
                selectedPhraseSource = modelWatch.selectedPhraseSource()
            }
            .alert("Requiere Premium", isPresented: $showPremiumAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Las frases de otros autores necesitan acceso Premium.")
            }
        }

        private func moveScreens(from source: IndexSet, to destination: Int) {
            screenOrder.move(fromOffsets: source, toOffset: destination)
            screenOrder = ScreenOrderStore.normalize(screenOrder)
        }

        private func settingsDisplayName(for screen: WatchScreen) -> String {
            if screen == .agenda && !modelWatch.hasAgendaPremiumAccess {
                return "Agenda (Versión extendida)"
            }
            return screen.displayName
        }

        private func selectPhraseSource(_ source: WatchPhraseSource) {
            if modelWatch.setSelectedPhraseSource(source) {
                selectedPhraseSource = source
            } else {
                selectedPhraseSource = .neville
                showPremiumAlert = true
            }
        }
    }
}

struct WatchGoalsView: View {
    @StateObject private var store = WatchGoalUnitsStore.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.16, blue: 0.19),
                        Color(red: 0.08, green: 0.34, blue: 0.27),
                        Color(red: 0.16, green: 0.43, blue: 0.31)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(.mint)
                            Text("Metas")
                                .font(.headline.bold())
                            Spacer()
                            Button {
                                store.requestSnapshot()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.plain)
                            .offset(y: 3)
                            .accessibilityLabel("Actualizar Metas")
                        }

                        let cards = store.goalCards(at: timeline.date)
                        if cards.isEmpty {
                            emptyState()
                        } else {
                            ForEach(cards) { card in
                                goalCard(card, now: timeline.date)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
            }
            .onChange(of: timeline.date) { _, date in
                store.expireUnitsIfNeeded(at: date)
            }
        }
        .task {
            store.expireUnitsIfNeeded(at: Date())
            store.requestSnapshot()
        }
        .alert(
            "No se pudo fichar",
            isPresented: Binding(
                get: { store.lastError != nil },
                set: { if !$0 { store.lastError = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { store.lastError = nil }
        } message: {
            Text(store.lastError ?? "")
        }
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 35, weight: .light))
                .foregroundStyle(.mint)

            Text("Sin unidades pendientes")
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)

            Text("Las Metas activas aparecerán aquí cuando tengan unidades programadas.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func goalCard(_ card: WatchGoalCardItem, now: Date) -> some View {
        if let unit = card.displayedUnit {
            let isSending = store.pendingCompletionIDs.contains(unit.id)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(card.title)
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Spacer(minLength: 4)

                    if card.isAvailable {
                        Label("Disponible", systemImage: "bolt.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Label(remainingText(until: unit.startDate, now: now), systemImage: "clock")
                            .font(.system(size: 18, weight: .semibold).monospacedDigit())
                            .foregroundStyle(.mint)
                    }
                }

                HStack(spacing: 7) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(unit.unitName)
                            .font(.caption2.bold())
                            .lineLimit(1)
                        Text(unit.targetText)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 3)

                    if card.isAvailable {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Vence en")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.75))
                            Text(remainingText(until: unit.endDate, now: now))
                                .font(.system(size: 18, weight: .bold).monospacedDigit())
                                .foregroundStyle(.yellow)
                        }

                        Button {
                            store.complete(unit, now: now)
                        } label: {
                            Image(systemName: isSending ? "arrow.up" : "checkmark")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(card.isAvailable ? Color.green : Color.gray)
                                .frame(width: 30, height: 30)
                                .background(.white, in: Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(isSending || !unit.isAvailable(at: now))
                        .accessibilityLabel(isSending ? "Enviando" : "Marcar unidad realizada")
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.42))
                    }
                }
            }
            .padding(9)
            .background {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(
                        card.isAvailable
                            ? Color(red: 0.08, green: 0.52, blue: 0.25).opacity(0.94)
                            : Color.white.opacity(0.10)
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(
                        card.isAvailable ? Color.green.opacity(0.9) : Color.white.opacity(0.18),
                        lineWidth: card.isAvailable ? 1.4 : 0.8
                    )
            }
        }
    }

    private func remainingText(until date: Date, now: Date) -> String {
        let seconds = max(Int(date.timeIntervalSince(now)), 0)
        let days = seconds / 86_400
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        if days > 0 { return "\(days)d \((hours % 24))h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

enum WatchScreen: String, CaseIterable, Identifiable {
    case inicio
    case frases
    case diario
    case notas
    case agenda
    case presencia
    case quickNote
    case metas
    case ajustes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inicio: return WatchL10n.exact("Inicio")
        case .frases: return WatchL10n.exact("Frases")
        case .diario: return WatchL10n.exact("Diario")
        case .notas: return WatchL10n.exact("Notas")
        case .agenda: return WatchL10n.exact("Agenda")
        case .presencia: return WatchL10n.exact("Presencia")
        case .quickNote: return WatchL10n.exact("Acceso rápido")
        case .metas: return WatchL10n.exact("Metas")
        case .ajustes: return WatchL10n.exact("Ajustes")
        }
    }

    var shortName: String {
        switch self {
        case .agenda: return WatchL10n.exact("Agenda")
        case .quickNote: return WatchL10n.exact("Rápida")
        default: return displayName
        }
    }

    var symbolName: String {
        switch self {
        case .inicio: return "square.grid.2x2.fill"
        case .frases: return "quote.bubble.fill"
        case .diario: return "book.closed.fill"
        case .notas: return "note.text"
        case .agenda: return "calendar.badge.clock"
        case .presencia: return "sparkles"
        case .quickNote: return "location.fill.viewfinder"
        case .metas: return "target"
        case .ajustes: return "gearshape.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .inicio: return Color(red: 0.43, green: 0.42, blue: 0.58)
        case .frases: return Color(red: 0.66, green: 0.45, blue: 0.25)
        case .diario: return Color(red: 0.59, green: 0.35, blue: 0.43)
        case .notas: return Color(red: 0.32, green: 0.47, blue: 0.62)
        case .agenda: return Color(red: 0.50, green: 0.39, blue: 0.59)
        case .presencia: return Color(red: 0.28, green: 0.55, blue: 0.52)
        case .quickNote: return Color(red: 0.38, green: 0.55, blue: 0.36)
        case .metas: return Color(red: 0.20, green: 0.64, blue: 0.40)
        case .ajustes: return Color(red: 0.42, green: 0.45, blue: 0.47)
        }
    }

    var softColor: Color {
        tintColor.opacity(0.18)
    }

    static var reorderableCases: [WatchScreen] {
        [.inicio, .metas, .frases, .diario, .presencia, .agenda, .notas, .quickNote]
    }
}

private enum ScreenOrderStore {
    private static let key = "watchScreenOrder"
    private static let notesPresenceSwapMigrationKey = "watchScreenOrderNotesPresenceSwapV1"

    static func load() -> [WatchScreen] {
        let defaults = UserDefaults.standard
        guard let rawValues = UserDefaults.standard.array(forKey: key) as? [String] else {
            defaults.set(true, forKey: notesPresenceSwapMigrationKey)
            return WatchScreen.reorderableCases
        }

        let mapped = rawValues.compactMap(WatchScreen.init(rawValue:))
        var normalized = normalize(mapped)

        if !defaults.bool(forKey: notesPresenceSwapMigrationKey),
           let notesIndex = normalized.firstIndex(of: .notas),
           let presenceIndex = normalized.firstIndex(of: .presencia) {
            normalized.swapAt(notesIndex, presenceIndex)
            defaults.set(normalized.map(\.rawValue), forKey: key)
            defaults.set(true, forKey: notesPresenceSwapMigrationKey)
        }

        return normalized
    }

    static func save(_ order: [WatchScreen]) {
        let normalized = normalize(order)
        UserDefaults.standard.set(normalized.map(\.rawValue), forKey: key)
    }

    static func normalize(_ order: [WatchScreen]) -> [WatchScreen] {
        var unique: [WatchScreen] = []
        for screen in order where screen != .ajustes {
            if !unique.contains(screen) {
                unique.append(screen)
            }
        }

        if !unique.contains(.inicio) {
            unique.insert(.inicio, at: 0)
        }

        for screen in WatchScreen.reorderableCases where !unique.contains(screen) {
            unique.append(screen)
        }

        return unique
    }
}





#Preview {
    ContentView()
}

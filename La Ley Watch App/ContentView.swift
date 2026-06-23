//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var modelWatch = watchModel.shared
    @AppStorage("AtajosiOS") private var atajoWatch: String = ""
    @State private var selectedTab: String = WatchScreen.frases.rawValue
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
                selectedTab = availableScreenOrder.first?.rawValue ?? WatchScreen.frases.rawValue
                didSetInitialTab = true
            } else if !availableScreenOrder.map(\.rawValue).contains(selectedTab) && selectedTab != WatchScreen.ajustes.rawValue {
                selectedTab = availableScreenOrder.first?.rawValue ?? WatchScreen.frases.rawValue
            }
            handleShortcutNavigation(atajoWatch)
        }
        .onChange(of: screenOrder) { _, newValue in
            let normalized = ScreenOrderStore.normalize(newValue)
            if normalized != newValue {
                screenOrder = normalized
                return
            }
            ScreenOrderStore.save(normalized)
            if !availableScreenOrder.map(\.rawValue).contains(selectedTab) && selectedTab != WatchScreen.ajustes.rawValue {
                selectedTab = availableScreenOrder.first?.rawValue ?? WatchScreen.frases.rawValue
            }
        }
        .onChange(of: atajoWatch) { _, newValue in
            handleShortcutNavigation(newValue)
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

    @ViewBuilder
    private func screenView(for screen: WatchScreen) -> some View {
        switch screen {
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
        case .ajustes:
            EmptyView()
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
                        alertMessage = "Entrada eliminada"
                    } else {
                        alertMessage = "Error al eliminar entrada"
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
                        self.alertMessage = "Nota Eliminada"
                        modelWatch.getNotas()
                    } else {
                        self.alertMessage = "Error al Eliminar Nota"
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
                            alertMessage = "Nota actualizada"
                            showEditSheet = false
                        } else {
                            alertMessage = "Error al actualizar nota"
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

                        alertMessage = updated ? "Categoría actualizada" : "Error al actualizar categoría"
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

                    TextFieldLink("Título: \(title)", prompt: Text("Título")) { value in
                        title = value
                    }
                    .frame(height: 38)

                    TextField("Nota", text: $nota)
                        .textFieldStyle(.plain)
                    .frame(height: 38)

                    TextFieldLink("Categoría: \(categoria)", prompt: Text("Categoría")) { value in
                        categoria = value
                    }
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

                    TextFieldLink("Categoría: \(categoria)", prompt: Text("Categoría")) { value in
                        categoria = value
                    }
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
                    Text(title)
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
                        ForEach(screenOrder) { screen in
                            Text(screen.displayName)
                                .foregroundStyle(.black)
                        }
                        .onMove(perform: moveScreens)
                    }
                }
            }
        }

        private func moveScreens(from source: IndexSet, to destination: Int) {
            screenOrder.move(fromOffsets: source, toOffset: destination)
            screenOrder = ScreenOrderStore.normalize(screenOrder)
        }
    }
}

enum WatchScreen: String, CaseIterable, Identifiable {
    case frases
    case diario
    case notas
    case agenda
    case presencia
    case quickNote
    case ajustes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .frases: return "Frases"
        case .diario: return "Diario"
        case .notas: return "Notas"
        case .agenda: return "Agenda(Versión Extendida)"
        case .presencia: return "Presencia"
        case .quickNote: return "Acceso rápido"
        case .ajustes: return "Ajustes"
        }
    }

    static var reorderableCases: [WatchScreen] {
        [.frases, .diario, .notas, .agenda, .presencia, .quickNote]
    }
}

private enum ScreenOrderStore {
    private static let key = "watchScreenOrder"

    static func load() -> [WatchScreen] {
        guard let rawValues = UserDefaults.standard.array(forKey: key) as? [String] else {
            return WatchScreen.reorderableCases
        }

        let mapped = rawValues.compactMap(WatchScreen.init(rawValue:))
        return normalize(mapped)
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

        for screen in WatchScreen.reorderableCases where !unique.contains(screen) {
            unique.append(screen)
        }

        return unique
    }
}





#Preview {
    ContentView()
}

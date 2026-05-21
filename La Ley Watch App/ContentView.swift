//
//  ContentView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 31/1/24.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab: String = WatchScreen.frases.rawValue
    @State private var screenOrder: [WatchScreen] = ScreenOrderStore.load()
    @State private var didSetInitialTab = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(screenOrder) { screen in
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
            screenOrder = ScreenOrderStore.normalize(screenOrder)
            if !didSetInitialTab {
                selectedTab = screenOrder.first?.rawValue ?? WatchScreen.frases.rawValue
                didSetInitialTab = true
            } else if selectedTab == WatchScreen.ajustes.rawValue || !screenOrder.map(\.rawValue).contains(selectedTab) {
                selectedTab = screenOrder.first?.rawValue ?? WatchScreen.frases.rawValue
            }
        }
        .onChange(of: screenOrder) { _, newValue in
            let normalized = ScreenOrderStore.normalize(newValue)
            if normalized != newValue {
                screenOrder = normalized
                return
            }
            ScreenOrderStore.save(normalized)
            if selectedTab == WatchScreen.ajustes.rawValue || !normalized.map(\.rawValue).contains(selectedTab) {
                selectedTab = normalized.first?.rawValue ?? WatchScreen.frases.rawValue
            }
        }
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
        case .quickNote:
            QuickNoteLauncherView()
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
                            }
                        }
                    }
                }
            }
            .alert(isPresented : $showAlert){
                Alert(title: Text("Diario"), message: Text(self.alertMessage))
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
                        NavigationLink{
                            ScrollView {
                                Text(nota.nota ?? "")
                            }
                        }label: {
                            Text(nota.title ?? "").fontDesign(.serif).foregroundStyle(.black)
                                .frame(height: 10)
                        }
                        .swipeActions(edge: .trailing){
                            Button{
                                if modelWatch.deleteNota(nota: nota) {
                                    self.alertMessage = "Nota Eliminada"
                                    modelWatch.getNotas() //Actualiza los listados
                                }else{
                                    self.alertMessage = "Error al Eliminar Nota"
                                }
                                
                                self.showAlert = true
                            }label: {
                                Image(systemName: "trash")
                                    .tint(.red)
                            }
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
            .task {
                modelWatch.getNotas()
            }
        }
    }

    struct QuickNoteLauncherView: View {
        var body: some View {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()

                NavigationLink {
                    QuickAddNotaByLocationView()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 82, height: 82)
                        .background(.white.opacity(0.75))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
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
    case quickNote
    case ajustes

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .frases: return "Frases"
        case .diario: return "Diario"
        case .notas: return "Notas"
        case .quickNote: return "Acceso rápido"
        case .ajustes: return "Ajustes"
        }
    }

    static var reorderableCases: [WatchScreen] {
        [.frases, .diario, .notas, .quickNote]
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

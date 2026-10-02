
import SwiftUI
import CoreData


struct ContentView: View{
    
    @EnvironmentObject private var settingModel: SettingModel
    @Environment(\.scenePhase) private var scenePhase
    
    @State var showSheetDiario = false
    @State var showSheetNotas = false
    @State var showSheetMetas = false
    @State private var dashboardDestination: DashboardDestination?

    @AppStorage("purchaseStatus") private var purchaseStatus = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium = false
    
    
    
    
    
    //Codigo a cargar al inicio:
    init(){
        //Carga los valores de Setting para Userdefault si es la primera vez
        if UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize) == 0 {
            SettingModel().setValuesByDefault()
        } 
    }
    
    
    
    
    var body: some View{
        
        
        
        Home()
            .onOpenURL(perform: { url in
                if let destination = DashboardDestination(url: url) {
                    dashboardDestination = destination
                    return
                }

                switch url.description{
                    case AppCons.DeepLink_url_Diario : showSheetDiario = true
                    case AppCons.DeepLink_url_Notas :  showSheetNotas = true
                    case AppCons.DeepLink_url_Metas,
                         AppCons.DeepLink_url_Metas_AppStore,
                         "myapp://metas" : showSheetMetas = true
                    default : break
                }
            })
            .onAppear(perform: consumeControlCenterDestination)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    consumeControlCenterDestination()
                }
            }
            .sheet(isPresented: $showSheetDiario, content: {
                DiarioListView()
            })
            .sheet(isPresented: $showSheetNotas, content: {
                ListNotasViews()
            })
            .sheet(isPresented: $showSheetMetas, content: {
                GoalsListView()
            })
            .sheet(item: $dashboardDestination) { destination in
                dashboardView(for: destination)
            }
            .onReceive(NotificationCenter.default.publisher(for: .coreDataStoresDidLoad)) { _ in
                ConsciousDashboardSnapshotPublisher.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
                ConsciousDashboardSnapshotPublisher.refresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)) { _ in
                ConsciousDashboardSnapshotPublisher.refresh()
            }
            .onChange(of: purchaseStatus) { _, _ in
                ConsciousDashboardSnapshotPublisher.refresh()
            }
            .onChange(of: yorjPremium) { _, _ in
                ConsciousDashboardSnapshotPublisher.refresh()
            }
        
    }

    private func consumeControlCenterDestination() {
        let defaults = UserDefaults(suiteName: AppCons.AppGroupName)
        guard let rawValue = defaults?.string(forKey: "controlCenter.pendingDestination") else {
            return
        }

        defaults?.removeObject(forKey: "controlCenter.pendingDestination")
        dashboardDestination = DashboardDestination(rawValue: rawValue)
    }

    @ViewBuilder
    private func dashboardView(for destination: DashboardDestination) -> some View {
        if destination.requiresPremium && !(purchaseStatus || yorjPremium) {
            PremiumFeaturePreviewView(feature: destination.premiumFeature)
        } else {
            switch destination {
            case .crearNota:
                ControlCenterNoteEditorView()
            case .crearNotaVoz:
                ControlCenterVoiceNoteEditorView()
            case .crearDiario:
                NewDiarioEntryView()
            case .crearAgenda:
                AgendaMainView(presentsNewItemOnAppear: true)
            case .crearRecordatorio:
                ReminderEditorView(
                    reminderAEditar: nil,
                    titleAImportar: nil,
                    textoAImportar: nil,
                    onSave: {}
                )
            case .metas:
                GoalsListView()
            case .presencia:
                PresenciaView()
            case .agenda:
                AgendaMainView()
            case .diario:
                DiarioListView()
            case .notas:
                ListNotasViews()
            case .calma:
                EspacioCalmaView()
            case .ritualMatutino:
                MorningRitualMainView()
            case .cierre:
                RitualEveningReviewEntryView()
            case .coherencia:
                CardioCoherenceWelcomeFlowView()
            case .autores:
                ControlCenterAuthorsView()
            case .chatIA:
                ControlCenterAIChatView()
            case .centroSanador:
                CentroSanadorView(embeddedInNavigationStack: true)
            case .conferencias:
                TxtListView(typeOfContent: .conf, title: L10n.exact("Conferencias"))
            case .resumenSemanal:
                WeeklyReviewView()
            case .lectorEtiquetas:
                LectorEtiquetasView()
            }
        }
    }
    


}//struct

private enum DashboardDestination: String, Identifiable {
    case crearNota = "crear-nota"
    case crearNotaVoz = "crear-nota-voz"
    case crearDiario = "crear-diario"
    case crearAgenda = "crear-agenda"
    case crearRecordatorio = "crear-recordatorio"
    case metas
    case presencia
    case agenda
    case diario
    case notas
    case calma
    case ritualMatutino = "ritual-matutino"
    case cierre
    case coherencia
    case autores
    case chatIA = "chat-ia"
    case centroSanador = "centro-sanador"
    case conferencias
    case resumenSemanal = "resumen-semanal"
    case lectorEtiquetas = "lector-etiquetas"

    var id: String { rawValue }

    var requiresPremium: Bool {
        switch self {
        case .crearNota, .crearNotaVoz, .crearDiario, .diario, .notas, .autores,
             .conferencias:
            return false
        case .crearAgenda, .crearRecordatorio, .metas, .presencia, .agenda,
             .calma, .ritualMatutino, .cierre, .coherencia, .chatIA,
             .centroSanador, .resumenSemanal, .lectorEtiquetas:
            return true
        }
    }

    var premiumFeature: PremiumFeatureID {
        switch self {
        case .metas:
            .goals
        case .presencia:
            .consciousPresence
        case .crearAgenda, .agenda:
            .agenda
        case .crearRecordatorio:
            .smartReminders
        case .calma:
            .calmSpace
        case .ritualMatutino, .cierre:
            .consciousDailyCycle
        case .coherencia:
            .cardioCoherence
        case .chatIA:
            .integratedAI
        case .centroSanador:
            .healingCenter
        case .resumenSemanal:
            .weeklyReview
        case .lectorEtiquetas:
            .labelScanner
        case .crearNota, .crearNotaVoz, .crearDiario, .diario, .notas,
             .autores, .conferencias:
            .extendedContent
        }
    }

    init?(url: URL) {
        guard url.scheme == "laley", url.host == "dashboard" else { return nil }
        guard let tool = url.pathComponents.dropFirst().first else { return nil }
        self.init(rawValue: tool)
    }
}



private struct ControlCenterAuthorsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    NavigationLink {
                        NevilleAuthorView()
                    } label: {
                        authorRow("Neville Goddard", systemImage: "person.text.rectangle")
                    }

                    Divider()

                    NavigationLink {
                        BruceLiptonAuthorView()
                    } label: {
                        authorRow("Bruce Lipton", systemImage: "leaf")
                    }

                    Divider()

                    NavigationLink {
                        JoeDispenzaAuthorView()
                    } label: {
                        authorRow("Joe Dispenza", systemImage: "brain.head.profile")
                    }

                    Divider()

                    NavigationLink {
                        GreggBradenAuthorView()
                    } label: {
                        authorRow("Gregg Braden", systemImage: "globe.americas")
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.secondary.opacity(0.25), lineWidth: 1)
                }
                .padding()
            }
            .navigationTitle("Autores")
        }
    }

    private func authorRow(_ title: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .frame(width: 32)
                .foregroundStyle(.orange)

            Text(title)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct ControlCenterAIChatView: View {
    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            ChatView(textoACargar: nil)
        } else {
            ContentUnavailableView(
                "Chat IA no disponible",
                systemImage: "ellipsis.message",
                description: Text("Requiere iOS 26 o posterior.")
            )
        }
    }
}

private struct ControlCenterNoteEditorView: View {
    @StateObject private var notesModel = NotasModel()

    var body: some View {
        AddNotasView()
            .environmentObject(notesModel)
    }
}

private struct ControlCenterVoiceNoteEditorView: View {
    @StateObject private var notesModel = NotasModel()

    var body: some View {
        AddVoiceNoteView()
            .environmentObject(notesModel)
    }
}


#Preview {
    ContentView()
}

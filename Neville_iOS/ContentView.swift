
import SwiftUI
import CoreData


struct ContentView: View{
    
    @EnvironmentObject private var settingModel: SettingModel
    
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

    @ViewBuilder
    private func dashboardView(for destination: DashboardDestination) -> some View {
        if destination.requiresPremium && !(purchaseStatus || yorjPremium) {
            PremiumFeaturePreviewView(feature: destination.premiumFeature)
        } else {
            switch destination {
            case .metas:
                GoalsListView()
            case .presencia:
                PresenciaView()
            case .agenda:
                AgendaMainView()
            case .diario:
                DiarioListView()
            case .ritualMatutino:
                MorningRitualMainView()
            case .cierre:
                RitualEveningReviewEntryView()
            case .coherencia:
                CardioCoherenceWelcomeFlowView()
            }
        }
    }
    


}//struct

private enum DashboardDestination: String, Identifiable {
    case metas
    case presencia
    case agenda
    case diario
    case ritualMatutino = "ritual-matutino"
    case cierre
    case coherencia

    var id: String { rawValue }

    var requiresPremium: Bool {
        switch self {
        case .diario:
            return false
        case .metas, .presencia, .agenda, .ritualMatutino, .cierre, .coherencia:
            return true
        }
    }

    var premiumFeature: PremiumFeatureID {
        switch self {
        case .metas:
            .goals
        case .presencia:
            .consciousPresence
        case .agenda:
            .agenda
        case .ritualMatutino, .cierre:
            .consciousDailyCycle
        case .coherencia:
            .cardioCoherence
        case .diario:
            .extendedContent
        }
    }

    init?(url: URL) {
        guard url.scheme == "laley", url.host == "dashboard" else { return nil }
        guard let tool = url.pathComponents.dropFirst().first else { return nil }
        self.init(rawValue: tool)
    }
}




#Preview {
    ContentView()
}

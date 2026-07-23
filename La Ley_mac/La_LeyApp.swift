//
//  La_LeyApp.swift
//  La Ley
//
//  Created by Yorjandis PG on 6/11/25.
//

import SwiftUI
import UserNotifications

@main
struct La_LeyApp: App {
    
    @Environment(\.dismiss) var dismiss
    
    @StateObject private var settingModel = SettingModel()
    @StateObject private var frasesModel = FrasesModel.shared
    @StateObject private var txtcontentModel = TxtContentModel.shared
    @StateObject private var securityModel = SecurityModel.shared
    @StateObject private var clipBoardObserver : ClipboardObserver = ClipboardObserver() //Inicia la clase que observa cambios en el portapapales
    @StateObject private var purchaseManager : PurchaseManager = .shared //Para compras en la App

    
    private let persistentStore : CoreDataController =  CoreDataController.shared
    
    @AppStorage(AppCons.UD_setting_theme) var setting_theme  : Theme = .auto
    
    
    //Para Las funciones de Atajo:
    @AppStorage("AtajosMac" ) var AtajosMac: String = ""
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    
 
    
    @Environment(\.scenePhase) private var scenePhase
    
    //Para mostrar el contenido del mensaje de la notificación
    @StateObject private var messageCenter: NotificationMessageCenter = .shared
    

    init(){
        //Inicializar las notificaciones
        ReminderNotificationManager.shared.requestPermission()
        ReminderNotificationManager.shared.configureCategories()
        
        UNUserNotificationCenter.current().delegate = AppNotificationDelegate.shared //Para mostrar los recordatorios cuando la app esta en primer plano
        
     
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                
                NotificationBannerOverlay() //Banner de notificacioens para anunciar los recordatorios
                
                
                    NavigationStack{
                        ContentViewMac()
                            .environmentObject(settingModel)
                            .environmentObject(frasesModel)
                            .environmentObject(txtcontentModel)
                            .environmentObject(securityModel) //acceso seguro a las notas protegisas y al diario
                            .environmentObject(clipBoardObserver) //Inyectamos la clase que observa cambios en el portapapeles
                            .environment(\.managedObjectContext, persistentStore.context)
                            .applyTheme(setting_theme) //Aplicando la configuración de theme segun los valores en Ajustes
                            .onChange(of: self.AtajosMac, { _ , newValue in
                                //Procesa los Intents creados: Atajos de App Atajos y Siri
                                switch newValue{
                                case "abrirDiario":
                                    showWindow(for: DiarioListView(),
                                               environmentObjects: [self.settingModel],
                                               title: "Diario",
                                               size: .percentage(width: 0.50, height: 0.50),
                                               isModal: false)
                                case "abrirNotas":
                                    showWindow(for: ListNotasViews(),
                                               environmentObjects: [],
                                               title: "Notas",
                                               size: .percentage(width: 0.50, height: 0.50),
                                               isModal: false)
                                case "abrirRamdonConf":
                                    if let nombreTxt = self.txtcontentModel.getRandomConferencia(){
                                        showWindow(for: ContentTxtShowView(title: "Conferencias", nombreTxt: nombreTxt, type: .conf),
                                                   environmentObjects: [self.txtcontentModel, self.clipBoardObserver, self.settingModel],
                                                   title: "Conferencias",
                                                   size: .percentage(width: 0.50, height: 0.50),
                                                   isModal: false)
                                    }
                                default:
                                    return
                                }
                                
                                AtajosMac = "" //Resetea el flag
                                
                            })
                            
                            .onDisappear {
                                //Cerrando todas las ventanas hijas abiertas antes de salir
                                WindowManager.shared.closeAllChildren()
                            }
                            .onChange(of: scenePhase) { old, phase in
                                if phase == .active {
                                    ConsciousDashboardSnapshotPublisher.refresh()
                                    //Permite mostrar el contenido de la notificación
                                    messageCenter.loadPendingMessage()
                                
                                    if messageCenter.showMessage{
                                        showWindow(for:
                                            VStack {
                                            Text(messageCenter.message ?? "")
                                                .padding()
                                        },
                                        environmentObjects: [],
                                        title: "Mensaje de notificación",
                                                   size: AppCons.windows_size_content_small,
                                                   isModal: false){
                                            //Deshabilita que se muestre la notificación de nuevo
                                            Task{@MainActor in
                                             messageCenter.showMessageSet(state: false)
                                            }
                                            
                                        }
                                    }
                                    
                                }
                            }
                            .onOpenURL { url in
                                openDashboardTool(from: url)
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
                    }
            }
            .task {
                if CoreDataController.shared.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                    do {
                        try await persistentStore.cargarStores()
                    } catch {
                        msg("❌ Error al cargar Core Data en macOS: \(error.localizedDescription)")
                    }
                }

                ConsciousDashboardSnapshotPublisher.refresh()

                self.frasesModel.getAllFrases() //Carga las frases
                
                
                self.securityModel.canOpenDiario = false //Al iniciar la ventana se reinicia la variabe que da acceso al diario.
                self.purchaseStatus = self.purchaseManager.isPremium //Almacena al inicio el estado de la suscripción premium
                
                // ✅ Gestiona los duplicados en las frases:
                await frasesModel.GestionarDuplicados_en_Frases()
                
            }
               
        }
    }

    @MainActor
    private func openDashboardTool(from url: URL) {
        guard url.scheme == "laley", url.host == "dashboard",
              let tool = url.pathComponents.dropFirst().first else { return }

        let sharedDefaults = UserDefaults(suiteName: AppCons.AppGroupName)
        let hasPremium = purchaseStatus
            || (sharedDefaults?.bool(forKey: "purchaseStatus") ?? false)
            || (sharedDefaults?.bool(forKey: "yorjPremium") ?? false)

        if tool != "diario" && !hasPremium {
            showWindow(
                for: PurchaseView(),
                environmentObjects: [],
                title: "Premium",
                size: AppCons.windows_size_content,
                isModal: true
            )
            return
        }

        switch tool {
        case "metas":
            showWindow(for: GoalsListView(), environmentObjects: [], title: "Metas", size: AppCons.windows_size_content, isModal: false)
        case "agenda":
            showWindow(for: AgendaMainView(), environmentObjects: [], title: "Agenda", size: AppCons.windows_size_content, isModal: false)
        case "diario":
            showWindow(for: DiarioListView(), environmentObjects: [settingModel], title: "Diario", size: AppCons.windows_size_content, isModal: false)
        case "ritual-matutino":
            showWindow(for: MorningRitualMainView(), environmentObjects: [], title: "Ritual Matutino", size: AppCons.windows_size_content, isModal: false)
        case "cierre":
            showWindow(for: RitualEveningReviewEntryView(), environmentObjects: [], title: "Cierre consciente", size: AppCons.windows_size_content, isModal: false)
        case "presencia":
            showWindow(for: DashboardMacHandoffView(tool: "Presencia", symbol: "camera.macro"), environmentObjects: [], title: "Presencia", size: AppCons.windows_size_content_small, isModal: false)
        case "coherencia":
            showWindow(for: DashboardMacHandoffView(tool: "Coherencia", symbol: "waveform.path.ecg"), environmentObjects: [], title: "Coherencia", size: AppCons.windows_size_content_small, isModal: false)
        default:
            break
        }
    }
    
    
    
    
    
    
}

private struct DashboardMacHandoffView: View {
    let tool: String
    let symbol: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.cyan)
            Text(tool)
                .font(.title.bold())
            Text("Esta práctica guiada continúa en el iPhone. El panel del Mac seguirá mostrando el estado sincronizado.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
        }
        .padding(32)
    }
}

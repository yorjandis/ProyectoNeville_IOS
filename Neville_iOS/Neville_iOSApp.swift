//
//  Neville_iOSApp.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/9/23.
//

import SwiftUI
import AppIntents



@main
struct Neville_iOSApp: App {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var networkMonitor         = NetworkMonitor() //Helper Para conexiones de red
    @StateObject private var modelTxt               = TxtContentModel.shared
    @StateObject private var modelFrases            = FrasesModel.shared
    @StateObject private var settingModel           = SettingModel() //Inicializo el modelo para cargar valores de Setting y lo inyecto en el árbol de vistas
    @StateObject private var securityModel          = SecurityModel.shared //Almacena variables observables para
    @StateObject private var reflexModel            = ReflexModel.shared //Modelo Observable para Reflexiones
    @StateObject private var clipBoardModel         = ClipboardObserver() //Observa cambios en el portapapales
    @StateObject private var shareModel             = ShareModel()//Para manejar la extensión de compartir imagen/texto
    @StateObject private var purchaseModel          = PurchaseManager.shared //Para manejar Las comptras en aplicación
    
    
    
    private let persistentStore : CoreDataController =  CoreDataController.shared
    
    @AppStorage(AppCons.UD_setting_theme) var setting_theme  : Theme = .auto
    
    //Para Las funciones de Atajo:
    enum ItemAtajo : Identifiable{
       case abrirDiario, abrirNotas, abrirRandomConf
        var id : String {String(describing: self)}
    }
    @State var itemAtajo : ItemAtajo? = nil //Representa un item de Atajo (conveniente para usar un solo sheet)
    @AppStorage("AtajosiOS" ) var AtajosiOS: String = ""
    
    //Almacena el estado de compra en la App: suscripción premium anual: 12.99
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false

    //Para mostrar el contenido del mensaje de la notificación
    @StateObject private var messageCenter: NotificationMessageCenter = .shared
    
     init(){
         //Inicializar las notificaciones
         ReminderNotificationManager.shared.requestPermission()
         ReminderNotificationManager.shared.configureCategories()
        
         UNUserNotificationCenter.current().delegate = AppNotificationDelegate.shared //Para mostrar los recordatorios cuando la app esta en primer plano
     }
     
   
    //Claves de los ficheros
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"
    

    var body: some Scene {
        WindowGroup {
                ZStack{
                    
                    NotificationBannerOverlay() //Banner de notificacioens para anunciar los recordatorios
                    
                    //No inicia la app hasta que se haya cargado CoreData
                        NavigationStack{
                        ContentView()
                            .environmentObject(settingModel)
                            .environmentObject(networkMonitor)
                            .environmentObject(modelTxt)
                            .environmentObject(modelFrases)
                            .environmentObject(securityModel) //Almacena variables observables para acceso seguro: Notas protegidas y Diario
                            .environmentObject(reflexModel)
                            .environmentObject(clipBoardModel)
                            .environment(\.managedObjectContext, persistentStore.context)
                            .applyTheme(self.setting_theme) //Aplicando el theme según los valores en Ajustes
                            //Funciones de Atajo:
                            .onChange(of: self.AtajosiOS) { _ , newValue in
                                
                                guard !newValue.isEmpty else { return }
                                
                                switch newValue {
                                    case "abrirDiario":
                                        itemAtajo = .abrirDiario
                                    case "abrirNotas":
                                        itemAtajo = .abrirNotas
                                    case "abrirRamdonConf":
                                        itemAtajo = .abrirRandomConf
                                    default:
                                        itemAtajo = nil
                                    }

                                AtajosiOS = "" // limpiar después
                                   
                            }
                            .onChange(of: scenePhase) {old,  phase in
                                //almacenar el mensaje de la notificación
                                if phase == .active {
                                    messageCenter.loadPendingMessage()
                                    ReminderStore.shared.invalidateExpiredDateReminders()
                                }
                            }
                            .sheet(item: self.$itemAtajo) { item in
                                switch  item{
                                case .abrirDiario:
                                        DiarioListView()
                                            .environmentObject(self.settingModel)
                                case .abrirNotas:
                                        ListNotasViews()
                                            .environmentObject(self.settingModel)
                                case .abrirRandomConf:
                                        if let txtConf = self.modelTxt.getRandomConferencia(){
                                            ContentTxtShowView(title: "Conferencia", nombreTxt: txtConf, type: .conf, blocks: [
                                                ContentBlock(content: .text(UtilFuncs.FileRead("conf_\(txtConf)")))
                                            ])
                                                .environmentObject(self.modelTxt)
                                                .environmentObject(self.clipBoardModel)
                                                .environmentObject(self.settingModel)
                                        }else {
                                            Text("No se ha podido obtener una conferencia. Pruebe de nuevo")
                                        }
                                    }
                            }
                            .sheet(isPresented: $messageCenter.showMessage) {
                                //Mostrar el contenido de la notificación actual de los recordatorios
                                VStack {
                                    Text(messageCenter.message ?? "")
                                        .padding()
                                }
                                .presentationDetents([.medium])
                            }
                    }
                    
  
            }
                .task {
                    //Cargar la Base Datos de Core Data: Si aun no se ha cargado la BD... Porque es posible que se haya cargado en la ejecución de los Intent
                    if CoreDataController.shared.persistentContainer.persistentStoreCoordinator.persistentStores.isEmpty {
                        do{
                            try await persistentStore.cargarStores()
                            modelTxt.getAllFileTxtOfType(type: .conf)   // Carga el listado de conferencias
                            modelFrases.getAllFrases() //Carga el Listado de Frases
                            
                            // ✅ Gestiona los duplicados en las frases:
                            await modelFrases.GestionarDuplicados_en_Frases()
                            
                            
                        }catch{
                            msg("❌ Error al cargar Core Data 222: \(error.localizedDescription)")
                        }
                    }
                    
                    
                    //Maneja los item que se han procesado en el menú compartir del SO: iOS
                    await handleShareItem()
                }
            
        }
        
    }
    
    
    //Maneja la información que entra por el menú de compartir:
    func handleShareItem() async{
        
        guard let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group") else {
            msg("❌ No se pudo acceder al App Group")
            return
        }
      
            //Manejando el texto en Notas
            if let texto = defaults.string(forKey: self.keyNotaShareText){
                
                //Detectando si tiene el formato de importación de Notas:
                
                if let textImportacionNota = QRModel.detectFormatImportNota(text: texto){
                    _ = NotasModel().addNote(nota: textImportacionNota.1.1, title: textImportacionNota.1.0, isFav: textImportacionNota.1.2)
                }else{
                    _ = NotasModel().addNote(nota: texto, title: "Nota desde Menú Compartir")
                }

                // Limpiar el valor para la próxima vez
                defaults.removeObject(forKey: self.keyNotaShareText)
            }
            
            //Copiando el texto en Frases
            if let texto = defaults.string(forKey: self.keyFraseShareText){
                
                //Detectando formato de importación de Frases
                if let textImportado = QRModel.detectFormatImportFrase(frase: texto){
                    _ = FrasesModel.shared.AddFrase(frase: textImportado.0, autor: textImportado.1, nota: textImportado.2, isfav: textImportado.3)
                }else{
                    _ = FrasesModel.shared.AddFrase(frase: texto, autor: "personal")
                }

                // Limpiar el valor para la próxima vez
                defaults.removeObject(forKey: self.keyFraseShareText)
            }
    }

}

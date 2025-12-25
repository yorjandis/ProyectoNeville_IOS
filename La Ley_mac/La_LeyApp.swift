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
    
//Manejo de las notificaciones de los recordatorios:
    let notificationDelegate = ReminderNotificationDelegate() //Delegado para manejar las notificaciones de los recordatorios
    
    //Mostrar una vista con el contenido de la notificación de recordaorio
    @AppStorage("pendingReminderMessage") private var pendingReminderMessage: String?
    
    

    init(){
        //Inicializar las notificaciones
        ReminderNotificationManager.shared.requestPermission()
        ReminderNotificationManager.shared.configureCategories()
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        /*
        //Solo para macOS: esto resetea los valores de UserDefault en cada lanzamiento de la app, pero solo dentro del entorno de desarrollo.
        #if DEBUG
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        UserDefaults.standard.synchronize()
        #endif
         */
    }

    
    var body: some Scene {
        WindowGroup {
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
                    .task {
                        self.securityModel.canOpenDiario = false //Al iniciar la ventana se reinicia la variabe que da acceso al diario.
                        self.purchaseStatus = self.purchaseManager.isPremium //Almacena al inicio el estado de la suscripción premium
                    }
                    .onDisappear {
                        //Cerrando todas las ventanas hijas abiertas antes de salir
                        WindowManager.shared.closeAllChildren()
                    }
                    .onAppear{
                        print("123")
                        //manejar las notificaciones de recordatorios:
                        if let pendingReminderMessage {
                            print("456")
                            showWindow(for:
                                        VStack{Text(pendingReminderMessage).padding()
                            }.padding(),
                                       environmentObjects: [],
                                       title: "Mensaje de Notificaciones",
                                       size: AppCons.windows_size_content_small,
                                       isModal: false) {
                                Task{ @MainActor in
                                    self.pendingReminderMessage = nil // limpiar
                                }
                                
                            }
                            
                        }
                       
                    }
        }
    }
    
    
    
    
    
    
}



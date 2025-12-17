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
    @StateObject private var shareModel             =  ShareModel()//Para manejar la extensión de compartir imagen/texto
    

  private let persistentStore : CoreDataController =  CoreDataController.shared
    
    @AppStorage(AppCons.UD_setting_theme) var setting_theme  : Theme = .auto
    
    //Para Las funciones de Atajo:
    enum ItemAtajo : Identifiable{
       case abrirDiario, abrirNotas, abrirRandomConf
        var id : String {String(describing: self)}
    }
    @State var itemAtajo : ItemAtajo? = nil //Representa un item de Atajo (conveniente para usar un solo sheet)
    @AppStorage("AtajosiOS" ) var AtajosiOS: String = ""

    
    /*
     init(){
         //Solo para macOS: esto resetea los valores de UserDefault en cada lanzamiento de la app, pero solo dentro del entorno de desarrollo.
         #if DEBUG
         UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
         UserDefaults.standard.synchronize()
         #endif
     }
     */
   
    //Claves de los ficheros
    let keyNotaShareText    = "notaShareText"
    let keyFraseShareText   = "fraseShareText"

    var body: some Scene {
        WindowGroup {
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
                    .task {
                        modelTxt.getAllFileTxtOfType(type: .conf)   // Carga el listado de conferencias
                        modelFrases.getAllFrases() 
                    }
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
                                    ContentTxtShowView(title: "Conferencia", nombreTxt: txtConf, type: .conf)
                                        .environmentObject(self.modelTxt)
                                        .environmentObject(self.clipBoardModel)
                                        .environmentObject(self.settingModel)
                                }else {
                                    Text("No se ha podido obtener una conferencia. Pruebe de nuevo")
                                }
                            }
                    }
                    
                
            }
            .task {
                //Maneja los item que se han procesado en el menú compartir del SO: iOS
                await handleShareItem()
            }
        }
    }
    
    
    func handleShareItem() async{
        
        if let defaults = UserDefaults(suiteName: "group.com.ypg.nev.group"){
            
            //Manejando el texto en Notas
            if let texto = defaults.string(forKey: self.keyNotaShareText){
                
                //Detectando si tiene el formato de imprtación de Notas:
                
                if let textImportacionNota = QRModel.detectFormatImportNota(text: texto){
                    _ = NotasModel().addNote(nota: textImportacionNota.1.1, title: textImportacionNota.1.0, isFav: textImportacionNota.1.2)
                }else{
                    _ = NotasModel().addNote(nota: texto, title: "Nota desde QR")
                }

                // Limpiar el valor para la próxima vez
                defaults.removeObject(forKey: self.keyNotaShareText)
            }
            
            //Copiando el texto en Frases
            if let texto = defaults.string(forKey: self.keyFraseShareText){
                
                //Detectando formato de importación de Frases
                if let textImportado = QRModel.detectFormatImportFrase(text: texto){
                    _ = FrasesModel.shared.AddFrase(frase: textImportado.1)
                }else{
                    _ = FrasesModel.shared.AddFrase(frase: texto)
                }

                // Limpiar el valor para la próxima vez
                defaults.removeObject(forKey: self.keyFraseShareText)
            }

        }

    }
  
    
    
}

//
//  WatchConectivityModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 31/1/24.
//Shared: WatchOS/iOS targets.

import SwiftUI
import WatchConnectivity

class WatchConectivityModel : NSObject, ObservableObject, WCSessionDelegate {
    
    let session = WCSession.default
    
    static let shared = WatchConectivityModel() //Singleton
    
    @Published var isSending    = false //Marcar estado de: trasmitiendo datos
    @Published var isReachable  = false //true para saber si la contraparte es accesible
    @Published var frase_link   = "" //link de la conferencia a abrir
    @Published var nota_link    = "" //link de la conferencia a abrir
    @Published var conf_link    = "" //link de la conferencia a abrir
    @Published var diario_link  = "" //link de la conferencia a abrir
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    
    
    
    //Se ha completado la activación de la WCSession:
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession activado: \(activationState.rawValue)")
        DispatchQueue.main.async {
            self.isReachable = true //Actualiza el estado de la variable
        }
    }
    
    //Ha cambiado el estado de alcance de la contraparte
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    //Solo para iOS:
    
    #if os(iOS)
        
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession esta inactivo:\(session.activationState.rawValue)")
    }
    
        //La sesion se ha desactivado: incapaz de recibir mensajes del reloj
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession se ha desactivado: \(session.activationState.rawValue)")
        session.activate() //Activar de nuevo la sesión
    }
    
        //llamado cuando cambia el estado de la sesión en el reloj
    func sessionWatchStateDidChange(_ session: WCSession) {
        print("WCSession en el reloj ha cambiado: \(session.activationState.rawValue)")
    }
    #endif
    
    
    //Yorj: esta función se llamara cuando se reciba algún mensaje de la contraparte. Como este archivo es compartido entre targets se debe poner clausulas de código para iOS y watchOS, respectivamente:
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        //Procesar los mensajes entrantes en iOS
        #if os(iOS)
        DispatchQueue.main.async{
            //Si la app esta activa en ese momento se abre la view correspondiente
            if UIApplication.shared.applicationState == .active {
                if let conf_link = message[Info.conf_link.txt] { //Abrir conferencia en la app
                   self.conf_link = conf_link as? String ?? ""
                }
                if let frase_link = message[Info.frase_link.txt] { //Abrir frase en la app
                    self.frase_link = frase_link as? String ?? ""
                }
                if let nota_link = message[Info.nota_link.txt] { //Abrir notas en la app
                    self.nota_link = nota_link as? String ?? ""
                }
                if let diario_link = message[Info.diario_link.txt] { //Abrir el diario en la app
                   self.diario_link = diario_link as? String ?? ""
                }
            }else{ //Si la app esta en backGround/inactiva: Crear una notificación push local y se pasa la info en un UserInfo dict:
                
                let content = UNMutableNotificationContent()
                content.title = "La Ley"
                if let conf_link = message[Info.conf_link.txt] {
                    content.body = "Abrir Conferencia"
                    content.userInfo = ["conf_link": conf_link]
                }
                if let frase_link = message[Info.frase_link.txt] {
                    content.body = "Abrir Frase"
                    content.userInfo = ["frase_link": frase_link]
                }
                if let nota_link = message[Info.nota_link.txt] {
                    content.body = "Abrir Nota"
                    content.userInfo = ["nota_link": nota_link]
                }
                if let diario_link = message[Info.diario_link.txt] {
                    content.body = "Abrir Diario"
                    content.userInfo = ["diario_link": diario_link]
                }
                content.sound = .default
                
                let resquest = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
                
                UNUserNotificationCenter.current().add(resquest) { error in
                    print(error?.localizedDescription ?? "Error en la notificación Push")
                }
            }    
        }
        
        
        #endif
        
        
    }
 
}

//Nombre de notificación personalizado
extension Notification.Name {
    static let infoSend = Notification.Name("InfoSend")
}

fileprivate enum Info: String{
    case frase_link, conf_link, nota_link, diario_link
    var txt : String{
        self.rawValue
    }
    
}



//
//  NetModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 31/10/23.
//

import Foundation
import Network



/// Se encarga de monitorizar la conección a internet

@MainActor final class NetworkMonitor: ObservableObject {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    
    @Published var isConnected = false
    
    init() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            // Usamos Task para asegurar que la actualización se haga en el hilo principal
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}


//Chequea si existe una nueva versión en la play store
//No bloquea el hilo principal de la app

struct CheckAppStatus{
    //Tipos de error
    enum TError: Error {
        case invalidResponse, invalidBundleInfo
    }


    //Función asíncrona para detectar un cambio de versión de la App publicada
    /// - Parameter  action closure que se devolverá con un valor Bool que indica si existe una nueva versión (true si existe una nueva versión)
    /// - Returns devuelve un closure con un valor booleano que indica si existe una nueva versión: true si existe, false de otro modo.

    func getAppNewVersion(action: @escaping @Sendable (Bool)->()) async throws ->Void{
        
        enum TError: Error {
                case errorLocalizado
            }
        
        
        let urlApp = "https://apps.apple.com/es/app/la-ley/id6472626696"
        let stringSeparate = "new__latest__version" //Esta cadena identificará el texto de la versión en el texto de la web. Apple la puede cambiar
        
        //Obteniendo la versión local instalada
                guard let info = Bundle.main.infoDictionary,
                      let localVersion = info["CFBundleShortVersionString"] as? String else {throw TError.errorLocalizado}
        
      
        
        //Chequeando la url del sitio web:
        guard let url = URL(string: urlApp) else {throw TError.errorLocalizado}
        
        //Obtener la versión remota en la App Store:
        do {
            let webContent = try String(contentsOf: url, encoding: .utf8) //Obtiene el contenido de la web
            let arrayOfInfo = webContent.components(separatedBy: "\n") //Obtiene un arreglo del contenido en líneas
            if !arrayOfInfo.isEmpty {
                for i in arrayOfInfo {
                    //Comprobando si la linea contiene la frase clave que indica que contiene la versión
                    if i.contains(stringSeparate){
                        let lineaClave = i.components(separatedBy: stringSeparate)
                        
                      
                        let remoteVersion = lineaClave[1].digitos //digitos es una extensión de String que obtiene los dígitos de una cadena
                        
                        
                        //Devuelve el closure con la evaluación: true si las cadenas son distintas
                        return action(remoteVersion != localVersion)
                        
                    }
                }
            }else{ //Si se obtiene un arreglo vacio se devuelve error
                throw TError.errorLocalizado
            }
            
        }catch{
            throw TError.errorLocalizado
        }
        
        
    }
 

}




//(No usado, fines de prueba)Esta función determina si dos versiones de programa son distintas
///Incluye los casos en los cuales los números de versiones tiene distinta longitud
/*
 Ejemplo de uso:
 checkVersion("1.2.3", "1.2.3") // → .orderedSame
 checkVersion("1.2.4", "1.2.3") // → .orderedDescending (remoto mayor)
 checkVersion("1.2", "1.2.5")   // → .orderedAscending (local mayor)
 checkVersion("2.0", "1.9.9")   // → .orderedDescending
 checkVersion("1.0.1", "1")     // → .orderedDescending
 */
func checkVersion(_ remoteVersion: String, _ localVersion: String) -> ComparisonResult {
    let remoteParts = remoteVersion.split(separator: ".").compactMap { Int($0) }
    let localParts = localVersion.split(separator: ".").compactMap { Int($0) }
    
    let maxCount = max(remoteParts.count, localParts.count)
    
    for i in 0..<maxCount {
        let remote = i < remoteParts.count ? remoteParts[i] : 0
        let local = i < localParts.count ? localParts[i] : 0
        
        if remote > local { return .orderedDescending }   // remoto es mayor
        if remote < local { return .orderedAscending }    // local es mayor
    }
    
    return .orderedSame  // son iguales
}







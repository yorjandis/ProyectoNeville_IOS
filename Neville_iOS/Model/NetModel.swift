//
//  NetModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 31/10/23.
//

import Foundation
import Network



/// Se encarga de monitorizar la conección a internet
class NetworkMonitor: ObservableObject {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            Task {
                await MainActor.run {
                    self.objectWillChange.send()
                }
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

    ///Chequea si existe una nueva versión de la App
    /// - Returns - Devuelve un closure para manejar el resultado: Una tupla donde se devuelve bool que si es true indica que hay que actualizar (version local y remota distinta) si es false indica que las versiones local y remota son iguales. El segundo elemento de la tupla es error que de NO ser nil indica que se ha producido un error.
    func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
        
        //Obtener la info de la versión actual instalada
        guard let info = Bundle.main.infoDictionary,
              let localVersion = info["CFBundleShortVersionString"] as? String,
              let identifier = info["CFBundleIdentifier"] as? String,
              //url que será chequeada para obtener la información remota
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {throw TError.invalidBundleInfo}
 
        //Iniciando la tarea asíncrona para obtener la versión remota de la App
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            do {
                if let error = error { throw error } //Lanza un error y sale
                
                guard let data = data else { throw TError.invalidResponse } //Lanza un error y sale
                
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]

                guard let result = (json?["results"] as? [Any])?.first as? [String: Any],
                      let remoteVersion = result["version"] as? String else {throw TError.invalidResponse}
            
                // Completando el closure que será devuelto
                
               //print(localVersion)
               //print(remoteVersion)
                completion(remoteVersion != localVersion, nil)
                
            } catch {
                completion(nil, error)
            }
        }
        
        //LLegado a este punto, si no ha devuelto nada se resume la tarea
        task.resume()
        //Devuelve el valor de retorno
        return task
    }
    
   
   /*
    //Ejemplo
 try? isUpdateAvailable { (update, error) in
    if let error = error {
        print(error)
    } else if let update = update {
    //Si update es true indica que las versiones local y remota son distintas y hay que actualizar
        if update {
        //Hay que actualizar
    }else{
        //No hay que actualizar
    }
    }
}
    */

}


struct testYorj{
    
    //Función que ejecuta un closure a los segundos indicados en los parámetros. Asíncrona
    func executeLater(offsetTime : Int, _ action : @escaping @Sendable ()->Void)->Void{
        let dispatchAfter = DispatchTimeInterval.seconds(offsetTime)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + dispatchAfter, execute: action)
    }
    
    
}

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
@available(iOS 17.0, *)
@MainActor
struct CheckAppStatus{
    //Función asíncrona para detectar un cambio de versión de la App publicada
    /// - Returns devuelve un valor booleano si exiete una nueva actualziación: true si existe, false de otro modo.
   static func getAppNewVersion() async -> Bool {
        // 1️⃣ Obtener el identificador del bundle actual
        guard let bundleID = Bundle.main.bundleIdentifier else {
            print("❌ No se encontró el bundle identifier")
            return false
        }
        
        // 2️⃣ Construir la URL de consulta a la API de iTunes
        // Ejemplo: https://itunes.apple.com/lookup?bundleId=com.apple.Pages
        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
           // print("❌ URL inválida")
            return false
        }

        do {
            // 3️⃣ Descargar datos desde la API
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 4️⃣ Decodificar JSON de respuesta
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let results = json["results"] as? [[String: Any]],
                let appInfo = results.first,
                let appStoreVersion = appInfo["version"] as? String
            else {
               // print("❌ No se pudo obtener la versión del App Store")
                return false
            }

            // 5️⃣ Obtener la versión instalada
            guard
                let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else {
                print("❌ No se pudo leer la versión local")
                return false
            }

            // 6️⃣ Comparar versiones
            let isNew = isVersion(appStoreVersion, greaterThan: localVersion)
           // print("📱 Versión local: \(localVersion) | 🏪 App Store: \(appStoreVersion) | Nueva: \(isNew)")
            return isNew

        } catch {
           // print("⚠️ Error al consultar App Store:", error)
            return false
        }
       
       
       // 🔧 Función auxiliar para comparar versiones (ej. "1.2.10" > "1.2.3")
        func isVersion(_ version1: String, greaterThan version2: String) -> Bool {
           let v1 = version1.split(separator: ".").compactMap { Int($0) }
           let v2 = version2.split(separator: ".").compactMap { Int($0) }
           let maxCount = max(v1.count, v2.count)
           
           for i in 0..<maxCount {
               let num1 = i < v1.count ? v1[i] : 0
               let num2 = i < v2.count ? v2[i] : 0
               if num1 != num2 {
                   return num1 > num2
               }
           }
           return false
       }
       
    }

   
     

}







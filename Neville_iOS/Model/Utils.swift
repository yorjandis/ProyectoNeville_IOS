//
//  Utils.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//Esto es un ejemplo

import Foundation
import SwiftUI
import LocalAuthentication





struct UtilFuncs{
    ///ReadFileToArray : Devuelve un array conteniendo todas las líneas de texto de un fichero txt
    /// - Parameter - filename: el nombre del fichero sin la extension, para ser procesado
    /// - Returns - Devuelve un arreglo de String. cada línea del fichero es una item del arreglo
    static func FileReadToArray(_ filename: String) -> [String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let fileContents = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }

        // Separa por líneas y elimina las vacías o con solo espacios
        let result = fileContents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // limpia cada línea
            .filter { !$0.isEmpty } // elimina vacías

        return result
    }
    
    ///Lee el contenido de un fichero Txt, ubicado en el bundle de la app, y lo devuelve como String
    /// - Parameter - fileName: el nombre del fichero, sin la extensión
    ///  - Returns - Devuelve el contenido del fichero
    static func FileRead(_ fileName: String) -> String {
        var result = ""
        let temp = "\(fileName.lowercased())"
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            if let fileContents = try? String(contentsOf: gg, encoding: .utf8) {
                result = fileContents //.replacingOccurrences(of: "\n", with: "<br>") //Deshabilitados la conversión de \n a <br> porque ya no utilizamos RichtEdit para vosualizar
            }
        }
        return result
    }
    
    #if os(macOS)
    // Ejemplo de contenedor; la función está fuera de cualquier View y es estática.
        static func autent(HabilitarContenido : Binding<Bool>) {
            let context = LAContext()
            var error: NSError?
            let reason = "Por favor autentícate para tener acceso a su información"

            // Primero intentamos con biometría (Touch ID en macOS)
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evalError in
                    // Siempre actualizar la UI en el hilo principal
                    DispatchQueue.main.async {
                        HabilitarContenido.wrappedValue = success
                    }
                }

            // Si no hay biometría, intentamos la autenticación de dispositivo (contraseña del usuario)
            } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                    DispatchQueue.main.async {
                        HabilitarContenido.wrappedValue = success
                    }
                }

            // No hay métodos disponibles -> denegar por defecto
            } else {
                DispatchQueue.main.async {
                    HabilitarContenido.wrappedValue = false
                }
            }
        }
    
    #endif
    #if os(iOS)
    //Yorj: Muy importante: Em Swift 6 , esta función debe estar fuera de toda View, como una función statica por ejemplo.
   static func autent(HabilitarContenido : Binding<Bool>){
        
        let contextLA : LAContext = LAContext()
        var error : NSError?
        if contextLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            contextLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor autentícate para tener acceso a su información") { success, error in
                if success {
                    //Habilitación del contenido
                    //"el valor es satisfactorio")
                    HabilitarContenido.wrappedValue = true
                    
                    
                } else {
                    //"Error en la autenticación biométrica")
                    //"el valor ha dado error")
                    HabilitarContenido.wrappedValue = false
                }
            }
            
            
        }else{ //El Dispositivo no soporta autenticación biométrica
               // print("El Dispositivo no soporta autenticación biométrica")
        }
        
    }
    
    #endif
    
    
}





//Permite acceder al UserDefaul compartido : UserDefault.shared
extension UserDefaults {
    @MainActor static func shared()->UserDefaults{
        return UserDefaults(suiteName: AppCons.AppGroupName) ?? .standard
    }
    
}


//Extensión de String que permite obtener todos los dígitos de una cadena, incluido el punto "."
extension String {
    var digitos: String {
        return filter("1234567890.".contains)
    }
}




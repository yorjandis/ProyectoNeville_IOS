//
//  BiometrySupport.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 14/10/25.
//

//Determina si existe soporte para autenticación biométrica en el dispositivo:

import LocalAuthentication

//Define los resultados del chequeo de aoporte de biometría
public enum BiometrySupport {
    case available, notAvailable
    
}

//Chequea la existencia de soporte de biometría
struct BiometryCheckerSupport {
    static func checkBiometricSupport() -> BiometrySupport {
            let context = LAContext()
            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                switch context.biometryType {
                case .faceID:
                    return .available
                case .touchID:
                    return .available
                case .none:
                    return .notAvailable
                default:
                    return .notAvailable
                }
                 
            } else {
                return .notAvailable
            }
        }
}

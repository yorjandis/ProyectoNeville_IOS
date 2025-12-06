//
//  LocalAutenticationForIntent.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/11/25.
//

import LocalAuthentication

func autenticarBiometricamente() async -> Bool {
    let context = LAContext()
    var error: NSError?
    
    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
        return false
    }

    do {
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Acceder al diario"
        )
    } catch {
        return false
    }
}

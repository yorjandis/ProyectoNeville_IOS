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

    #if os(watchOS)
    let policy: LAPolicy = .deviceOwnerAuthentication
    #else
    let policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics
    #endif
    
    guard context.canEvaluatePolicy(policy, error: &error) else {
        return false
    }

    do {
        return try await context.evaluatePolicy(
            policy,
            localizedReason: "Acceder al diario"
        )
    } catch {
        return false
    }
}

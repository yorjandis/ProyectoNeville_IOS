//
//  AppIntentsMain.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//

//En macOS debemos implementar esta función para que el sistema registre todos nuestros Intents definidos

import AppIntents

struct IntentsPackages: AppIntentsPackage {

    static var includedIntents: [any AppIntent.Type] {
        [
            AbrirDiarioIntentMac.self,
            AbrirNotasItentMac.self,
            CrearFraseIntentMac.self,
            CrearEntradaDiarioIntentMac.self,
            CrearNotaIntentMac.self,
            GetRandomConfIntentMac.self
        ]
    }
}

//
//  Shortcuts.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 16/12/25.
//


import AppIntents

struct ShortcutsMac: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        // Atajo para Abrir el Diario
        AppShortcut(
            intent: AbrirDiarioIntentMac(),
            phrases: [
                "en \(.applicationName) abre diario",
                "en \(.applicationName) abre mi diario"
            ],
            shortTitle: "Abrir Diario",
            systemImageName: "lock.fill"
        )
        
        // Atajo para Abrir las Notas
        AppShortcut(
            intent: AbrirNotasItentMac(),
            phrases: [
                "en \(.applicationName) abre mis notas"
            ],
            shortTitle: "Abrir Notas",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una frase:
        AppShortcut(
            intent: CrearFraseIntentMac(),
            phrases: [
                "en \(.applicationName) crea una frase"
            ],
            shortTitle: "Crear Frases",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una entrada del Diario:
        AppShortcut(
            intent: CrearEntradaDiarioIntentMac(),
            phrases: [
                "en \(.applicationName) crea una entrada"
            ],
            shortTitle: "Crear Entrada Diario",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una nota:
        AppShortcut(
            intent: CrearNotaIntentMac(),
            phrases: [
                "en \(.applicationName) crea una nota"
            ],
            shortTitle: "Crear Notas",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una nota:
        AppShortcut(
            intent: GetRandomConfIntentMac(),
            phrases: [
                "en \(.applicationName) abre conferencia"
            ],
            shortTitle: "Abrir Conferencia",
            systemImageName: "doc.plaintext.fill"
        )
        
    }
}

//
//  DiarioShortcuts.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/11/25.
//
import AppIntents

struct Shortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        // Atajo para Abrir el Diario
        AppShortcut(
            intent: AbrirDiarioIntent(),
            phrases: [
                "en \(.applicationName) abre diario",
                "en \(.applicationName) abre mi diario"
            ],
            shortTitle: "Abrir Diario",
            systemImageName: "lock.fill"
        )
        
        // Atajo para Abrir las Notas
        AppShortcut(
            intent: AbrirNotasItent(),
            phrases: [
                "en \(.applicationName) abre mis notas"
            ],
            shortTitle: "Abrir Notas",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una nota:
        AppShortcut(
            intent: CrearNotaIntent(),
            phrases: [
                "en \(.applicationName) crea una nota"
            ],
            shortTitle: "Crear Notas",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una frase:
        AppShortcut(
            intent: CrearFraseIntent(),
            phrases: [
                "en \(.applicationName) crea una frase"
            ],
            shortTitle: "Crear Frases",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo para crear una entrada del Diario:
        AppShortcut(
            intent: CrearEntradaDiarioIntent(),
            phrases: [
                "en \(.applicationName) crea una entrada"
            ],
            shortTitle: "Crear Entrada Diario",
            systemImageName: "doc.plaintext.fill"
        )
        
        //Atajo abrir una conferencia a la azar neville
        AppShortcut(
            intent: GetRandomConfIntent(),
            phrases: [
                "en \(.applicationName) abre conferencia"
            ],
            shortTitle: "Abrir Conferencia",
            systemImageName: "doc.plaintext.fill"
        )
    }
}

//neville

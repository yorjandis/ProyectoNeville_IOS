//
//  CrearFraseCalmaIntent.swift
//  Neville_iOS
//
//  Created by Codex on 8/5/26.
//

import SwiftUI
import AppIntents
import CoreData

// Crea una frase personal en Espacio Calma.
struct CrearFraseCalmaIntent: AppIntent, ProvidesDialog {
    var value: Never?

    static let title: LocalizedStringResource = "Crear Frase para Calma"
    static let description = IntentDescription("Crear una frase personal en Espacio Calma")

    @AppStorage("yorjPremium", store: UserDefaults(suiteName: "group.com.ypg.nev.group")) var yorjPremium: Bool = false

    @Parameter(title: "Frase", description: "Contenido de la frase para Calma")
    var frase: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let hasPremium = await PremiumService.shared.hasPremiumAccess()
        guard (hasPremium || self.yorjPremium) else {
            throw PremiumError.noSubscription
        }

        let trimmedPhrase = frase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhrase.isEmpty else {
            return .result(dialog: IntentDialog("La frase no puede estar vacía."))
        }

        let coordinator = await CoreDataController.shared
            .persistentContainer
            .persistentStoreCoordinator

        if coordinator.persistentStores.isEmpty {
            try await CoreDataController.shared.cargarStores()
        }

        let context = await CoreDataController.shared.persistentContainer.newBackgroundContext()

        do {
            guard let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
                return .result(dialog: IntentDialog("No se encontró la entidad de Espacio Calma."))
            }
            let calmObject = NSManagedObject(entity: entity, insertInto: context)
            calmObject.setValue(UUID(), forKey: "id")
            calmObject.setValue(trimmedPhrase, forKey: "phrase")
            calmObject.setValue(Date(), forKey: "createdAt")

            try context.save()
            await CoreDataController.shared.context.refreshAllObjects()

            return .result(dialog: IntentDialog("La frase se creó y se añadió a Espacio Calma."))
        } catch {
            context.rollback()
            return .result(dialog: IntentDialog("No se pudo crear la frase para Espacio Calma."))
        }
    }
}

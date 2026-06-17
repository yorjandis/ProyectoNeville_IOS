import Foundation
import CoreData

extension Notification.Name {
    static let agendaDeletedForWatchSync = Notification.Name("agendaDeletedForWatchSync")
}

@MainActor
final class AgendaRepository {
    private let context = CoreDataController.shared.context

    func fetchAll() -> [AgendaItemData] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.sortDescriptors = [NSSortDescriptor(key: "fechaActividad", ascending: true), NSSortDescriptor(key: "hora", ascending: true)]

        do {
            return deduplicateAgendaByID(try context.fetch(request)).compactMap(mapEntity)
        } catch {
            return []
        }
    }

    func save(item: AgendaItemData) -> Bool {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)

        let object: NSManagedObject
        if let existing = try? context.fetch(request).first {
            object = existing
        } else {
            guard let entity = NSEntityDescription.entity(forEntityName: "AgendaItemEntity", in: context) else {
                return false
            }
            object = NSManagedObject(entity: entity, insertInto: context)
            object.setValue(item.id, forKey: "id")
            object.setValue(item.fechaCreacion, forKey: "fechaCreacion")
        }

        object.setValue(item.titulo, forKey: "titulo")
        object.setValue(item.fechaModificacion, forKey: "fechaModificacion")
        object.setValue(item.nota, forKey: "nota")
        object.setValue(item.fechaActividad, forKey: "fechaActividad")
        object.setValue(item.hora, forKey: "hora")
        object.setValue(item.lugar, forKey: "lugar")
        object.setValue(item.contenido, forKey: "contenido")
        object.setValue(item.prioridad.rawValue, forKey: "prioridad")
        object.setValue(item.colorHex, forKey: "colorHex")
        object.setValue(item.completada, forKey: "completada")
        object.setValue(item.recordatorioActivo, forKey: "recordatorioActivo")
        object.setValue(item.reminderID, forKey: "reminderID")
        object.setValue(item.seriesID, forKey: "seriesID")

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    func delete(itemID: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.predicate = NSPredicate(format: "id == %@", itemID as CVarArg)

        if let object = try? context.fetch(request).first {
            context.delete(object)
            do {
                try context.save()
                postDeletedAgendaForWatchSync(id: itemID)
            } catch {
                context.rollback()
            }
        }
    }

    func delete(seriesID: UUID) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "AgendaItemEntity")
        request.predicate = NSPredicate(format: "seriesID == %@", seriesID as CVarArg)

        guard let objects = try? context.fetch(request), !objects.isEmpty else {
            return
        }

        let deletedIDs = objects.compactMap { $0.value(forKey: "id") as? UUID }

        for object in objects {
            context.delete(object)
        }

        do {
            try context.save()
            deletedIDs.forEach(postDeletedAgendaForWatchSync)
        } catch {
            context.rollback()
        }
    }

    private func postDeletedAgendaForWatchSync(id: UUID) {
        NotificationCenter.default.post(
            name: .agendaDeletedForWatchSync,
            object: nil,
            userInfo: ["id": id.uuidString]
        )
    }

    private func mapEntity(_ object: NSManagedObject) -> AgendaItemData? {
        guard let id = object.value(forKey: "id") as? UUID else { return nil }

        let fechaCreacion = object.value(forKey: "fechaCreacion") as? Date ?? Date()
        let fechaModificacion = object.value(forKey: "fechaModificacion") as? Date ?? fechaCreacion
        let prioridadRaw = (object.value(forKey: "prioridad") as? String) ?? AgendaPriority.neutral.rawValue

        return AgendaItemData(
            id: id,
            titulo: (object.value(forKey: "titulo") as? String) ?? "",
            fechaCreacion: fechaCreacion,
            fechaModificacion: fechaModificacion,
            nota: (object.value(forKey: "nota") as? String) ?? "",
            fechaActividad: (object.value(forKey: "fechaActividad") as? Date) ?? Date(),
            hora: (object.value(forKey: "hora") as? Date) ?? Date(),
            lugar: (object.value(forKey: "lugar") as? String) ?? "",
            contenido: (object.value(forKey: "contenido") as? String) ?? "",
            prioridad: AgendaPriority(rawValue: prioridadRaw) ?? .neutral,
            colorHex: (object.value(forKey: "colorHex") as? String) ?? "#A9D7A4",
            completada: object.value(forKey: "completada") as? Bool,
            recordatorioActivo: (object.value(forKey: "recordatorioActivo") as? Bool) ?? false,
            reminderID: object.value(forKey: "reminderID") as? String,
            seriesID: object.value(forKey: "seriesID") as? UUID
        )
    }

    private func deduplicateAgendaByID(_ fetched: [NSManagedObject]) -> [NSManagedObject] {
        let groupedByID = Dictionary(grouping: fetched) { object in
            (object.value(forKey: "id") as? UUID)?.uuidString ?? ""
        }

        var idsToDelete = Set<NSManagedObjectID>()

        for (id, items) in groupedByID where !id.isEmpty && items.count > 1 {
            let keeper = items.max { lhs, rhs in
                comparableDate(for: lhs) < comparableDate(for: rhs)
            }

            for item in items where item.objectID != keeper?.objectID {
                idsToDelete.insert(item.objectID)
                context.delete(item)
            }
        }

        guard !idsToDelete.isEmpty else { return fetched }

        do {
            try context.save()
        } catch {
            context.rollback()
            return fetched
        }

        return fetched.filter { !idsToDelete.contains($0.objectID) }
    }

    private func comparableDate(for object: NSManagedObject) -> Date {
        if let modified = object.value(forKey: "fechaModificacion") as? Date {
            return modified
        }
        if let created = object.value(forKey: "fechaCreacion") as? Date {
            return created
        }
        return .distantPast
    }
}

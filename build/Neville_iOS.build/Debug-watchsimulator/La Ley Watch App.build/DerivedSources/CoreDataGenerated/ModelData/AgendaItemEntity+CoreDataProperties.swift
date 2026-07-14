//
//  AgendaItemEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias AgendaItemEntityCoreDataPropertiesSet = NSSet

extension AgendaItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AgendaItemEntity> {
        return NSFetchRequest<AgendaItemEntity>(entityName: "AgendaItemEntity")
    }

    @NSManaged public var colorHex: String?
    @NSManaged public var completada: Bool
    @NSManaged public var contenido: String?
    @NSManaged public var fechaActividad: Date?
    @NSManaged public var fechaCreacion: Date?
    @NSManaged public var fechaModificacion: Date?
    @NSManaged public var hora: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var lugar: String?
    @NSManaged public var nota: String?
    @NSManaged public var prioridad: String?
    @NSManaged public var recordatorioActivo: Bool
    @NSManaged public var reminderID: String?
    @NSManaged public var seriesID: UUID?
    @NSManaged public var titulo: String?

}

extension AgendaItemEntity : Identifiable {

}

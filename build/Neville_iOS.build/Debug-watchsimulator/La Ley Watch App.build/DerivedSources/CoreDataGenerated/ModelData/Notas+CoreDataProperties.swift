//
//  Notas+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias NotasCoreDataPropertiesSet = NSSet

extension Notas {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Notas> {
        return NSFetchRequest<Notas>(entityName: "Notas")
    }

    @NSManaged public var categoria: String?
    @NSManaged public var checklistItemsData: String?
    @NSManaged public var direccionMapa: String?
    @NSManaged public var fechaCreacion: Date?
    @NSManaged public var fechaModificacion: Date?
    @NSManaged public var id: String?
    @NSManaged public var isChecklist: Bool
    @NSManaged public var isfav: Bool
    @NSManaged public var nota: String?
    @NSManaged public var title: String?

}

extension Notas : Identifiable {

}

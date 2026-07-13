//
//  Diario+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias DiarioCoreDataPropertiesSet = NSSet

extension Diario {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Diario> {
        return NSFetchRequest<Diario>(entityName: "Diario")
    }

    @NSManaged public var capitulo: String?
    @NSManaged public var content: String?
    @NSManaged public var direccionMapa: String?
    @NSManaged public var emotion: String?
    @NSManaged public var fecha: Date?
    @NSManaged public var fechaM: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isFav: Bool
    @NSManaged public var title: String?

}

extension Diario : Identifiable {

}

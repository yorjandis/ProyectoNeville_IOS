//
//  Contexto+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ContextoCoreDataPropertiesSet = NSSet

extension Contexto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contexto> {
        return NSFetchRequest<Contexto>(entityName: "Contexto")
    }

    @NSManaged public var id: String?
    @NSManaged public var nombre: String?
    @NSManaged public var frases: NSSet?

}

// MARK: Generated accessors for frases
extension Contexto {

    @objc(addFrasesObject:)
    @NSManaged public func addToFrases(_ value: Frases)

    @objc(removeFrasesObject:)
    @NSManaged public func removeFromFrases(_ value: Frases)

    @objc(addFrases:)
    @NSManaged public func addToFrases(_ values: NSSet)

    @objc(removeFrases:)
    @NSManaged public func removeFromFrases(_ values: NSSet)

}

extension Contexto : Identifiable {

}

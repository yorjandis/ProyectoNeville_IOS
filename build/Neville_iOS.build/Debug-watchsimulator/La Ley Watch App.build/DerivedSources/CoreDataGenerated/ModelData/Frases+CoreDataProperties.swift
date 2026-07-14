//
//  Frases+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias FrasesCoreDataPropertiesSet = NSSet

extension Frases {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Frases> {
        return NSFetchRequest<Frases>(entityName: "Frases")
    }

    @NSManaged public var autor: String?
    @NSManaged public var frase: String?
    @NSManaged public var fuente: String?
    @NSManaged public var id: String?
    @NSManaged public var isfav: Bool
    @NSManaged public var isnew: Bool
    @NSManaged public var noinbuilt: Bool
    @NSManaged public var nota: String?
    @NSManaged public var contextos: NSSet?
    @NSManaged public var relacionadas: NSSet?
    @NSManaged public var relacionadasPor: NSSet?

}

// MARK: Generated accessors for contextos
extension Frases {

    @objc(addContextosObject:)
    @NSManaged public func addToContextos(_ value: Contexto)

    @objc(removeContextosObject:)
    @NSManaged public func removeFromContextos(_ value: Contexto)

    @objc(addContextos:)
    @NSManaged public func addToContextos(_ values: NSSet)

    @objc(removeContextos:)
    @NSManaged public func removeFromContextos(_ values: NSSet)

}

// MARK: Generated accessors for relacionadas
extension Frases {

    @objc(addRelacionadasObject:)
    @NSManaged public func addToRelacionadas(_ value: Frases)

    @objc(removeRelacionadasObject:)
    @NSManaged public func removeFromRelacionadas(_ value: Frases)

    @objc(addRelacionadas:)
    @NSManaged public func addToRelacionadas(_ values: NSSet)

    @objc(removeRelacionadas:)
    @NSManaged public func removeFromRelacionadas(_ values: NSSet)

}

// MARK: Generated accessors for relacionadasPor
extension Frases {

    @objc(addRelacionadasPorObject:)
    @NSManaged public func addToRelacionadasPor(_ value: Frases)

    @objc(removeRelacionadasPorObject:)
    @NSManaged public func removeFromRelacionadasPor(_ value: Frases)

    @objc(addRelacionadasPor:)
    @NSManaged public func addToRelacionadasPor(_ values: NSSet)

    @objc(removeRelacionadasPor:)
    @NSManaged public func removeFromRelacionadasPor(_ values: NSSet)

}

extension Frases : Identifiable {

}

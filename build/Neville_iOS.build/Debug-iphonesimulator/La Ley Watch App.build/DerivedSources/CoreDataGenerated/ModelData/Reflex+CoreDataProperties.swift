//
//  Reflex+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ReflexCoreDataPropertiesSet = NSSet

extension Reflex {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reflex> {
        return NSFetchRequest<Reflex>(entityName: "Reflex")
    }

    @NSManaged public var autor: String?
    @NSManaged public var id: String?
    @NSManaged public var isfav: Bool
    @NSManaged public var isInbuilt: Bool
    @NSManaged public var isnew: Bool
    @NSManaged public var texto: String?
    @NSManaged public var title: String?

}

extension Reflex : Identifiable {

}

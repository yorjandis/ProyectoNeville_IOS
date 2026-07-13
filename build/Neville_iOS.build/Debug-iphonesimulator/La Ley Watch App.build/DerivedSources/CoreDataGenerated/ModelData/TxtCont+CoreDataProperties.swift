//
//  TxtCont+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TxtContCoreDataPropertiesSet = NSSet

extension TxtCont {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TxtCont> {
        return NSFetchRequest<TxtCont>(entityName: "TxtCont")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isfav: Bool
    @NSManaged public var isnew: Bool
    @NSManaged public var namefile: String?
    @NSManaged public var nota: String?
    @NSManaged public var type: String?

}

extension TxtCont : Identifiable {

}

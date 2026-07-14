//
//  CalmUserPhrase+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CalmUserPhraseCoreDataPropertiesSet = NSSet

extension CalmUserPhrase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CalmUserPhrase> {
        return NSFetchRequest<CalmUserPhrase>(entityName: "CalmUserPhrase")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var phrase: String?

}

extension CalmUserPhrase : Identifiable {

}

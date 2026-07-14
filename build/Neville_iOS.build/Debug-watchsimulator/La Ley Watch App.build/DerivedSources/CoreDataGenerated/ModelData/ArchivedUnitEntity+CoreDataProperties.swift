//
//  ArchivedUnitEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ArchivedUnitEntityCoreDataPropertiesSet = NSSet

extension ArchivedUnitEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArchivedUnitEntity> {
        return NSFetchRequest<ArchivedUnitEntity>(entityName: "ArchivedUnitEntity")
    }

    @NSManaged public var completedDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var index: Int32
    @NSManaged public var info: String?
    @NSManaged public var name: String?
    @NSManaged public var note: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var status: String?
    @NSManaged public var goal: ArchivedGoalEntity?

}

extension ArchivedUnitEntity : Identifiable {

}

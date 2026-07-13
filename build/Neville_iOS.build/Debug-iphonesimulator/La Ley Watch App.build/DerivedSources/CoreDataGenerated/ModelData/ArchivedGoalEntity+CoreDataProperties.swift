//
//  ArchivedGoalEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias ArchivedGoalEntityCoreDataPropertiesSet = NSSet

extension ArchivedGoalEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArchivedGoalEntity> {
        return NSFetchRequest<ArchivedGoalEntity>(entityName: "ArchivedGoalEntity")
    }

    @NSManaged public var completionDate: Date?
    @NSManaged public var descriptionText: String?
    @NSManaged public var frequency: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var totalUnits: Int32
    @NSManaged public var unitType: String?
    @NSManaged public var units: NSSet?

}

// MARK: Generated accessors for units
extension ArchivedGoalEntity {

    @objc(addUnitsObject:)
    @NSManaged public func addToUnits(_ value: ArchivedUnitEntity)

    @objc(removeUnitsObject:)
    @NSManaged public func removeFromUnits(_ value: ArchivedUnitEntity)

    @objc(addUnits:)
    @NSManaged public func addToUnits(_ values: NSSet)

    @objc(removeUnits:)
    @NSManaged public func removeFromUnits(_ values: NSSet)

}

extension ArchivedGoalEntity : Identifiable {

}

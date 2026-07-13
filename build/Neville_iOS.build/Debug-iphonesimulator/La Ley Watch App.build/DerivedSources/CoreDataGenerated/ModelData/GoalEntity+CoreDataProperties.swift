//
//  GoalEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias GoalEntityCoreDataPropertiesSet = NSSet

extension GoalEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalEntity> {
        return NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }

    @NSManaged public var descriptionText: String?
    @NSManaged public var frequency: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var isStarted: Bool
    @NSManaged public var startDate: Date?
    @NSManaged public var title: String?
    @NSManaged public var totalUnits: Int32
    @NSManaged public var unitType: String?
    @NSManaged public var units: NSSet?

}

// MARK: Generated accessors for units
extension GoalEntity {

    @objc(addUnitsObject:)
    @NSManaged public func addToUnits(_ value: UnitEntity)

    @objc(removeUnitsObject:)
    @NSManaged public func removeFromUnits(_ value: UnitEntity)

    @objc(addUnits:)
    @NSManaged public func addToUnits(_ values: NSSet)

    @objc(removeUnits:)
    @NSManaged public func removeFromUnits(_ values: NSSet)

}

extension GoalEntity : Identifiable {

}

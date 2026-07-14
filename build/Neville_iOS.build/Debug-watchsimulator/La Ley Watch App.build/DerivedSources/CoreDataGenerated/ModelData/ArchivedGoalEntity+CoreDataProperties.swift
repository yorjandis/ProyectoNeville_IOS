//
//  ArchivedGoalEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
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
    @NSManaged public var completionBasis: String?
    @NSManaged public var customUnitLabel: String?
    @NSManaged public var dayPeriod: String?
    @NSManaged public var descriptionText: String?
    @NSManaged public var durationUnit: String?
    @NSManaged public var durationValue: Int32
    @NSManaged public var executionTargetValue: Double
    @NSManaged public var frequency: Int32
    @NSManaged public var id: UUID?
    @NSManaged public var scheduleType: String?
    @NSManaged public var title: String?
    @NSManaged public var totalUnits: Int32
    @NSManaged public var unitType: String?
    @NSManaged public var weeklyDaysPerWeek: Int16
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

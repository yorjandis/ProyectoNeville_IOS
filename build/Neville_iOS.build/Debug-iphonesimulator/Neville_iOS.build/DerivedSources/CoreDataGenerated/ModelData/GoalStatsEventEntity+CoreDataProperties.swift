//
//  GoalStatsEventEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 13/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias GoalStatsEventEntityCoreDataPropertiesSet = NSSet

extension GoalStatsEventEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalStatsEventEntity> {
        return NSFetchRequest<GoalStatsEventEntity>(entityName: "GoalStatsEventEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var dayStart: Date?
    @NSManaged public var eventType: String?
    @NSManaged public var goalID: UUID?
    @NSManaged public var goalTitle: String?
    @NSManaged public var id: UUID?
    @NSManaged public var unitID: UUID?
    @NSManaged public var unitIndex: Int32
    @NSManaged public var unitType: String?

}

extension GoalStatsEventEntity : Identifiable {

}

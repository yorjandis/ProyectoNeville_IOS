//
//  WeeklyReviewEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias WeeklyReviewEntityCoreDataPropertiesSet = NSSet

extension WeeklyReviewEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WeeklyReviewEntity> {
        return NSFetchRequest<WeeklyReviewEntity>(entityName: "WeeklyReviewEntity")
    }

    @NSManaged public var celebration: String?
    @NSManaged public var completedAt: Date?
    @NSManaged public var focus: String?
    @NSManaged public var id: UUID?
    @NSManaged public var periodEnd: Date?
    @NSManaged public var periodKey: String?
    @NSManaged public var periodStart: Date?
    @NSManaged public var snapshotJSON: String?

}

extension WeeklyReviewEntity : Identifiable {

}

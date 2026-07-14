//
//  RitualSessionEntity+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias RitualSessionEntityCoreDataPropertiesSet = NSSet

extension RitualSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RitualSessionEntity> {
        return NSFetchRequest<RitualSessionEntity>(entityName: "RitualSessionEntity")
    }

    @NSManaged public var anticipatedSituationsJSON: String?
    @NSManaged public var agendaCompletedCount: Int32
    @NSManaged public var agendaTotalCount: Int32
    @NSManaged public var automaticPilotEvents: Int32
    @NSManaged public var coherenceSessionsCount: Int32
    @NSManaged public var completed: Bool
    @NSManaged public var completedAtEpochMillis: Int64
    @NSManaged public var consciousResponsesJSON: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var energy: Int16
    @NSManaged public var emotionsJSON: String?
    @NSManaged public var goalUnitsCompletedCount: Int32
    @NSManaged public var goalsJSON: String?
    @NSManaged public var gratitude: String?
    @NSManaged public var id: UUID?
    @NSManaged public var identity: String?
    @NSManaged public var identityAlignment: Int16
    @NSManaged public var journalEntryCreated: Bool
    @NSManaged public var journalEntryID: UUID?
    @NSManaged public var journalEntryRequested: Bool
    @NSManaged public var kind: String?
    @NSManaged public var learning: String?
    @NSManaged public var noteText: String?
    @NSManaged public var predominantEmotionID: String?
    @NSManaged public var presenceReturns: Int32
    @NSManaged public var sessionDateEpochDay: Int64
    @NSManaged public var suggestion: String?
    @NSManaged public var tomorrowPreparation: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var whatWentWell: String?
    @NSManaged public var autopilotMoment: String?

}

extension RitualSessionEntity : Identifiable {

}

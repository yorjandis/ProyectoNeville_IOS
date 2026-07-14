//
//  coherencia+CoreDataProperties.swift
//  
//
//  Created by Yorjandis PG on 14/7/26.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias coherenciaCoreDataPropertiesSet = NSSet

extension coherencia {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<coherencia> {
        return NSFetchRequest<coherencia>(entityName: "coherencia")
    }

    @NSManaged public var afterScore: Int16
    @NSManaged public var beforeScore: Int16
    @NSManaged public var closingWord: String?
    @NSManaged public var dateEpochMillis: Int64
    @NSManaged public var durationMinutes: Int16
    @NSManaged public var heartConnectionScore: Int16
    @NSManaged public var id: UUID?
    @NSManaged public var initialState: String?
    @NSManaged public var intention: String?
    @NSManaged public var mentalClarityScore: Int16
    @NSManaged public var predominantEmotion: String?

}

extension coherencia : Identifiable {

}

//
//  UnitStatus.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI

enum UnitStatus: String {
    case pending
    case completed
    case lost
}


//Actualiza el título y la descripción de un objetivo:
extension UnitEntity {
     func updateNoteUnit(note: String) throws  {
         self.note = note
         try self.managedObjectContext?.save()
    }
}

//
//  iCloudKitCRUD.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 6/2/24.
//
//Operaciones para las distintas tablas de la BD

import Foundation
import CloudKit


struct iCloudNotas{
    
    ///Add (Private DB)
    /// - Parameters - título, nota y si es favorita
    /// - Returns - true si success, false otherwise
    func add(title : String, nota: String, isfav : Int64)async -> Bool{
        let record : [String : Any] = [
            TNotas.CD_entityName.rawValue   : TNotas.valueEntityName,
            TNotas.CD_id.rawValue           :UUID().uuidString,
            TNotas.CD_title.rawValue        :title,
            TNotas.CD_nota.rawValue         :nota,
            TNotas.CD_isfav.rawValue        : isfav
        ]
        let result = await iCloudKitModel(of: .BDPrivada).savePrivateRecord(tableName: TableName.CD_Notas, listFields: record)
        return result
        
    }
    
    
    ///Update:
    ////// - Parameters - record : un registro para actualizar
    ///  - Returns - true if success, false otherwise
    func Update(record : CKRecord?, title : String, nota: String, isfav : Int64)async -> Bool{
        if let rec = record{
            rec.setValue(title,     forKey: TNotas.CD_title.rawValue)
            rec.setValue(nota,      forKey: TNotas.CD_nota.rawValue)
            rec.setValue(isfav,     forKey: TNotas.CD_isfav.rawValue)
            
            return await iCloudKitModel(of: .BDPrivada).SaveRecord(record: rec)
        }
        
        
      return false
    }
    
    
    
    ///Delete
    /// - Parameters - record : un registro para eliminar
    /// - Returns - true if success, false otherwise
    func Delete(record : CKRecord?)async -> Bool {
        if let rec = record {
          return await iCloudKitModel(of: .BDPrivada).DeleteRecord(record: rec)
        }
        return false
    }
   
}


struct iCloudDiario{
    
    ///Add (Private DB)
    /// - Parameters - título, nota y si es favorita
    /// - Returns - true si success, false otherwise
    func add(title : String, content: String, emotion : String, fecha: Date, fechaM: Date,  isfav : Int64)async -> Bool{
        let record : [String : Any] = [
            TDiario.CD_entityName.txt      : TDiario.valueEntityName,
            TDiario.CD_id.txt              :UUID().uuidString,
            TDiario.CD_title.txt           :title,
            TDiario.CD_content.txt         :content,
            TDiario.CD_emotion.txt         :emotion,
            TDiario.CD_isFav.txt           : isfav,
            TDiario.CD_fecha.txt           :Date.now,
            TDiario.CD_fechaM.txt          :Date.now
        ]
        let result = await iCloudKitModel(of: .BDPrivada).savePrivateRecord(tableName: TableName.CD_Diario, listFields: record)
        return result
        
    }
    
    
    ///Update:
    ////// - Parameters - record : un registro para actualizar
    ///  - Returns - true if success, false otherwise
    func Update(record : CKRecord?, title : String, content: String, emotion : String, fecha: Date, fechaM: Date,  isfav : Int64)async -> Bool{
        if let rec = record{
            rec.setValue(title,     forKey: TDiario.CD_title.rawValue)
            rec.setValue(content,   forKey: TDiario.CD_content.rawValue)
            rec.setValue(emotion,   forKey: TDiario.CD_emotion.rawValue)
            rec.setValue(fecha,     forKey: TDiario.CD_fecha.rawValue)
            rec.setValue(fechaM,    forKey: TDiario.CD_fechaM.rawValue)
            rec.setValue(isfav,     forKey: TNotas.CD_isfav.rawValue)
            
            return await iCloudKitModel(of: .BDPrivada).SaveRecord(record: rec)
        }
        
        
        return false
    }
    
    
    
    ///Delete
    /// - Parameters - record : un registro para eliminar
    /// - Returns - true if success, false otherwise
    func Delete(record : CKRecord?)async -> Bool {
        if let rec = record{
            return await iCloudKitModel(of: .BDPrivada).DeleteRecord(record: rec)
        }
          return false
    }
    
    
    //MARK: Operaciones Diario filtros
    //estas operaciones generan un nuevo listado que se mostrará
    
    
    //filtrar por emocion
    
    //filtrar por favoritos
    
    
    //Buscar las entradas en una fecha
    
    
    //Buscar las entradas en un rango de fechas
    
}




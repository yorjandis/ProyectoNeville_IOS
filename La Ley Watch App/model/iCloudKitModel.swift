//
//  iCloudKitModel.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 4/2/24.
//
//Se encarga de las operaciones CRUD sobre iCloudKit


import Foundation
import CloudKit



///Inicializa el contenedor para un tipo de BD y Contiene operaciones CRUD:
/// - Returns - Devuelve un objeto CKDatabase listo para operaciones
class iCloudKitModel {
    
    enum typeOfDataBase {
        case BDPrivada, BDpublica, BDshared
    }
    private let containerName   = "iCloud.com.ypg.nev.app.icloud"
    private let CloudKitZone    = "com.apple.coredata.cloudkit.zone"
    private let OwnerName       = "_a2f03c7433ba9905c18635267039d0dc"
    
    
    private var container   : CKContainer     //Acceso al contenedor para operaciones que lo requieran
    private var containerDB : CKDatabase      //Acceso a la BD según el tipo especificado: privada, publica y compartida
   
    
    init(of type: typeOfDataBase){
        switch type{
        case .BDPrivada:
            self.containerDB = CKContainer(identifier: self.containerName).privateCloudDatabase
        case .BDpublica:
            self.containerDB = CKContainer(identifier: self.containerName).publicCloudDatabase
        case .BDshared:
            self.containerDB = CKContainer(identifier: self.containerName).sharedCloudDatabase
        }
        
        self.container = CKContainer(identifier: self.containerName)
        
    }
    


    /// Returns all records in the table
    /// - Parameter - : tableName: table name to request
    /// - Returns - array of all records in the table name
    func getRecords(tableName: TableName)async -> [CKRecord]{
        
        let query = CKQuery(recordType: tableName.txt, predicate: NSPredicate(value: true))   
        var result = [CKRecord]()
        do {
            let  yy  = try await self.containerDB.records(matching: query)
            for tuple in yy.matchResults {  //matchResults es un arreglo de tuples [RecordID, Result<record, error>]
                
                do {
                    try result.append(tuple.1.get()) //Con la función get() se obtiene el valor OK de Result<Record, error>, o sea, el record.
                }catch{
                    print("error obteniendo el record")
                } 
            }
        }catch{
            print(error.localizedDescription)
        }
        
        return result
        
    }
    

    
    
    
    ///Delete record in the BD:
    /// - Parameter -  record: record to delete
    /// - Returns -  true if success, false otherwise
    func DeleteRecord(record : CKRecord)async -> Bool{
        do{
            try await self.containerDB.deleteRecord(withID: record.recordID)
        }catch{
            print(error.localizedDescription)
            return false
        }
        return true
    }
    
    
    ///Save a record. Para Operaciones de Update
    ///Yorj: En el archivo CRUD se obtiene un registro, se modifica sus entradas y luego se llama a esta función para actualizar su contenido
    /// - Parameters - record : El registro a actualizar
    /// - Returns - true if success, false otherwise
    func SaveRecord(record : CKRecord)async -> Bool{
        do{
            try await self.containerDB.save(record)
            return true
        }catch{
            return false
        }
        
    }
    
    
    
    ///Salva un nuevo registro pasandole un diccionario . Se llama desde icloudKitCRUD
    /// - Parameters  tableName: Nombre de la tabla
    ///              listFields: array de campos a devolver
    /// - Returns - devuelve true si éxito, false si error
     func savePrivateRecord(tableName: TableName, listFields: [String: Any])async -> Bool{
         let rec = CKRecordZone.ID(zoneName: self.CloudKitZone, ownerName: self.OwnerName)
        let ckRecordID = CKRecord.ID(recordName: UUID().uuidString, zoneID:rec)
        
         let record = CKRecord(recordType: tableName.txt, recordID: ckRecordID)
        
        record.setValuesForKeys(listFields)
        do{
          try await  self.containerDB.save(record)
            return true
        }catch{
            print(error.localizedDescription)
            return false
        }
 
    }
    
    
    
    ///Salva un valor en la base de datos pública: Es compartida entre todos los usuarios. Se llama desde icloudKitCRUD
    /// - Parameters  tableName: Nombre de la tabla
    ///              listFields: array de campos a devolver
    /// - Returns - devuelve true si éxito, false si error
     func savePublicRecord(tableName: TableName, listFields: [String: Any])async -> Bool{
        
         let record = CKRecord(recordType: tableName.txt)
        record.setValuesForKeys(listFields)
        do{
            try await  self.containerDB.save(record)
        }catch{
            print(error.localizedDescription)
            return false
        }

        return true
    }
    
    
    ///Obtiene una listado de CKRecords en función de un criterio de búsqueda: Yor: Para establecer los filtros de contenido por el reloj
    ///
    func filterByCriterio(tableName: TableName, criterio : CriteriosFiltros, textoABuscar : String = "", fecha1: Date = Date.now, fecha2 : Date = Date.now)async -> [CKRecord]{

        var result = [CKRecord]()
        
        let allrecords = await self.getRecords(tableName:tableName) //Obteniendo todos los records de la tabla
        
        switch criterio {
            
        case .todos : result = allrecords
        case .tituloNota : //Vale para notas y Diario ya que ambos tienen un campo de título
            for i in allrecords {
                let temp = i.value(forKey: TNotas.CD_title.txt) as? String
                if let rr = temp { //porque temp es un String optional (as? String)
                    if rr.lowercased().contains(textoABuscar.lowercased()){
                        result.append(i)
                    }
                }
                
            }
        case .tituloDiario :
            for i in allrecords {
                let temp = i.value(forKey: TDiario.CD_title.txt) as? String
                if let rr = temp {
                    if rr.lowercased().contains(textoABuscar.lowercased()){
                        result.append(i)
                    }
                }
            }
        case .textoNota :
            for i in allrecords {
                let temp = i.value(forKey: TNotas.CD_nota.txt) as? String
                if let rr = temp {
                    if rr.lowercased().contains(textoABuscar.lowercased()){
                        result.append(i)
                    }
                }
            }
        case .contenidoDiario :
            for i in allrecords {
                let temp = i.value(forKey: TDiario.CD_content.txt) as? String
                if let rr = temp {
                    if rr.lowercased().contains(textoABuscar.lowercased()){
                        result.append(i)
                    }
                }
            }
        case .favoritoNota:
            for i in allrecords {
                let temp = i.value(forKey: TNotas.CD_isfav.txt) as? Int64
                if temp == 1 {result.append(i)}
            }
        case .favoritoDiario:
            for i in allrecords {
                let temp = i.value(forKey: TDiario.CD_isFav.txt) as? Int64
                if temp == 1 {result.append(i)}
            }
        case .emocionDiario:
            for i in allrecords {
                let emoticono = i.value(forKey: TDiario.CD_emotion.txt) as? String
                if let rr = emoticono {
                    if rr == textoABuscar {
                        result.append(i)
                    }
                }
                
            }
        case .fechaDiario:
            for i in allrecords {
                let temp = i.value(forKey: TDiario.CD_fecha.txt) as? Date
                if temp?.formatted(date: .long, time: .omitted) == fecha1.formatted(date: .long, time: .omitted){
                    result.append(i)
                }
            }
        case .rangoFechaDiario: //determinando las entradas que estan dentro de un rango de fechas determinado
            let range = fecha1...fecha2 //rango de fechas
            for i in allrecords {
                let fecha = i.value(forKey: TDiario.CD_fecha.txt) as? Date
                if range.contains(fecha ?? Date.now + 1){
                    result.append(i)
                }
            }
        }

        return result
        
        
    }
    
    //enum de criterios de filtros
    enum CriteriosFiltros {
        case todos, favoritoNota, favoritoDiario, tituloNota, tituloDiario, textoNota, contenidoDiario,emocionDiario, fechaDiario, rangoFechaDiario
    }
    
   
}//Class



//MARK: Enumeraciones de Tablas
enum TableName : String{
    case CD_Frases, CD_Diario, CD_Notas, CD_Reflex, CD_TxtCont, Prueba
    var txt: String { self.rawValue}
}

enum TNotas : String {
    case CD_entityName, CD_id, CD_title, CD_nota, CD_isfav
    var txt: String { self.rawValue}
    static let valueEntityName = "Notas"
}

enum TFrases : String{
    case CD_entityName, CD_id, CD_frase, CD_isfav, CD_isnew,CD_noinbuilt,CD_nota
    var txt: String { self.rawValue}
    static let valueEntityName = "Frases"
}

enum TTxtContent :String {
    case CD_entityName, CD_id, CD_isfav, CD_nota, CD_type, CD_namefile
    var txt: String { self.rawValue}
    static let valueEntityName = "TxtCont"
}

enum TDiario : String{
    case CD_entityName, CD_id, CD_title, CD_isFav, CD_content, CD_emotion, CD_fecha, CD_fechaM
    var txt: String { self.rawValue}
    static let valueEntityName = "Diario"
}
    
    

    

    
    


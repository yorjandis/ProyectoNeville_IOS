//
//  iCloudKitModel.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 4/2/24.
//
//Se encarga de las operaciones CRUD sobre iCloudKit


import Foundation
import CloudKit


//Resultados de la consultas y operaciones sobre la BD de icloud:
class iCloudKitResults : ObservableObject {
    @Published var resultNotas = [[String:String]]()//arreglo de entradas de dict qye representan los campos de la tabla
    
    static let shared = iCloudKitResults() //Singleton
}


//Inicializa el contenedor para un tipo de BD y Contiene operaciones CRUD:
class iCloudKitModel {
    
    enum typeOfDataBase {
        case BDPrivada, BDpublica, BDshared
    }
    private let containerName = "iCloud.com.ypg.nev.app.icloud"
    
   private var container : CKDatabase    //= CKContainer.init(identifier: "iCloud.com.ypg.nev.app.icloud").privateCloudDatabase
    
    
   // @Published var resultNotas = [(String, String)]()
   // @Published var resultNotas2 = [[String:String]]()//arreglo de entradas de dict qye representan los campos de la tabla
    
    
    init(of type: typeOfDataBase){
        switch type{
        case .BDPrivada:
            self.container = CKContainer(identifier: self.containerName).privateCloudDatabase
        case .BDpublica:
            self.container = CKContainer(identifier: self.containerName).publicCloudDatabase
        case .BDshared:
            self.container = CKContainer(identifier: self.containerName).sharedCloudDatabase
        }
        
    }
    
    
  
    
    /// Realiza una consulta a una tabla
    /// Parametros: lisFields: arreglo de campos a devolver
    func getRecords(tableName: String, listFields : [String])async -> [[String:String]]{
        
        let query = CKQuery(recordType: tableName, predicate: NSPredicate(value: true))
        
        var result = [[String:String]]()
        
        do {
            let  yy  = try await self.container.records(matching: query)
           
            for row in yy.matchResults {  //Recorriendo cada fila de la tabla
                do{
                    
                    var dic = [String:String]()//Crear una instancia de dic
                    for ii in listFields { //Volcaldo del contenido de la fila en un array de dict:
                        let value = try row.1.get().value(forKey: ii) as? String ?? ""
                        dic[ii] = value
                    }
                    result.append(dic)//Añadiendo el dic al arreglo de resultados
                    
                    //let title = try i.1.get().value(forKey: "CD_title") as? String ?? ""
                    //let nota = try i.1.get().value(forKey: "CD_nota") as? String ?? ""
                    //self.resultNotas.append((title, nota))
                }
                
            }
        }catch{
            print(error.localizedDescription)
        }
        
        
        iCloudKitResults.shared.resultNotas = result //!! Actualizando la variable de entorno
        
        return result
        
    }

    
    
    
    func DeleteRecord(recordName : String)async{
        do{
            try await self.container.deleteRecord(withID: CKRecord.ID.init(recordName: recordName))
        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    //Salva un registro de Nota:
    //Devuelve true si tiene éxito, false si error
    func saveRecordNota(title: String, nota: String, isfav : Int)async -> Bool{
        let rec = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: "_a2f03c7433ba9905c18635267039d0dc")
        let ckRecordID = CKRecord.ID(recordName: UUID().uuidString, zoneID:rec)
        
        let record = CKRecord(recordType: "CD_Notas", recordID: ckRecordID)
        
      
        
        record.setValue(title, forKey: "CD_title")
        record.setValue(nota, forKey: "CD_nota")
        record.setValue(UUID().uuidString, forKey: "CD_id")
        record.setValue(isfav, forKey: "CD_isfav")
        do{
          try await  self.container.save(record)
        }catch{
            print(error.localizedDescription)
            return false
        }
       
        return true
    }
    
    
    
    
    
}//Class



    
    
    
    

    
    


//
//  ConfeModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//Operaciones con las conferecnias

import Foundation
import CoreData

struct ConfeModel{
    let context = CoreDataController.dC.context
    
    ///Leyendo Userdefault:  que indica si se ha populado la tabla Confe
    private  var isConfeLoaded : Bool {
        return UserDefaults.standard.bool(forKey: Constant.UD_isConfLoaded)
    }
    
    
    ///Obtiene todas las Conferencias:
    /// - Returns : Devuelve un arreglo de objetos Conf, si falla devuelve un arreglo vacio
    func getAllConfe()-> [Confe]{
        let defaultResult = [Confe]()
        
        if isConfeLoaded == false {return defaultResult}
        
            let fetcRequest : NSFetchRequest<Confe> = Confe.fetchRequest()
            
            do{
                return try context.fetch(fetcRequest)
            }
            catch{
                return defaultResult
            }

    }
    
    
    
    ///Devuelve una conferencia aleatoria
    /// - Returns - Devuelve un objeto de tipo Confe. Si falla devuelve un objeto vacio
    func getRandomConfe()->Confe{
        let temp = self.getAllConfe()
        if temp.count > 0 {
            return temp.randomElement() ?? Confe()
        }
        return Confe()
    }
    
    
    ///Actualiza el estado de favorito (Alterna entre el estado actual)
    func setFavState(confe : Confe, state : Bool){
        do{
            confe.isFav = state
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    ///Devuelve el estado de favorito:
    func getFavState(confe : Confe)->Bool{
        return confe.isFav
    }
    
    ///Devuelve el valor del campo nota
    func getNota(confe : Confe)->String{
        return confe.nota ?? ""
    }
    
    ///Establece el valor del campo nota
    func setNota(confe : Confe, nota : String){
        do{
            confe.nota = nota
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    ///Devuelve un arreglo con todas las conferencias favoritas
    func getAllFavorite()->[Confe]{
        var result : [Confe] = []
        let array = self.getAllConfe()
        
        for item in array{
            if item.isFav{
                result.append(item)
            }
        }
        
        
        return result
    }
    
    ///Devuelve todas las conferencias que tiene alguna nota
    func getAllNota()->[Confe]{
        var result : [Confe] = []
        let array = self.getAllConfe()
        
        for item in array{
            let temp = item.nota ?? ""
            if !temp.isEmpty {
                result.append(item)
            }
        }

        return result
    }
 
    
    
    
    ///Popula la Tabla Conf. Esto se hace la primera vez que se instala la app
    func populateConf(){
        if isConfeLoaded {return} //Sale si la tabla frases ya esta populada
            
            let arrayConf = listTxtConfe() //Obtiene el arreglo de fileName de confe
 
            //Populando la tabla Confe
            for item in arrayConf {
                
                let row = Confe(context: context) //carga entidad Frases desde el contexto
                
                row.id = UUID()
                row.isFav = false
                row.nota = ""
                row.nameFile = item
                    try? context.save()
            }
                
                //almacena una marca que indica que la tabla frase ha sido populada
                UserDefaults.standard.setValue(true, forKey: Constant.UD_isConfLoaded)
    }
    

    //Obtiene un arreglo con todas los nombre de las conferencias txt
    ///Obtiene el arreglo de ficheros txt
   private  func  listTxtConfe()-> [String] {
        var result = [String]()
        var temp : String = ""
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!

        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            
            for item in items {
                if item.hasPrefix(TypeOfTxtContent.conf.getPrefix) {
                    temp = String(item.trimmingPrefix(TypeOfTxtContent.conf.getPrefix))
                        .replacingOccurrences(of: ".txt", with: "")
                        .capitalized(with: .autoupdatingCurrent)
                    
                    result.append(temp)
                }
            }
        } catch {
            // failed to read directory – bad permissions, perhaps?
        }
        
        return result
        
    }
    
    
    
}

//
//  YTIdModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 11/11/23.
//
//Maneja la tabla YTVideo que se encarga de los id de videos

import Foundation
import CoreData


struct YTIdModel{
    
    let context = CoreDataController.dC.context
    
    
    
    //Obtener todos los items
    
    func GetAllItems(type : YTIdModel.TypeIdVideosYoutube)->[YTvideo]{
        var result : [YTvideo] = []
        
        do{
            let fetchRequest : NSFetchRequest<YTvideo> = YTvideo.fetchRequest()
            let array = try context.fetch(fetchRequest)
            for item in array{
                if item.type == type.getnameFile{
                    result.append(item)
                }
            }
        }catch{
            
        }
        return result

    }
    
    ///Devuelve una entity aleatoria, segun el tipo
    ////// - Parameter type : indica el tipo de contenido a filtrar
    /// - Returns - Devuelve un objeto de tipo YTVideo. Si falla devuelve un objeto vacio
    func getRandomConfe(type : YTIdModel.TypeIdVideosYoutube)->YTvideo{
        let temp = self.GetAllItems(type: type)
        if temp.count > 0 {
            return temp.randomElement() ?? YTvideo(context: context)
        }
        return YTvideo(context: context)
    }
    
    
    ///Actualiza el estado de favorito (Alterna entre el estado actual)
    func setFavState(entity : YTvideo, state : Bool){
        do{
            entity.isfav = state
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    ///Devuelve el valor del campo nota
    func getNota(entity : YTvideo)->String{
        return entity.nota ?? ""
    }
    
    ///Establece el valor del campo nota
    func setNota(entity : YTvideo, nota : String){
        do{
            entity.nota = nota
            try context.save()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    
    ///Devuelve un arreglo con todas las entity de cierto tipo que son favoritas
    func getAllFavorite(type : YTIdModel.TypeIdVideosYoutube)->[YTvideo]{
        var result : [YTvideo] = []
        let array = self.GetAllItems(type: type)
        
        for item in array{
            if item.isfav{
                result.append(item)
            }
        }
        
        return result
    }
    
    
    ///Devuelve todas las entity que tiene una nota, segun el tipo
    func getAllNota(type : YTIdModel.TypeIdVideosYoutube)->[YTvideo]{
        var result : [YTvideo] = []
        let array = self.GetAllItems(type: type)
        
        for item in array{
            let temp = item.nota ?? ""
            if !temp.isEmpty {
                result.append(item)
            }
        }

        return result
    }
    
    
    
    //------------------------------------------------------FUNCIONES INTERNAS------------------------------------------------
    
    ///Popula la Tabla YTVideo. Esto se hace la primera vez que se instala la app
    func populateTable(){
        
       if UserDefaults.standard.bool(forKey: Constant.UD_isYTvideoPupulate) {return} //Sale si la tabla TxtFiles ya esta populada
        
        print("yor: Esta es la primera vez")
        
        var array : [(String, String)] = [] //Almacena los idVideos,title en forma de tupla

        let arrayOfNameFiles = ["listidvideoconf","listidaudiolibros","listidgregg","list1",
                                "list2","list3"
        
        ] //Yor en un futuro esto debe poder escalarse autom. con nuevo contenido
        
 
        for nameFile in arrayOfNameFiles{
            
            array = self.GetIdVideosFromTxtFiles(nameFile: nameFile) //Obteniendo el arreglo de id de videos
            
            //Populando... segun el tipo de elemento (prefijo)
            for item in array {
                let entidad = YTvideo(context: context)
                entidad.id          = UUID()
                entidad.isfav       = false
                entidad.nota        = ""
                entidad.idvideo     = item.0
                entidad.titlevideo  = item.1
                entidad.type        = nameFile //!!!Este campo dice el tipo de video!!! es el nombre del fichero txt que contiene los id
                
            }
        }
        
        if context.hasChanges {
            try? context.save()
        }
        
        
        //almacena en UserDefault un flag que indica que la tabla se ha populado
        if self.GetAllItems(type: .video_Conf).count > 0 { //Significa que se populó la tabla con al menos las Video_conferencias
            UserDefaults.standard.setValue(true, forKey: Constant.UD_isYTvideoPupulate)
        }
            
           
    }
    

    
    //Devuelve un arreglo de id de videos tomados de un txt
    /// - Parameters - typeContent : indica el tipo de listado a cargar
    /// - Returns - arreglo de tuplas donde .0 es IdVideo; .1 es el título del video
     func GetIdVideosFromTxtFiles(nameFile : String)-> [(String, String)]{
        var result : [(String, String)] = []
        var temp = [String]() //array: linea del txt: "ID::Title"

        temp = UtilFuncs.ReadFileToArray(nameFile)
        
        for item in temp {
            let temp1 = item.components(separatedBy: "::")
            result.append((temp1[0], temp1[1]))
        }
        return result

    }
    
    
    enum TypeIdVideosYoutube{
        case aud_libros, video_Conf, gregg, liderazgo, desarrolloPersonal, libertadFinanciera, emprendedores, espiritualidad, personasDejaronHuellas, alcanzarExito, NA
        
        
        var getnameFile : String {
            switch self{
            case .gregg:                        return "listidgregg"
            case .espiritualidad:               return "list1"
            case .liderazgo:                    return "list2"
            case .desarrolloPersonal:           return "list3"
            case .libertadFinanciera:           return "list4"
            case .emprendedores:                return "list5"
            case .personasDejaronHuellas:       return "list6"
            case .alcanzarExito:                return "list7"
            case .video_Conf:                   return "listidvideoconf"
            case .aud_libros:                   return "listidaudiolibros"
            case .NA:                           return ""
            }
        }
        
        var getTitle : String {
            switch self{
            case .gregg:                        return "Videos de Gregg Braden"
            case .espiritualidad:               return "Espiritualidad"
            case .liderazgo:                    return "Liderazgo"
            case .desarrolloPersonal:           return "Desarrollo Personal"
            case .libertadFinanciera:           return "Libertad Financiera"
            case .emprendedores:                return "Emprendedores"
            case .personasDejaronHuellas:       return "Personas que dejaron huellas"
            case .alcanzarExito:                return "Alcanzar el éxito"
            case .video_Conf:                   return "Videos Conferencias"
            case .aud_libros:                   return "Audio Libros"
            case .NA:                           return ""
            }
        }

    }
    
}









//Item de video de Youtube:
struct ItemVideoYoutube : Hashable{
    let id : String //id del video
    let title : String //Un título descriptivo
    
    ///Devuelve un arreglo de objetos "ItemVideoYoutube" Para poder crear varios videos a la vez
    func getInfo()->[ItemVideoYoutube]{
        var result = [ItemVideoYoutube]()
        result.append(ItemVideoYoutube(id: self.id, title: self.title))
        return result
    }
    
}

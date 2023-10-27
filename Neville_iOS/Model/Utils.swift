//
//  Utils.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//

import SwiftUI

//Almacenamiento de variables globales:
struct Constant{
    static let appName      = "Neville Para Todos"
    static let appVersion   = "1.0.0"
    
    //nameFile in Staff:
    static let FileListFrases           = "listfrases"
    static let FileBiografia            = "biografia"
    static let FileListIdVideoConf      = "listidvideoconf"
    static let FileListIdAudioLibros    = "listidaudiolibros"
    static let FileListIdGreggVideos    = "listidgregg"
    
    
    //Colors:
    static var favoriteColorOff : Color = Color.black
    static var favoriteColorOn : Color  = Color.orange
    
    //UserDefault:
    
        /// UserDefault Store:  Nombre para la clave Bool que indica si la entity Frases ha sido populada
    static var UD_isfrasesLoaded = "isfrasesLoaded"
    
    
     //Tab names for TabButtons
     static let tabButtons = ["book.pages.fill","video.fill","house.circle.fill","video.circle.fill", "slider.vertical.3"]
 
}

///Enumeración para los distintos tipos de elementos de contenido:
///El valor raw representa el prefijo/nombre del fichero en el bundle
enum TypeOfTxtContent{
    case conf, aud_Conf, frases, citas, preguntas, ayudas, biografia, NA
    
    //devuelve un título para cada case
    var getDescription:String{
        switch self {
        case .conf          :  return "Conferencias En Texto"
        case .frases        :  return "Frases"
        case .aud_Conf      :  return "Audio Conferencias"
        case .ayudas        :  return "Ayudas"
        case .citas         :  return "Citas de Conferencias"
        case .preguntas     :  return "Preguntas y Respuestas"
        case .biografia     :  return "Biografía"
        case .NA            :  return ""
        }
    }
    
    //Devuelve el prefijo del fichero txt inbuilt (También para IDs youtube)
    var getPrefix : String{
        switch self {
        case .conf          :  return "conf_"
        case .ayudas        :  return "ayud_"
        case .citas         :  return "cita_"
        case .preguntas     :  return "preg_"
        default: return ""
        }
    }
    
    //Devuelve el valor self de acuerdo al prefijo entrado (lo contrario de getPrefix )
    

    
}


///Enum para listar videos de youtube
///
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

struct UtilFuncs{
    
    ///Obtiene la lista de frases del fichero txt in-built:
    /// - Returns: Devuelve un  arreglo de cadenas con las frases cargadas del txt en Staff
    static  func getfrasesArrayFromTxtFile() ->[String] {
        var array = [String]()
        
        array = UtilFuncs.ReadFileToArray(Constant.FileListFrases)
        
        return array
        
    }
    
    ///Devuelve una frase aleatoria
    /// - Returns : Devuelve una frase aleatoria a partir del arreglo generado por `getfrasesArrayFromTxtFile()`
    static func getRandonFrase()->String{
        return getfrasesArrayFromTxtFile().randomElement() ?? ""
    }
    
    
    ///ReadFileToArray : Devuelve un array conteniendo todas las líneas de texto de un fichero txt
   static  func ReadFileToArray(_ filetxt : String)->[String]{
        
        var result = [String]()
        
        if let content = Bundle.main.url(forResource: filetxt , withExtension: "txt") {
            if let fileContens = try? String(contentsOf: content){
                
                result = fileContens.components(separatedBy: .newlines)
                if result.last == "" {
                    result.removeLast()
                }
            }
        }
        return result
        
    }

    
    
    ///Devuelve un arreglo de tuplas con pares titulo, idVideo para videos
    ///
    /// - Parameters - typeContent : indica el tipo de listado a cargar
    /// - Returns - arreglo de tuplas donde .0 es IdVideo; .1 es el título del video
    static func GetIdVideosFromYoutube(typeContent : TypeIdVideosYoutube)-> [(String, String)]{
        var result : [(String, String)] = []
        var temp = [String]() //array: linea del txt: "ID::Title"

        temp = UtilFuncs.ReadFileToArray(typeContent.getnameFile)
        
        for item in temp {
            let temp1 = item.components(separatedBy: "::")
            result.append((temp1[0], temp1[1]))
        }
        return result

    }

    
}








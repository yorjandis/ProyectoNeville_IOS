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
    static let appVersion   = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    
    //nameFile in Staff:
    static let FileListFrases           = "listfrases"
    static let FileBiografia            = "biografia"
    static let FileListIdVideoConf      = "listidvideoconf"
    static let FileListIdAudioLibros    = "listidaudiolibros"
    static let FileListIdGreggVideos    = "listidgregg"
    
    
    //Colors:
    static var favoriteColorOff : Color = Color.black
    static var favoriteColorOn  : Color  = Color.orange
    
    //UserDefault(UD_):
    
    /// Para conocer si se ha populado la tabla Frases
    static var UD_isfrasesLoaded = "isfrasesLoaded"
    
    /// Para conocer si se ha populado la tabla TxtFiles con el  contenido TXT(conferencias, citas, preguntas, ayudas...) : Bool
    static var UD_isTxtFilesPupulate        = "isTxtFilesPupulate"
    
    /// Para conocer si se ha populado la tabla YTvideo  : Bool
    static var UD_isYTvideoPupulate        = "isYTvideoPupulate"
    
    //name values for setting:
    static let UD_setting_fontFrasesSize   = "setting_fontFrasesSize"
    static let UD_setting_fontContentSize  = "setting_fontContentSize"
    static let UD_setting_fontMenuSize     = "setting_fontMenuSize"
    static let UD_setting_fontListaSize    = "setting_fontListaSize"
    
    static let UD_setting_color_frases      = "settig_color_frases"
    static let UD_setting_color_main_a      = "settig_color_main_a"
    static let UD_setting_color_main_b      = "settig_color_main_b"
    
    
    

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





struct UtilFuncs{
    

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

    //Lee el contenido del TXt y lo devuelve como String
   static func FileRead(_ file : String)->String{
        
        var result = ""
       let temp = "\(file.lowercased())"
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            
            if let fileContens = try? String(contentsOf: gg){
                result = fileContens
            }
            
        }
        
        return result
        
    }
    


    
}








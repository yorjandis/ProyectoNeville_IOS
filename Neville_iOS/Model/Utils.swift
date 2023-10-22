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
enum TypeOfContent{
    case conf, video_Conf, aud_Conf, frases, citas, preguntas, ayudas,aud_libros, biografia,vide_gregg,  NA
    
    //devuelve un título para cada case
    var getTitleOfContent:String{
        switch self {
        case .conf          :  return "Conferencias En Texto"
        case .frases        :  return "Frases"
        case .aud_Conf      :  return "Audio Conferencias"
        case .ayudas        :  return "Ayudas"
        case .citas         :  return "Citas de Conferencias"
        case .preguntas     :  return "Preguntas y Respuestas"
        case .video_Conf    :  return "Video Conferencias"
        case .aud_libros    :  return "Audio libros"
        case .biografia     :  return "Bio"
        case .vide_gregg    :  return "Videos Gregg Braden"
        case .NA            :  return ""
        }
    }
    
    //Devuelve el prefijo del fichero txt inbuilt
    var getPrefix : String{
        switch self {
        case .conf          :  return "conf_"
        case .ayudas        :  return "ayud_"
        case .citas         :  return "cita_"
        case .preguntas     :  return "preg_"
        default: return ""
        }
    }
    
    //Devuelve el nombre del fichero inbuilt
    var getNameFile : String {
        switch self {
        case .video_Conf : return "listidvideoconf"
        case .aud_libros : return "listidaudiolibros"
        case .vide_gregg : return "listidgregg"
        default: return ""
        }
    }
    
}


//Representa un item de video de Youtube:
struct ItemVideoYoutube : Hashable{
    let id : String //id del video
    let title : String //Un título descriptivo
    
    ///Devuelve un arreglo con la info de sus campos
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

    //Devuelve un arreglo de tuplas: IDvideo:TitleOfVideo
    static func getListVideoIds(_ typeContent : TypeOfContent)->[(String ,String)]{
        
        var result  = [(String , String)]()  //dic
        var temp = [String]() //array linea del txt: "ID::Title"
        var temp2 = [String]() //array contiene cada parte: [0]=ID, [1]=title
        
        
        temp = UtilFuncs.ReadFileToArray(typeContent.getNameFile)
        for idx in temp {
            temp2 = idx.components(separatedBy: "::") //separando componentes
            result.append((temp2[0], temp2[1]))
            // result[temp2[0]] = temp2[1] //populando el dic
        }
        
        return result
        
    }

    //Yor: es la mismo que getListVideoIds pero utilizando un array2D
    static func getListVideoIds2(_ typeContent : TypeOfContent)->[[String]]{

        var temp = [String]() //array linea del txt: "ID::Title"
        var temp2 = [String]() //array contiene cada parte: [0]=ID, [1]=title
        
        
        temp = UtilFuncs.ReadFileToArray(typeContent.getNameFile)
        
        var result = Array(repeating: Array(repeating: "", count: 2), count: temp.count)  //dic
        var i : Int = 0
        for idx in temp {
            temp2 = idx.components(separatedBy: "::") //separando componentes
            result[i][0] = temp2[0]
            result[i][1] = temp2[1]
            if i <= temp.count{   i += 1}
            // result[temp2[0]] = temp2[1] //populando el dic
        }
        
        return result
        
    }

    
}








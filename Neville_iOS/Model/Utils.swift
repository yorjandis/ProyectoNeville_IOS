//
//  Utils.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 15/9/23.
//Esto es un ejemplo

import Foundation
import SwiftUI
import LocalAuthentication

//Almacenamiento de variables globales:
@MainActor
struct AppCons{
    static let appName      = "La Ley"
    static let appVersion   = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    
    static let AppGroupName = "group.com.ypg.nev.group" //Nombre del contenedor AppGroup compartido
    
    
    //nameFile in Staff:
    static let FileListFrases           = "listfrases"
    static let FileBiografia            = "biografia"
    static let FileListIdVideoConf      = "listidvideoconf"
    static let FileListIdAudioLibros    = "listidaudiolibros"
    static let FileListIdGreggVideos    = "listidgregg"
    
    
    //Colors:
    static var favoriteColorOff : Color = Color.black
    static var favoriteColorOn  : Color  = Color.orange

    
    //name values for setting:
    static let UD_setting_fontFrasesSize   = "setting_fontFrasesSize"
    static let UD_setting_fontContentSize  = "setting_fontContentSize"
    static let UD_setting_fontMenuSize     = "setting_fontMenuSize"
    static let UD_setting_fontListaSize    = "setting_fontListaSize"
    
    static let UD_setting_color_frases          = "settig_color_frases"
    static let UD_setting_color_main_a          = "settig_color_main_a"
    static let UD_setting_color_main_b          = "settig_color_main_b"
    static let UD_setting_color_fondoContent    = "settig_color_fondoContent"
    static let UD_setting_color_textContent     = "settig_color_textContent"
    
    static let UD_setting_NotasFaceID           = "setting_NotasFaceID"
    
    //UserDefault compartido:(UD_shared_)
    static let UD_shared_FraseWidgetActual = "FraseWidgetActual" //Donde se almacena la frase actualmente cargada en el widget
    
    //DeepLinks:
    static let DeepLink_url_Diario  = "widget:/com.ypg.nev.diario"
    static let DeepLink_url_Notas   = "widget:/com.ypg.nev.notas"
    static let DeepLink_url_Frase   = "widget:/com.ypg.nev.frase"
    
    //Lleva un registro con las interacciones del usuario para mostrar una ventana de reseña
    static let UD_setting_ReviewCounter     = "UD_setting_ReviewCounter" //Contador de hitos
    static let UD_setting_showReview        = "UD_setting_showReview"   //Si es 1, se muestra la ventana, si es 2  no se muestra la ventana de review
    

}

/*
///Enumeración para los distintos tipos de elementos de contenido:
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
    

    
}
*/



struct UtilFuncs{
    
    
    ///ReadFileToArray : Devuelve un array conteniendo todas las líneas de texto de un fichero txt
    /// - Parameter - filename: el nombre del fichero sin la extension, para ser procesado
    /// - Returns - Devuelve un arreglo de String. cada línea del fichero es una item del arreglo
    static  func FileReadToArray(_ filename : String)->[String]{
        
        var result = [String]()
        
        if let content = Bundle.main.url(forResource: filename , withExtension: "txt") {
            if let fileContens = try? String(contentsOf: content){
                
                result = fileContens.components(separatedBy: .newlines)
                while result.last == ""{
                    result.removeLast()
                }
            }
        }
        return result
        
    }
    
    ///Lee el contenido de un fichero Txt, ubicado en el bundle de la app, y lo devuelve como String
    /// - Parameter - fileName: el nombre del fichero, sin la extensión
    ///  - Returns - Devuelve el contenido del fichero
    static func FileRead(_ fileName: String) -> String {
        var result = ""
        let temp = "\(fileName.lowercased())"
        
       // print("Yorj: nombre del fichero a abrir \(temp)")
        
        if let gg = Bundle.main.url(forResource: temp, withExtension: "txt") {
            if let fileContents = try? String(contentsOf: gg) {
                result = fileContents.replacingOccurrences(of: "\n", with: "<br>")
            }
        }
        return result
    }
    
    #if os(iOS)
    
    //Yorj: Muy importante: Em Swift 6 , esta función debe estar fuera de toda View, como una función statica por ejemplo.
   static func autent(HabilitarContenido : Binding<Bool>){
        
        let contextLA : LAContext = LAContext()
        var error : NSError?
        if contextLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            contextLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor autentícate para tener acceso a su información") { success, error in
                if success {
                    //Habilitación del contenido
                    //"el valor es satisfactorio")
                    HabilitarContenido.wrappedValue = true
                    
                    
                } else {
                    //"Error en la autenticación biométrica")
                    //"el valor ha dado error")
                    HabilitarContenido.wrappedValue = false
                }
            }
            
            
        }else{ //El Dispositivo no soporta autenticación biométrica
               // print("El Dispositivo no soporta autenticación biométrica")
        }
        
    }
    
    #endif
    
    
}





//Permite acceder al UserDefaul compartido : UserDefault.shared
extension UserDefaults {
    @MainActor static func shared()->UserDefaults{
        return UserDefaults(suiteName: AppCons.AppGroupName) ?? .standard
    }
    
}


//Extensión de String que permite obtener todos los dígitos de una cadena, incluido el punto "."
extension String {
    var digitos: String {
        return filter("1234567890.".contains)
    }
}




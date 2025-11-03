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
    
    //name values for setting:
    static let UD_setting_fontFrasesSize   = "setting_fontFrasesSize"
    static let UD_setting_fontContentSize  = "setting_fontContentSize"
    static let UD_setting_fontMenuSize     = "setting_fontMenuSize"
    static let UD_setting_fontListaSize    = "setting_fontListaSize"
    static let UD_setting_fontChatIASize   = "setting_fontChatIASize"
    
    //Colores
    static var favoriteColorOff : Color = Color.black
    static var favoriteColorOn  : Color  = Color.orange
    static let UD_setting_color_frases          = "settig_color_frases"
    static let UD_setting_color_main_a          = "settig_color_main_a"
    static let UD_setting_color_main_b          = "settig_color_main_b"
    static let UD_setting_color_fondoContent    = "settig_color_fondoContent"
    static let UD_setting_color_textContent     = "settig_color_textContent"
    
    //Otros
    static let UD_setting_OrdenarEntradaDiario  = "settig_Diario_ordenarentradas" //Permite ordenar las entradas del Diario por fechaCracion/fechaModificación
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
    
    //IA:
    static let UD_setting_TipoChatIA            = "setting_TipoChatIA"  //Tipo de Chat de IA(true : neville, false : Chat General)
    static let UD_setting_AceptacionDescargoIA  = "AceptacionDescargoIA"  //Aceptación del Descargo de Responsabilidad(true : Acepto, false : No acepto). La funciones de IA dependerán de este acuerdo aceptado.
    
    static let DescargoDeResposabilidad = """
                Descargo de Responsabilidad:\n
                
                🟣 La Inteligencia Artificial, IA en lo adelante, puede generar respuestas imprecisas o con errores.
                
                🟣 El usuario es el único responsable de la verificación y la aplicación
                de la respuesta generada por IA.
                
                🟣 El desarrollador no es responsable por  los daños o pérdidas derivadas del uso o imposibilidad de uso del contenido generado por IA.
                
                🟣 Para hacer uso de la IA debe aceptar estas condiciones.
                
                Nota: Este Descargo de Responsabilidad estará disponible en Ajustes.
                """
    
}



struct UtilFuncs{
    
    
    ///ReadFileToArray : Devuelve un array conteniendo todas las líneas de texto de un fichero txt
    /// - Parameter - filename: el nombre del fichero sin la extension, para ser procesado
    /// - Returns - Devuelve un arreglo de String. cada línea del fichero es una item del arreglo
    static func FileReadToArray(_ filename: String) -> [String] {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "txt"),
              let fileContents = try? String(contentsOf: url) else {
            return []
        }

        // Separa por líneas y elimina las vacías o con solo espacios
        let result = fileContents
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // limpia cada línea
            .filter { !$0.isEmpty } // elimina vacías

        return result
    }
    
    ///Lee el contenido de un fichero Txt, ubicado en el bundle de la app, y lo devuelve como String
    /// - Parameter - fileName: el nombre del fichero, sin la extensión
    ///  - Returns - Devuelve el contenido del fichero
    static func FileRead(_ fileName: String) -> String {
        var result = ""
        let temp = "\(fileName.lowercased())"
        
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




//
//  AppCons.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 5/11/25.
//

import SwiftUI

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
    static let UD_setting_fontChatIASize   = "setting_fontChatIASize" //Tamaño de letra del chat de IA
 
    //Colores
    static var favoriteColorOff : Color = Color.black
    static var favoriteColorOn  : Color  = Color.orange
    static let UD_setting_color_frases          = "settig_color_frases"
    static let UD_setting_color_main_a          = "settig_color_main_a"
    static let UD_setting_color_main_b          = "settig_color_main_b"
    static let UD_setting_color_fondoContent    = "settig_color_fondoContent"
    static let UD_setting_color_textContent     = "settig_color_textContent"
    
    //Colores de IA
    static let UD_setting_colorIA_main_a          = "settig_colorIA_main_a"
    static let UD_setting_colorIA_main_b          = "settig_colorIA_main_b"
    static let UD_setting_colorIA_textContent     = "settig_colorIA_textContent"    //Color del texto del Chat de mIA
    static let UD_setting_colorIA_textRespond     = "setting_colorIA_textRespond"   //Color de texto de la ventana de respuesta de la IA
    
    //Otros
    static let UD_setting_OrdenarEntradaDiario      = "settig_Diario_ordenarentradas" //Permite ordenar las entradas del Diario por fechaCracion/fechaModificación
    static let UD_setting_NotasFaceID               = "setting_NotasFaceID" //Proteger las notas de FaceID
    static let UD_setting_DiarioSiempreOpenFaceID   = "setting_DiarioSiempreOpenFaceID" //Permitir que la ventana del Diario permanezca desbloqueada
    
  
   
    
    //UserDefault compartido:(UD_shared_)
    static let UD_shared_FraseWidgetActual = "FraseWidgetActual" //Donde se almacena la frase actualmente cargada en el widget
    
    
    //Variables booleanas para determinar si el contenido de las ventanas se muestren el Details
    static let UD_setting_showEnDetails_diario          = "setting_showEnDetails_diario"
    static let UD_setting_showEnDetails_evaluacion      = "setting_showEnDetails_evaluacion"
    static let UD_setting_showEnDetails_ajustes         = "setting_showEnDetails_ajustes"
    static let UD_setting_showEnDetails_chat_ia         = "setting_showEnDetails_chat_ia"
    
    
    
    //DeepLinks:
    static let DeepLink_url_Diario  = "widget:/com.ypg.nev.diario"
    static let DeepLink_url_Notas   = "widget:/com.ypg.nev.notas"
    static let DeepLink_url_Frase   = "widget:/com.ypg.nev.frase"
    
    //Lleva un registro con las interacciones del usuario para mostrar una ventana de reseña
    static let UD_setting_ReviewCounter     = "UD_setting_ReviewCounter" //Contador de hitos
    static let UD_setting_showReview        = "UD_setting_showReview"   //Si es 1, se muestra la ventana, si es 2  no se muestra la ventana de review
    
    //IA:
    static let UD_setting_IA_AceptacionDescargo  = "AceptacionDescargoIA"  //Aceptación del Descargo de Responsabilidad(true : Acepto, false : No acepto). La funciones de IA dependerán de este acuerdo aceptado.
    static let UD_setting_IA_TratamientoPersonal = "setting_IA_TratamientoPersonal" //Especifica si la IA puede interpretar el papel de un Maestro Personal
    
    #if os(macOS)
    //Tamaños de ventana para la función showWindow en macOS:
    static let windows_size_content : WindowSize = .percentage(width: 0.45, height: 0.53)
    static let windows_size_content_small : WindowSize = .absolute(CGSize(width: 900, height: 400))
    #endif
    
    //Devuelve un valor centalizado que indica si todas las ventanas flotantes son modales o no
    /*
     -Actualmente esta función no esta en uso.
     -Deberia implementarse en Ajustes para darle al usuario la posibilidad de establecer todas las ventanas a No modales para tenerlas como ventanas independientes. O a todas modales, para inhabilitar interacción con la ventana padre
     */
    static func getIsWindowsModals() -> Bool {
        return UserDefaults.standard.bool(forKey: "isAllWindowsModals")
    }
   
    
    //Descargo de responsabilidad para la utilización de la IA generativa en el dispositivo:
    static let DescargoDeResposabilidad = """
                Descargo de Responsabilidad:\n
                
                🟣 La Inteligencia Artificial, IA en lo adelante, puede generar respuestas imprecisas o con errores.
                
                🟣 El usuario es el único responsable de la verificación y aplicación
                de la respuesta generada por IA.
                
                🟣 El desarrollador no es responsable por  los daños o pérdidas derivadas del uso o imposibilidad de uso del contenido generado por IA.
                
                🟣 Para hacer uso de la IA debe aceptar estas condiciones.
                
                Nota: Este Descargo de Responsabilidad estará disponible en Ajustes.
                """
    
}

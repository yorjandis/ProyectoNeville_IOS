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
    static let appVersion   = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String //Versión actual de la app
    
    static let AppGroupName = "group.com.ypg.nev.group" //Nombre del contenedor AppGroup compartido

    //NameFile: Neville
    static let FileListFrases                   = "listfrases"
    static let FileBiografiaNeville             = "biografia"
    static let FileResumenEnseñanzaNeville      = "resumen_enseñanza_nevile"
    
    //NameFile: Joe Dispenza
    static let FileListFrasesJD                 = "listfrases_jd"
    static let FileBiografiaJD                  = "biografia_jd"
    static let FileResumenDejaDeSerTu           = "resumen_libro_dejadesertu"
    static let FilePlanDejaDeSerTu              = "plan_libro_dejadesertu"
    static let FileResumenDesarrollaTuCerebro   = "resumen_libro_desarrollatucerebro"
    static let FilePlanDesarrollaTuCerebro      = "plan_libro_desarrollatucerebro"
    static let FileResumenElPLaceboEresTu       = "resumen_libro_elplaceboerestu"
    static let FilePlanElPlaceboEresTu          = "plan_libro_elplaceboerestu"
    static let FileResumenSuperNatural          = "resumen_libro_supernatural"
    static let FilePlanSupernarural             = "plan_libro_supernatural"
    static let FileResumenEnseñanzaJD           = "resumen_enseñanza_jd"
    
    //NameFile: Gregg Braden
    static let FileListFrasesGregg                  = "listfrases_de_gregg"
    static let FileBiografiaGregg                   = "biografia_gregg"
    static let FileResumenEnseñanzaGregg            = "resumen_enseñanza_gregg"
    static let FileResumenLaMatrizDivinaGregg       = "resumen_libro_lamatrizdivina"
    static let FilePlanLaMatrizDivinaGregg          = "plan_libro_lamatrizdivina"
    static let FileResumenResilenciaCorazonGregg    = "resumen_libro_resiliencia_desde_corazon"
    static let FilePlanResilenciaCorazonGregg       = "plan_libro_resiliencia_desde_corazon"
    static let FileResumenPuramenteHumanosGregg     = "resumen_libro_puramente_humanos"
    static let FilePlanPuramenteHumanosGregg        = "plan_libro_puramente_humanos"
   
    
    
    //NameFile: Bruce Lipton
    static let FileListFrasesBruceL             = "listfrases_bruce"
    static let FileBiografiaBruce               = "biografia_bruce"
    static let FileResumenEnseñanzaBruce        = "resumen_enseñanzas_bruce"
    static let FileResumenBiologiaCreencia      = "resumen_libro_biologiacreencia"
    static let FilePlanBiologiaCrrencia         = "plan_libro_biologiacreencia"
    
    
    //Fichero de Frases de Otros Autores:
    static let FileListFrasesOtros            = "listfrases_otros"
    
    //Fichero de Frases para temas de Salud:
    static let FileListFrasesSalud            = "listfrases_salud"
    
    //name values for setting:
    static let UD_setting_fontFrasesSize   = "setting_fontFrasesSize"
    static let UD_setting_fontContentSize  = "setting_fontContentSize"
    static let UD_setting_fontMenuSize     = "setting_fontMenuSize"
    static let UD_setting_fontListaSize    = "setting_fontListaSize"
    static let UD_setting_fontReminder    = "setting_fontReminder"
    static let UD_setting_fontChatIASize   = "setting_fontChatIASize" //Tamaño de letra del chat de IA
    
    //Opciones de Frases En Setting
    static let UD_setting_showHide_autor_in_frases  : String = "setting_showHide_autor_in_frases"
 
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
    static let UD_setting_DiarioAccesoAjustes       = "setting_DiarioAccesoAjustes" //Bloquea/desbloquea la opción en Ajustes para lógica de loguin del Diario
  
   //Theme
    static let UD_setting_theme                     = "setting_theme"    //Theme light/dark
    
    //UserDefault compartido:(UD_shared_)
    static let UD_shared_FraseWidgetActual = "FraseWidgetActual" //Donde se almacena la frase actualmente cargada en el widget
    
    
    //Variables booleanas para determinar si el contenido de las ventanas se muestren el Details
    static let UD_setting_showEnDetails_diario          = "setting_showEnDetails_diario"
    static let UD_setting_showEnDetails_evaluacion      = "setting_showEnDetails_evaluacion"
    static let UD_setting_showEnDetails_ajustes         = "setting_showEnDetails_ajustes"
    static let UD_setting_showEnDetails_chat_ia         = "setting_showEnDetails_chat_ia"
    
    //Variable que almacena el número de Frases inbuilt Actualmente:
    static let UD_FrasesInbuilt_Count           = "UD_FrasesInbuilt_Count"
    
    //Para filtrar las Frases que se mostraran en el Home
    static let UD_FiltroFrasesHome : String = "FiltroFrasesHome"
    
    
    
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

    //Descargo de responsabilidad para la utilización de la IA generativa en el dispositivo:
    static let DescargoDeResposabilidad = """
                Condiciones de Uso de la Inteligencia Artifical:\n
                
                La Inteligencia Artificial, IA en lo adelante, puede generar respuestas imprecisas o con errores.
                
                Para hacer uso de la IA debe aceptar las siguientes condiciones:
                
                🟣 El usuario es el único responsable de la verificación y aplicación
                de la respuesta generada por IA.
                
                🟣 El desarrollador no es responsable por  los daños o pérdidas derivadas del uso o imposibilidad de uso del contenido generado por IA.
                 
                Este Descargo de Responsabilidad estará disponible en Ajustes.
                
                """
    
    
    static let zspNota  = "\u{200B}\u{200B}\u{200B}" //Prefijo oculto en formato importación de Notas
    static let zspFrase = "\u{2063}\u{2063}\u{2063}" //Prefijo oculto en formato importación de Frases

    
    //Claves UserDefault para las funciones de popular la tabla frase
    static let UD_ProgresoUI_PopulandoFrases : String = "PoulandoFrases"
    static let UD_TablaFrasesPopulada : String = "TablaFrasesPopulada"
    
    
    
}



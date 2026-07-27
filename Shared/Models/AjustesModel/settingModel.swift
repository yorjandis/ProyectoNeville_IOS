//
//  settingModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 30/10/23.
//
//Maneja las configuraciones de Setting

//Esta clase se pasará como un objeto de enviroment a toda la jerarquia de vista a nivel de la App.
import SwiftUI
import Combine

@MainActor
final class SettingModel : ObservableObject {
    
    @Published var colorfrase : Color = .black
    @Published var colorFondo_a : Color = .purple
    @Published var colorFondo_b : Color = .blue.opacity(0.5)
    
    init(){
        //Cargando los últimos colores almacenados en UserDefault:
        Task{
            await LoadLastColors()
        }
       
    }
    
    //Almacena un color y actualiza las variables
     func saveColor(forkey: String, color : Color) {
        let cgColor = UIColor(color).cgColor
        let components = cgColor.components ?? []
        let rgba: [CGFloat]

        if cgColor.colorSpace?.model == .monochrome,
           let white = components.first {
            rgba = [
                white,
                white,
                white,
                components.count > 1 ? components[1] : 1
            ]
        } else if components.count >= 4 {
            rgba = Array(components.prefix(4))
        } else if components.count == 3 {
            rgba = [components[0], components[1], components[2], 1]
        } else if let white = components.first {
            rgba = [white, white, white, 1]
        } else {
            return
        }

        UserDefaults.standard.setValue(rgba, forKey: forkey)
         
         //Actualizando las variables Observables
         switch forkey {
             case AppCons.UD_setting_color_main_a:
             self.colorFondo_a = color
         case AppCons.UD_setting_color_main_b:
             self.colorFondo_b = color
         case AppCons.UD_setting_color_frases:
             self.colorfrase = color
         default:
             break
         }
         
    }
    
    //Devuelve el valor de un color como Color para una clave en userdefault. Por defecto devuelve el color primario en el sistema
    static func loadColor(forkey: String)->Color?{
        guard let components = UserDefaults.standard.object(
            forKey: forkey
        ) as? [CGFloat],
              !components.isEmpty else {
            return nil
        }

        if components.count >= 4 {
            return Color(
                .sRGB,
                red: components[0],
                green: components[1],
                blue: components[2],
                opacity: components[3]
            )
        }
        if components.count == 3 {
            return Color(
                .sRGB,
                red: components[0],
                green: components[1],
                blue: components[2],
                opacity: 1
            )
        }
        let white = components[0]
        let opacity = components.count > 1 ? components[1] : 1
        return Color(
            .sRGB,
            red: white,
            green: white,
            blue: white,
            opacity: opacity
        )
    }
    

    

    ///Establece los valores por defecto para setting
    func setValuesByDefault(){
        UserDefaults.standard.setValue(30, forKey: AppCons.UD_setting_fontFrasesSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontContentSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontMenuSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontListaSize)
        UserDefaults.standard.setValue(false, forKey: AppCons.UD_setting_NotasFaceID)
        UserDefaults.standard.setValue(5, forKey: AppCons.UD_setting_HomeProductividadPresenciaTotal)
        UserDefaults.standard.setValue(1, forKey: AppCons.UD_setting_HomeProductividadMetasTotal)
        UserDefaults.standard.setValue(1, forKey: AppCons.UD_setting_HomeProductividadDiarioTotal)
        UserDefaults.standard.setValue(0, forKey: AppCons.UD_setting_ReviewCounter) //Lleva un conteo de interacciones con el usuario, si llega a 150 se muestra una ventana de review y se resetea
        UserDefaults.standard.setValue(1, forKey: AppCons.UD_setting_showReview) //Lleva un conteo de interacciones con el usuario, si llega a 150 se muestra una ventana de review y se resetea
        
        saveColor(forkey: AppCons.UD_setting_color_frases, color: .black)
        saveColor(forkey: AppCons.UD_setting_color_main_a, color: .purple)
        saveColor(forkey: AppCons.UD_setting_color_main_b, color: .blue.opacity(0.5))
        saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: .gray) //Color de fondo del ContentTxt
        saveColor(forkey: AppCons.UD_setting_color_textContent, color: .black) //Color de texto del ContentTxt
        saveColor(
            forkey: AppCons.UD_setting_colorIA_main_a,
            color: AppCons.defaultColorIA_main_a
        )
        saveColor(
            forkey: AppCons.UD_setting_colorIA_main_b,
            color: AppCons.defaultColorIA_main_b
        )
        saveColor(
            forkey: AppCons.UD_setting_colorIA_textContent,
            color: AppCons.defaultColorIA_promptText
        )
        saveColor(
            forkey: AppCons.UD_setting_colorIA_textRespond,
            color: AppCons.defaultColorIA_responseText
        )
        saveColor(
            forkey: AppCons.UD_setting_colorIA_responseBubble,
            color: AppCons.defaultColorIA_responseBubble
        )
        
    }
    
    ///Actualiza las variables observables con los últimos colores almacenados:
    func LoadLastColors() async {
        self.colorfrase     = SettingModel.loadColor(forkey: AppCons.UD_setting_color_frases) ?? .primary
        self.colorFondo_a   = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .purple
        self.colorFondo_b   = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)    }
}

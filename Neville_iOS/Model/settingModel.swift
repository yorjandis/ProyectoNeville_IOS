//
//  settingModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 30/10/23.
//
//Maneja las configuraciones de Setting

//Esta clase se pasará como un objeto de enviroment a toda la jerarquia de vista a nivel de la App.
import SwiftUI

@MainActor
final class SettingModel : ObservableObject {
    
    @Published var colorfrase : Color = .black
    @Published var colorFondo_a : Color = .orange
    @Published var colorFondo_b : Color = .blue
    
    init(){
        //Cargando los últimos colores almacenados en UserDefault:
        Task{
            await LoadLastColors()
        }
       
    }
    
    //Almacena un color y actualiza las variables
     func saveColor(forkey: String, color : Color) {
        let colortemp = UIColor(color).cgColor
        
        if let components = colortemp.components {
            
            UserDefaults.standard.setValue(components, forKey: forkey)
        }
         
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
    static func loadColor(forkey: String)->Color{
        guard let userdefault = UserDefaults.standard.object(forKey: forkey) as? [CGFloat] else {
            return Color.primary
        }
        
        let color = Color(.sRGB, red: userdefault[0],
                                 green: userdefault[1],
                                 blue: userdefault[2],
                                 opacity:userdefault[3])
         
        return color
    }
    

    

    ///Establece los valores por defecto para setting
    func setValuesByDefault(){
        UserDefaults.standard.setValue(30, forKey: AppCons.UD_setting_fontFrasesSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontContentSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontMenuSize)
        UserDefaults.standard.setValue(18, forKey: AppCons.UD_setting_fontListaSize)
        UserDefaults.standard.setValue(false, forKey: AppCons.UD_setting_NotasFaceID)
        UserDefaults.standard.setValue(0, forKey: AppCons.UD_setting_ReviewCounter) //Lleva un conteo de interacciones con el usuario, si llega a 150 se muestra una ventana de review y se resetea
        UserDefaults.standard.setValue(1, forKey: AppCons.UD_setting_showReview) //Lleva un conteo de interacciones con el usuario, si llega a 150 se muestra una ventana de review y se resetea
        
        saveColor(forkey: AppCons.UD_setting_color_frases, color: .black)
        saveColor(forkey: AppCons.UD_setting_color_main_a, color: .red)
        saveColor(forkey: AppCons.UD_setting_color_main_b, color: .orange)
        saveColor(forkey: AppCons.UD_setting_color_fondoContent, color: .gray) //Color de fondo del ContentTxt
        saveColor(forkey: AppCons.UD_setting_color_textContent, color: .black) //Color de texto del ContentTxt
        
    }
    
    ///Actualiza las variables observables con los últimos colores almacenados:
    func LoadLastColors() async {
        self.colorfrase     = SettingModel.loadColor(forkey: AppCons.UD_setting_color_frases)
        self.colorFondo_a   = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a)
        self.colorFondo_b   = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b)
    }
}

//
//  settingModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 30/10/23.
//
//Maneja las configuraciones de Setting

import SwiftUI


struct SettingModel {
    
    //Devuelve un arreglo del color a almacenar
    func saveColor(forkey: String, color : Color) {
        let colortemp = UIColor(color).cgColor
        
        if let components = colortemp.components {
            
            UserDefaults.standard.setValue(components, forKey: forkey)
        }
        
       
        
    }
    
    //Devuelve el valor de un color como Color para una clave en userdefault. Por defecto devuelve el color primario en el sistema
    func loadColor(forkey: String)->Color{
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
        
        saveColor(forkey: AppCons.UD_setting_color_frases, color: .black)
        saveColor(forkey: AppCons.UD_setting_color_main_a, color: .red)
        saveColor(forkey: AppCons.UD_setting_color_main_b, color: .orange)
        
    }
    
    
}

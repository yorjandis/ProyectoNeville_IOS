//
//  settingView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 28/10/23.
//

import SwiftUI
import LocalAuthentication

struct settingView: View {
    
    @Environment(\.colorScheme) var theme
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)     var fontSizeFrases      : Int = 24
    @AppStorage(AppCons.UD_setting_fontContentSize)    var fontSizeContenido   : Int = 18
    @AppStorage(AppCons.UD_setting_fontMenuSize)       var fontSizeMenu        : Int = 18
    @AppStorage(AppCons.UD_setting_fontListaSize)      var fontSizeLista       : Int = 18
    @AppStorage(AppCons.UD_setting_NotasFaceID)        var setting_NotasFaceID : Bool = false
    
 
    @State var ColorFrase       : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_frases)
    @State var ColorPrimario    : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a)
    @State var ColorSecundario  : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)
    
    //Autenti
    private let contextLA = LAContext()
    @State var canOpenToggleButton = false
    @State var showAlert = false
    @State var alertMessage = ""
    

    var body: some View {
        NavigationStack{
            Form{
                
                Section("Tamaño de letra"){
                    HStack{
                        Text("Frases:")
                            .font(.system(size:CGFloat(fontSizeFrases)))
                        Spacer()
                        Stepper(String(fontSizeFrases), value: $fontSizeFrases)
                            
                    }
                    
                    HStack{
                        Text("Contenido:")
                            .font(.system(size:CGFloat(fontSizeContenido)))
                        Spacer()
                        Stepper(String(fontSizeContenido), value: $fontSizeContenido)
                           
                    }
                    
                    HStack{
                        Text("Menu:")
                            .font(.system(size:CGFloat(fontSizeMenu)))
                        Spacer()
                        Stepper(String(fontSizeMenu), value: $fontSizeMenu)
                            
                    }
                    
                    HStack{
                        Text("Listas:")
                            .font(.system(size:CGFloat(fontSizeLista)))
                        Spacer()
                        Stepper(String(fontSizeLista), value: $fontSizeLista)
                           
                    }
                    
                }.padding(2)
                    
                Section("Color de texto de frases"){
                    
                    ColorPicker("Color de frases", selection: $ColorFrase)
                        .foregroundColor(ColorFrase)
                        .bold()
                        .onChange(of: ColorFrase, initial: true) { oldValue, newValue in
                            SettingModel().saveColor(forkey: AppCons.UD_setting_color_frases, color: newValue)
                        }
                }
                
                Section("Color de fondo - Pantalla Principal"){
                    
                    VStack(alignment: .center){
                        ColorPicker("Color primario", selection: $ColorPrimario)
                            .onChange(of: ColorPrimario, initial: true) { oldValue, newValue in
                                SettingModel().saveColor(forkey: AppCons.UD_setting_color_main_a, color: newValue)
                            }
                            .padding(.bottom, 10)
                        ColorPicker("Color Secundario", selection: $ColorSecundario)
                            .onChange(of: ColorSecundario, initial: true) { oldValue, newValue in
                                SettingModel().saveColor(forkey: AppCons.UD_setting_color_main_b, color: newValue)
                            }
                        
                        Text("")
                            .frame(width: 200 ,  height: 60)
                            .background(LinearGradient(colors: [ColorPrimario, ColorSecundario], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        
                    }
                    .onAppear{
                        ColorFrase       = SettingModel().loadColor(forkey: AppCons.UD_setting_color_frases)
                        ColorPrimario    = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a)
                        ColorSecundario  = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)
                    }
                    
                    
                    
                }
                
                Section("Notas Generales"){
                    if canOpenToggleButton {
                        Toggle("Proteger las Notas con FaceID", isOn: $setting_NotasFaceID)
                    }else{
                        Button{
                            autent()
                        }label: {
                            Label("Opción protegida por FaceID", systemImage: "key.viewfinder")
                        }
                    }
                    
                }
                
                Section("Contacto & Información"){

                        ShareLink(item: URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696")!) {
                                Label("Compartir la App", image: "Icon-29")
                                .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                                .bold()
                                .font(.headline)
                                                    
                        }

                    Link(destination: URL(string:  "https://projectsypg.mozello.com/contacto/")!) {
                        Label("Enviarme un comentario", systemImage: "exclamationmark.warninglight.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    Link(destination: URL(string:  "https://projectsypg.mozello.com/productos/neville/")!) {
                        Label("Abrir página del proyecto", systemImage: "swiftdata")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }

                    Link(destination: URL(string:  "https://projectsypg.mozello.com/productos/neville/privacy-police-ios/")!) {
                        Label("Política de Privacidad", systemImage: "link")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }

                }
     
                .navigationTitle("Ajustes")
                .navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Configuración"), message: Text(alertMessage))
                }
 
            }
            
            
        }
    }
    
    
    func autent(){
        var error : NSError?
        if contextLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            contextLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor autentícate para tener acceso a su Diario") { success, error in
                        if success {
                             //Habilitación del contenido
                            withAnimation {
                                canOpenToggleButton = true
                            }
                            
                        } else {
                            print("Error en la autenticación biométrica")
                        }
                    }
            
            
        }else{
            alertMessage = "El dispositivo no soporta autenticación Biométrica. Se ha deshabilitado la protección del Diario"
            showAlert = true
            canOpenToggleButton = true //Deshabilitando la protección del Diario.
        }
    }
    
}



#Preview {
    settingView()
}

//
//  settingView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 28/10/23.
//

import SwiftUI
import LocalAuthentication
import CoreData

struct settingView: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    
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
    
    //Habilitar un botón en Ajustes para actualizar el nuevo contenido (importarlo a las BD)
    @State var showButtonUpdate = true // muestra/oculta el boton para actualizar nuevo contenido añadido al bundle
    
    //Permite ajustar en tiempo real los cambios en la UI home:
    @Binding var isSettingChanged : Bool
    
    
    //Otros
    @State private var showSheet : Int? = nil
    
    //Contadores de elementos:
    @State private var frasesCount          : Int = 0
    @State private var ayudasCount          : Int = 0
    @State private var preguntasCount       : Int = 0
    @State private var citasCount           : Int = 0
    @State private var conferenciasCount    : Int = 0

    

    var body: some View {
        
        NavigationStack{
            Form{
                Section("Tamaño de letra"){
                    HStack{
                        Text("Frases:")
                            .font(.system(size:CGFloat(fontSizeFrases)))
                        Spacer()
                        Stepper(String(fontSizeFrases), value: $fontSizeFrases)
                            .onChange(of: fontSizeFrases) { oldValue, newValue in
                                self.isSettingChanged.toggle() //Informa que se ha cambiado la setting
                            }
                        
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
                            self.isSettingChanged.toggle() //Informa a Home que se ha cambiado el color
                        }
                }
                
                Section("Color de fondo - Pantalla Principal"){
                    
                    VStack(alignment: .center){
                        ColorPicker("Color primario", selection: $ColorPrimario)
                            .onChange(of: ColorPrimario, initial: true) { oldValue, newValue in
                                SettingModel().saveColor(forkey: AppCons.UD_setting_color_main_a, color: newValue)
                                self.isSettingChanged.toggle() //Informa a Home que se ha cambiado el color
                            }
                            .padding(.bottom, 10)
                        ColorPicker("Color Secundario", selection: $ColorSecundario)
                            .onChange(of: ColorSecundario, initial: true) { oldValue, newValue in
                                SettingModel().saveColor(forkey: AppCons.UD_setting_color_main_b, color: newValue)
                                self.isSettingChanged.toggle() //Informa a Home que se ha cambiado el color
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
                    NavigationLink{
                        Form{
                            HStack{
                                Text("Versión")
                                Spacer()
                                Text("\(AppCons.appVersion ?? "")")
                                    .foregroundStyle(.orange).bold()
                            }
                            HStack{
                                Text("Frases")
                                Spacer()
                                Text("\(self.frasesCount)")
                            }.onTapGesture {self.showSheet = 1}
                            HStack{
                                Text("Conferencias")
                                Spacer()
                                Text("\(self.conferenciasCount)")
                            }.onTapGesture {self.showSheet = 2}
                            HStack{
                                Text("Citas")
                                Spacer()
                               Text("\(citasCount)")
                            }.onTapGesture {self.showSheet = 3}
                            HStack{
                                Text("Preguntas")
                                Spacer()
                                Text("\(self.preguntasCount)")
                            }.onTapGesture {self.showSheet = 4}
                            HStack{
                                Text("Ayudas")
                                Spacer()
                                Text("\(self.ayudasCount)")
                                    
                            }.onTapGesture {self.showSheet = 5}

                            HStack{
                                Text("Reflexiones")
                                Spacer()
                                Text("\(RefexModel().GetRequest(predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 6}
                            
                            HStack{
                                Text("Cuestionario")
                                Spacer()
                                Text("\(UtilFuncs.FileReadToArray("cuestionario").count)")
                            }.onTapGesture {self.showSheet = 7}
                            
                        }
                        .task{
                            self.frasesCount = FrasesModel().GetRequest(predicate: nil).count
                            self.conferenciasCount = TxtContentModel().GetRequest(context: self.context, type: .conf, predicate: nil).count
                            self.citasCount = TxtContentModel().GetRequest(context: self.context, type: .citas, predicate: nil).count
                            self.preguntasCount = TxtContentModel().GetRequest(context: self.context, type: .preg, predicate: nil).count
                            self.ayudasCount = TxtContentModel().GetRequest(context: self.context, type: .ayud, predicate: nil).count
                        }
                        .navigationTitle("Ajustes - Información")
                    }label: {
                        Label("Información", systemImage: "info.circle.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                    }
                    
                    NavigationLink{
                        NavigationStack{
                            ScrollView{
                                Text(UtilFuncs.FileRead("privacy"))
                            }.navigationTitle("Ajustes - Privacy")
                        }
                    }label:{
                        Label("Política de Privacidad", systemImage: "square.and.pencil.circle")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    
                    ShareLink(item: URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696")!) {
                        Label("Compartir la App", image: "Icon-29")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                        
                    }
                    NavigationLink{
                        FeedbackView(showTextBotton: false)
                    }label:{
                       Label("Deja una reseña!", systemImage:"bolt.heart.fill" )
                    }
                    
                    Link(destination: URL(string: "mailto:info@ypgcode.es")!) {
                        Label("Enviar Email", systemImage: "envelope.fill")
                    }
                    .font(.headline)
                    
                    Link(destination: URL(string:  "https://ypgcode.es/la-ley-neville-goddard/")!) {
                        Label("Abrir página del proyecto", systemImage: "swiftdata")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    Link(destination: URL(string:  "https://paypal.me/Yorpg?country.x=ES&locale.x=es_ES")!) {
                        Label("Donar para este proyecto", systemImage: "dollarsign.circle.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    
                    
                    
                    
                    
                    
                }
                
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Configuración"), message: Text(alertMessage))
                }
                
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .sheet(item: $showSheet) { details in
            switch details {
            case 1:
                FrasesListView()
            case 2:
                TxtListView( typeOfContent: .conf, title: "Lecturas")
            case 3:
                TxtListView( typeOfContent: .citas, title: "Citas")
            case 4:
                TxtListView( typeOfContent: .preg, title: "Preguntas")
            case 5:
                TxtListView( typeOfContent: .ayud, title: "Ayudas")
            case 6:
                ReflexListView()
            case 7:
                GamePLay()
            default :
                EmptyView()
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

extension Int: @retroactive Identifiable {
    public var id: Int { return self }
}


#Preview {
    settingView(isSettingChanged: .constant(true))
}

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
    @Environment(\.dismiss) var dismiss
    
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
                
                Section("Actualización de Contenido"){
                    VStack(alignment: .leading){
                        if showButtonUpdate {
                            Button("Actualizar Contenido!"){
                                
                                Task{
                                    //LLamar a todas las funciones de actualización de contenido
                                    let NoElementFrases =  FrasesModel().UpdateContenAfterAppUpdate()
                                    
                                    //Para elementos con prefijos:
                                    let NoElementConf   =  TxtContentModel().UpdateContenAfterAppUpdate(type: .conf)
                                    
                                    // let NoElementCitas  =   TxtContentModel().UpdateContenAfterAppUpdate(type: .citas)
                                    // let NoElementPreg   =   TxtContentModel().UpdateContenAfterAppUpdate(type: .preg)
                                    let NoElementAyuda  = TxtContentModel().UpdateContenAfterAppUpdate(type: .ayud)
                                    
                                    let NoElementReflex = RefexModel().UpdateContenAfterAppUpdate()
                                    
                                    self.alertMessage = """
                                    Se han adicionado:
                                    \(NoElementFrases.0) \\ \(NoElementFrases.1) frases
                                    \(NoElementConf.0) \\ \(NoElementConf.1) Conferencias
                                    \(NoElementAyuda.0) \\ \(NoElementAyuda.1) Ayudas
                                    \(NoElementReflex.0) \\ \(NoElementReflex.1) Reflexiones
                                    """
                                    self.showAlert = true
                                    
                                }
                                
                            }
                            .padding(5)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                        Text("Si existe nuevo contenido esta opción se habilitará. Un solo uso es suficiente")
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                    
                    
                    
                }
                
                Section("Manteniemiento"){
                    VStack(alignment: .leading){
                        NavigationLink("Eliminar duplicados"){
                            VStack{
                                Text("Si ha instalado la app anteriormente, es posible que el contenido no se sincronice correctamente con iCloud. Esta situación origina elementos duplicados en Frases, Conferencias, Citas, Preguntas, Ayudas y Reflexiones. Las cáusas pueden deberse a que iCloud no esta iniciado en el momento de la instalación entre otros...Para solucionar este problema y eliminar con seguridad los elementos duplicados utilice el botón debajo. Esto restaura los listados sin perder la información personal como notas o favoritos")
                                    .font(.system(size: 20))
                                    .fontDesign(.serif)
                                    .padding(20)
                                Button("Eliminar Duplicados"){
                                    FrasesModel().Fix_DeleteDuplicatesRowsInBDCoreDataForfrases()
                                    TxtContentModel().Fix_DeleteDuplicatesRowsInBDCoreDataForConf()
                                    RefexModel().Fix_DeleteDuplicatesRowsInBDCoreDataForReflex()
                                    self.alertMessage = "Los elementos duplicados se han borrado correctamente. Si el problema persiste, utilice la sección de contacto en Ajustes para enviar un mensaje al desarrollador"
                                    self.showAlert = true
                                }
                                .buttonStyle(.borderedProminent)
                                Spacer()
                                    .navigationTitle("Ajustes - Eliminar Duplicados")
                                
                            }
                        }
                        Text("Eliminar elementos duplicados")
                            .font(.footnote)
                            .foregroundStyle(.gray)
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
                                Text("\(FrasesModel().GetRequest(predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 1}
                            HStack{
                                Text("Conferencias")
                                Spacer()
                                Text("\(TxtContentModel().GetRequest(type: .conf, predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 2}
                            HStack{
                                Text("Citas")
                                Spacer()
                                Text("\(TxtContentModel().GetRequest(type: .citas, predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 3}
                            HStack{
                                Text("Preguntas")
                                Spacer()
                                Text("\(TxtContentModel().GetRequest(type: .preg, predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 4}
                            HStack{
                                Text("Ayudas")
                                Spacer()
                                Text("\(TxtContentModel().GetRequest(type: .ayud, predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 5}

                            HStack{
                                Text("Reflexiones")
                                Spacer()
                                Text("\(RefexModel().GetRequest(predicate: nil).count)")
                            }.onTapGesture {self.showSheet = 6}
                            
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
                        Label("Política de Privacidad", systemImage: "hand.raised.circle")
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
                    
                    Link(destination: URL(string:  "https://ypg.mozello.com/contacto/")!) {
                        Label("Enviarme un comentario", systemImage: "exclamationmark.warninglight.fill")
                            .foregroundStyle(theme == ColorScheme.dark ? .white : .black)
                            .bold()
                            .font(.headline)
                    }
                    Link(destination: URL(string:  "https://ypg.mozello.com/productos/neville/")!) {
                        Label("Abrir página del proyecto", systemImage: "swiftdata")
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
                TxtListView( type: .conf, title: "Lecturas")
            case 3:
                TxtListView( type: .citas, title: "Citas")
            case 4:
                TxtListView( type: .preg, title: "Preguntas")
            case 5:
                TxtListView( type: .ayud, title: "Ayudas")
            case 6:
                ReflexListView()
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

extension Int: Identifiable {
    public var id: Int { return self }
}


#Preview {
    settingView(isSettingChanged: .constant(true))
}

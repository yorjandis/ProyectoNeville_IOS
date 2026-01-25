//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

fileprivate enum TipeViewOptionTab : String,  Identifiable{
    //Recursos didáctivos y productividad:
    case notas, diario, lienzo,metas, frases, codeScanner, codeGenerate, game,ayudas, reflex, setting, reminder, premium, evidenciaCientifica, enciclopedia
    //Neville:
    case biografiaNeville,  frasesNeville, conferenciasNeville, citasNevile, preguntasNeville, resumenEnseñanzaNeville
    //Joe Dispenza
    case biografiaJD,frasesJD,resumenDejaDeSerTu, planDejaDeSerTu,resumenDesarrollaTuCerebro,planDesarrollaTuCerebro
    case resumenElPlaceboEresTu, planElPlacevoEresTu,resumenSuperNatural,planSuperNatural
    case resumenEnseñanzaJD
    //Gregg Braden
    case biografiaGregg, FrasesGregg
    case resumenEnseñanzaGregg
    //Bruce Lipton
    case biografíaBruceL,FrasesBruceL
    case resumenEnseñanzaBruceL
    case resumenLibroBiologiaCreencia, planLibroBiologiaCreencia
    //Cases Futuros
   // case resumenEnseñanzaNeville, ResumenEnseñanzaGregg, ResumenEnseñanzaBruceL
    var id: String { rawValue }
}




struct optionView: View {
    
    @EnvironmentObject var settingModel: SettingModel

    @State private var showView : TipeViewOptionTab?  = nil

    private let sizeWigth : CGFloat = 150
    
    struct QRText: Identifiable {
        let id = UUID()
        let text: String
    }
    
    @State private var footerToQRCode : QRText?
    
    var body: some View {
        NavigationStack{
            
            VStack{
                HStack{
                    Menu{
                        Button("Conferencias"){self.showView = .conferenciasNeville}
                        Menu("Apoyo al estudio"){
                            Button("Citas"){self.showView = .citasNevile}
                            Button("Preguntas"){self.showView = .preguntasNeville}
                            Button("Evaluación"){self.showView = .game}
                        }
                        Button("Frases"){self.showView = .frasesNeville}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaNeville}
                        Button("Bibliografía"){self.showView = .biografiaNeville}
                        Text("----Neville Goddard----").bold()
                    }label: {
                        Text("Neville Goddard")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Menu{
                        Button("Ayudas"){self.showView = .ayudas}
                        Button("Reflexiones"){self.showView = .reflex}
                        Button("Evidencia Científica"){self.showView = .evidenciaCientifica}
                        Button("Enciclopedia"){self.showView = .enciclopedia}
                        Button("Notas"){self.showView = .notas}
                        Button("Frases"){self.showView = .frases}
                        
                    }label: {
                        Text("Recursos Didácticos")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(5)
                .padding(.top, 10)
                
                HStack{
                    Menu{
                        Button("Resumen de Charlas"){}
                        Button("Resumen de Meditaciones"){}
                        //Button("Resumen de Talleres"){}
                        Menu("Análisis de Libros:"){
                            Menu("Desarrolla Tu Cerebro"){
                                Button("Resumen"){self.showView = .resumenDesarrollaTuCerebro}
                                Button("Práctica"){self.showView = .planDesarrollaTuCerebro}
                            }
                            Menu("Deja De Ser Tu"){
                                Button("Resumen"){self.showView = .resumenDejaDeSerTu}
                                Button("Práctica"){self.showView = .planDejaDeSerTu}
                            }
                            Menu("El Placebo Eres Tu"){
                                Button("Resumen"){self.showView = .resumenElPlaceboEresTu}
                                Button("Práctica"){self.showView = .planElPlacevoEresTu}
                            }
                            Menu("SobreNatural"){
                                Button("Resumen"){self.showView = .resumenSuperNatural}
                                Button("Práctica"){self.showView = .planSuperNatural}
                            }
                        }
                        Button("Frases"){self.showView = .frasesJD}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaJD}
                        Button("Bibliografía"){self.showView = .biografiaJD }
                        Text("----Dr. Joe Dispenza----").bold()
                    }label: {
                        Text("Joe Dispenza")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Menu{
                        Button("Lienzo"){self.showView = .lienzo}
                        Button("Recordatorios"){self.showView = .reminder}
                        Button("Metas"){self.showView = .metas}
                        Button("Lector QR"){self.showView = .codeScanner}
                        Button("Generador QR"){self.showView = .codeGenerate}
                    }label: {
                        Text("Productividad")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                }
                .padding(5)
                
                HStack{
                    Menu{
                        
                        Button("Resumen de Charlas"){}
                        Menu("Análisis de Libros:"){
                            Button("La Matríz Divina"){}
                            Button("La Curación Expontánea de las Creencias"){}
                        }
                        Button("Frases"){}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaGregg}
                        Button("Bibliografía"){self.showView = .biografiaGregg}
                        Text("----Gregg Braden----").bold()
                    }label: {
                        Text("Gregg Braden")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Button{
                        self.showView = .setting
                    }label:{
                        Text("Ajustes")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                        
                    
                }
                .padding(5)
                
                
                HStack{
                    Menu{
                        
                        Button("Resumen de Charlas"){}
                        Menu("Análisis de Libros:"){
                            Menu("La Biolgía de la Creencia"){
                                Button("Resumen"){self.showView = .resumenLibroBiologiaCreencia}
                                Button("Práctica"){self.showView = .planLibroBiologiaCreencia}
                            }
                            
                        }
                        Button("Frases"){}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaBruceL}
                        Button("Bibliografía"){self.showView = .biografíaBruceL}
                        Text("----Dr. Bruce Lipton----").bold()
                    }label: {
                        Text("Bruce Lipton")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    Button{
                        self.showView = .premium
                    }label: {
                        Text("La ley Premium")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                        
                        
                    
                }
                .padding(5)
                

            }
            .padding(10)
            .buttonStyle(.bordered)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            
        }
        .preferredColorScheme(.dark)
        .background(LinearGradient.AzulTecnologico())
        .sheet(item: self.$showView, content: { item in
            VStack{
                switch item{
                case .setting:
                    Ajustes()
                case .notas:
                    ListNotasViews()
                case .biografiaNeville:
                    ContentTxtShowView(title: "Biografía", nombreTxt: AppCons.FileBiografiaNeville, type: .NA )
                case .preguntasNeville:
                    TxtListView(typeOfContent: .preg, title: "Preguntas")
                case .citasNevile:
                    TxtListView(typeOfContent: .citas, title: "Citas")
                case .ayudas:
                    TxtListView(typeOfContent: .ayud, title: "Ayudas")
                case .reflex:
                    ReflexListView()
                case .diario:
                    DiarioListView()
                case .lienzo:
                    LienzoMain(texto: "")
                case .premium:
                    PurchaseView()
                case .conferenciasNeville:
                    TxtListView(typeOfContent: .conf, title: "Conferencias")
                    
                case .frasesNeville:
                    FrasesListView(mostrarFrasesDe: .nev)
                    
                case .codeScanner:
                    //Mostrar el lector de código
                    CodeScannerView(codeTypes: [.qr]) { qrCodeString in
                        do{
                            let result =  try qrCodeString.get().string
                            self.footerToQRCode = QRText(text: result)
                            
                        }catch{
                            
                        }
                        
                    }
                case .codeGenerate:
                    GenerateQRView(footer: "")
                case .game:
                    GamePLay()
                case .reminder:
                    ReminderListView()
                case .metas:
                    GoalsListView()
                case .biografiaJD:
                    ContentTxtShowView(title: "Biografía Joe Dispenza", nombreTxt: AppCons.FileBiografiaJD, type: .NA )
                case .biografiaGregg:
                    ContentTxtShowView(title: "Biografía Gregg Braden", nombreTxt: AppCons.FileBiografiaGregg, type: .NA )
                case .biografíaBruceL:
                    ContentTxtShowView(title: "Biografía Dr. Bruce H. Lipton", nombreTxt: AppCons.FileBiografiaBruce, type: .NA )
                case .evidenciaCientifica:
                    VStack(spacing: 25){
                        Text("🚧 en Construcción...")
                        Text("Objetivo: Mostrar Evidencia y base científica sobre los temas abordados en estas enseñanzas.")
                        Text("Algunos de los temas que requieren una base científica (La lista puede cambiar):")
                        ScrollView{
                            Text("""
                                🔶Existencia del Campo Cuántico/Matriz Divina/Mente Universar/Dios
                                🔶El Pensamiento lleva energía e información
                                🔶Los Pensamiento influyen en nuestra biología
                                🔶Los pensamientos y emociones cambian la estructura física del cerebro
                                🔶Somos más energía que materia
                                🔶Entrelazamiento cuántico
                                🔶Un pensamiento produce la secreción de sustancias químicas
                                🔶El cuerpo puede almacenar una emoción
                                🔶Nuestras emociones pueden causar enfermedades
                                🔶Neuroplasticidad
                                🔶Neurogénesis
                                🔶El corazón emite una firma magnética
                                🔶El corazón tiene neuronas propias y piensa y siente independientemente
                                🔶La Coherencia cardiaca normaliza las frecuencias cerebrales
                                🔶El corazón influje en la quimica cerebral
                                🔶El ADN puede modificarse con nuestros pensamientos
                                🔶La epigenética señala al gen que crea la enfemedad
                                🔶Los pensamientos influyen en la expresión génica
                                🔶Los pensamientos y emociones negativas rompen la coherencia de ondas cerebrales
                                🔶El hombre lleva más tiempo sobre la tierra del que esta registrado en el pasado
                                """)
                        }
                    }
                case .frasesJD:
                    FrasesListView(mostrarFrasesDe: .jd)
                case .FrasesGregg:
                    EmptyView()
                case .FrasesBruceL:
                    EmptyView()
                case .frases:
                    FrasesListView()
                case .resumenDejaDeSerTu:
                    ContentTxtShowView(title: "Resumen del Libro: Deja De Ser Tu", nombreTxt: AppCons.FileResumenDejaDeSerTu, type: .NA )
                case .planDejaDeSerTu:
                    ContentTxtShowView(title: "Plan del Libro: Deja De Ser Tu", nombreTxt: AppCons.FilePlanDejaDeSerTu, type: .NA )
                case .resumenDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Resumen del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FileResumenDesarrollaTuCerebro, type: .NA )
                case .planDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Plan del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FilePlanDesarrollaTuCerebro, type: .NA )
                case .resumenElPlaceboEresTu:
                    ContentTxtShowView(title: "Resumen del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FileResumenElPLaceboEresTu, type: .NA )
                case .planElPlacevoEresTu:
                    ContentTxtShowView(title: "Plan del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FilePlanElPlaceboEresTu, type: .NA )
                case .resumenSuperNatural:
                    ContentTxtShowView(title: "Resumen del Libro: SobreNatural", nombreTxt: AppCons.FileResumenSuperNatural, type: .NA )
                case .planSuperNatural:
                    ContentTxtShowView(title: "Plan del Libro: SobreNatural", nombreTxt: AppCons.FilePlanSupernarural, type: .NA )
                case .resumenEnseñanzaJD:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaJD, type: .NA )
                case .resumenEnseñanzaNeville:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Neville Goddard", nombreTxt: AppCons.FileResumenEnseñanzaNeville, type: .NA )
                case .resumenEnseñanzaGregg:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaGregg, type: .NA )
                case .resumenEnseñanzaBruceL:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaBruce, type: .NA )
                case .enciclopedia:
                    EnciclopediaListView()
                    
                case .resumenLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Resumen del Libro: La Biología De La Creencia", nombreTxt: AppCons.FileResumenBiologiaCreencia, type: .NA )
                case .planLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Plan del Libro: La Biología De La Creencia", nombreTxt: AppCons.FilePlanBiologiaCrrencia, type: .NA )
                }
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            
        })
        /*
         .sheet(isPresented: $showNotasSheet) {
             ListNotasViews()
         }
         .sheet(isPresented: $showBiografia) {
             ContentTxtShowView(title: "Biografía", nombreTxt: "biografia", type: .NA )
         }
         .sheet(isPresented: $showPreguntas) {
             TxtListView(typeOfContent: .preg, title: "Preguntas")
         }
         .sheet(isPresented: $showCitas) {
             TxtListView(typeOfContent: .citas, title: "Citas")
         }
         .sheet(isPresented: $showAyudas) {
             TxtListView(typeOfContent: .ayud, title: "Ayudas")
         }
         .sheet(isPresented: $showReflex) {
             ReflexListView()
         }
         .sheet(isPresented: $showDiarioSheet) {
             DiarioListView()
         }
         .sheet(isPresented: $showLienzoSheet) {
             LienzoMain(texto: nil)
         }
         .sheet (isPresented: $showFrasesList){
             FrasesListView()
         }
         .sheet(isPresented: $showSetting){
             Ajustes()
                 .presentationDetents([.large])
         }
         .sheet(isPresented: $showCodeScanner){
             //Mostrar el lector de código
             CodeScannerView(codeTypes: [.qr]) { qrCodeString in
                 do{
                   let result =  try qrCodeString.get().string
                     self.footerToQRCode = QRText(text: result)
                    
                 }catch{
                     
                 }
                 
             }
            
         }
         .sheet(item: $footerToQRCode){ item in
             GenerateQRView(footer: item.text)
                 .presentationDetents([.large])
                 .presentationDragIndicator(.hidden)
         }
         .sheet(isPresented: $showCodeGenerate){
            
                 GenerateQRView(footer: "")
                     .presentationDetents([.large])
                     .presentationDragIndicator(.hidden)
             
             
         }
         .sheet(isPresented: $showGame){
             GamePLay()
                 .presentationDetents([.large])
                 .presentationDragIndicator(.hidden)
         }
         .sheet(isPresented: self.$showReminder) {
             ReminderListView()
         }
         */
        
    }
    
    
    /*
     @ViewBuilder
     func primerGroup()-> some View{
         VStack(spacing: 20){
             HStack(spacing: 20){
                 
                 Button{
                     showReflex = true
                 }label: {
                     bloqueA("infinity", "Reflexiones")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Button{
                     showAyudas = true
                 }label: {
                     bloqueA("flag.2.crossed.fill", "Ayudas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             .padding(.top, 20)
             
             HStack(spacing: 20){
                 
                 Button{
                     showLienzoSheet = true
                 }label: {
                     bloqueA("heart.text.square", "Lienzo")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
                 
                 Button{
                     showFrasesList = true
                 }label: {
                     bloqueA("bookmark.fill", "Frases")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             
             HStack(spacing: 20){
                 Button{
                     showCitas = true
                 }label: {
                     bloqueA("doc.append", "Citas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Button{
                     showSetting = true
                 }label: {
                     bloqueA("gear", "Ajustes")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
             }
             Spacer()
             
             HStack{
                 
                 Spacer()
                 
                 Text ("     Inicio")
                     .font(.title2)
                     .fontDesign(.serif)
                 
                 Spacer()
                 
             }
             .padding(.vertical, 0)
             
             
             
         }
         
     }
     
     
     @ViewBuilder
     func  segundoGrupo()-> some View {
         VStack(spacing: 20){
             
             HStack(spacing: 20){
                 Button{
                     showBiografia = true
                 }label: {
                     bloqueA("person.text.rectangle", "Bibliografia")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Link(destination: URL(string: "https://t.me/+rODRAz2S6nVmMmY0")!){
                     bloqueA("personalhotspot", "Canal Telegram")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
             }
             .padding(.top, 20)
             HStack(spacing: 20){
                 Button{
                     showGame = true
                 }label: {
                     bloqueA("gamecontroller", "Evaluación")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 
                 Button{
                     showPreguntas = true
                 }label: {
                     bloqueA("questionmark.bubble", "Preguntas & Respuestas")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
             }
             HStack(spacing: 20){
                 
                 Button{
                     showReminder = true
                 }label: {
                     bloqueA("timer", "Recordatorios")
                 }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 
                 Menu{
                     Button{
                         //Mostrar el lector de QR
                         showCodeScanner = true
                     }label: {
                         bloqueA("qrcode.viewfinder", "Leer QR")
                     }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                     
                     Button{
                         showCodeGenerate = true
                     }label: {
                         bloqueA("qrcode", "Crear QR")
                     }.modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
                 }label: {
                     bloqueA("qrcode.viewfinder", "Funciones QR")
                 }
                 .modifier(GradientButtonStyle(ancho: sizeWigth, colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]))
             }
             Spacer()
             Text ("Recursos")
                 .font(.title2)
                 .fontDesign(.serif)
             
         }
     }
     
     */
    
    

    //auxiliar
    @MainActor
    @ViewBuilder
    private  func bloqueA( _ systemImagen : String, _ texto : String)-> some View{
        
        HStack {
            Image(systemName: systemImagen)
            Text(texto)
            Spacer()
        }
        .foregroundStyle(.black).bold()
        
    }
    
    
}





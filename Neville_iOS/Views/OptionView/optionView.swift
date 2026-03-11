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
    case resumenLaMatrizDivina, planLaMatrizDivina, resumenResilienciaDesdeCorazon, planResilienciaDesdeCorazon
    case resumenPuramenteHumanos, planPuramenteHumanos
    //Bruce Lipton
    case biografíaBruceL,FrasesBruceL
    case resumenEnseñanzaBruceL
    case resumenLibroBiologiaCreencia, planLibroBiologiaCreencia
    case serieEvolucionInterior_1, serieEvolucionInterior_2, serieEvolucionInterior_3, serieEvolucionInterior_4, serieEvolucionInterior_5
    case serieEvolucionInterior_6, serieEvolucionInterior_7, serieEvolucionInterior_8, serieEvolucionInterior_9, serieEvolucionInterior_10
    case serieEvolucionInterior_11, serieEvolucionInterior_12, serieEvolucionInterior_13
    
    //Cases Futuros
    case videosTutoriales
   
    var id: String { rawValue }
}




struct optionView: View {
    
    @EnvironmentObject var settingModel: SettingModel

    @State private var showView : TipeViewOptionTab?  = nil
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    

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
                    //Neville Goddard
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
                        Label("Neville Goddard", image: "nev-min")
                    }label: {
                        Text("Neville Goddard")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    //Recursos Didácticos
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
                    //Joe Dispenza
                    Menu{
                       // Button("Resumen de Charlas"){}
                       // Button("Resumen de Meditaciones"){}
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
                        Label("Dr. Joe Dispenza", image: "jd")
                    }label: {
                        Text("Joe Dispenza")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    //Herramientas
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
                    //Gregg Braden
                    Menu{
                       // Button("Resumen de Charlas"){}
                        Menu("Análisis de Libros:"){
                            Menu("La Matriz Divina"){
                                Button("Resumen"){self.showView = .resumenLaMatrizDivina}
                                Button("Práctica"){self.showView = .planLaMatrizDivina}
                            }
                            Menu("Resiliencia desde el Corazón"){
                                Button("Resumen"){self.showView = .resumenResilienciaDesdeCorazon}
                                Button("Práctica"){self.showView = .planResilienciaDesdeCorazon}
                            }
                            Menu("Puramente Humanos"){
                                Button("Resumen"){self.showView = .resumenPuramenteHumanos}
                                Button("Práctica"){self.showView = .planPuramenteHumanos}
                            }
                            
                        }
                        Button("Frases"){self.showView = .FrasesGregg}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaGregg}
                        Button("Bibliografía"){self.showView = .biografiaGregg}
                        Label("Gregg Braden", image: "gregg")
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
                    //Bruce Lipton
                    Menu{
                        
                        Menu("Resumen Serie: Evolución Interior"){
                            Button("Capitulo 13"){self.showView = .serieEvolucionInterior_13}
                            Button("Capitulo 12"){self.showView = .serieEvolucionInterior_12}
                            Button("Capitulo 11"){self.showView = .serieEvolucionInterior_11}
                            Button("Capitulo 10"){self.showView = .serieEvolucionInterior_10}
                            Button("Capitulo 9"){self.showView = .serieEvolucionInterior_9}
                            Button("Capitulo 8"){self.showView = .serieEvolucionInterior_8}
                            Button("Capitulo 7"){self.showView = .serieEvolucionInterior_7}
                            Button("Capitulo 6"){self.showView = .serieEvolucionInterior_6}
                            Button("Capitulo 5"){self.showView = .serieEvolucionInterior_5}
                            Button("Capitulo 4"){self.showView = .serieEvolucionInterior_4}
                            Button("Capitulo 3"){self.showView = .serieEvolucionInterior_3}
                            Button("Capitulo 2"){self.showView = .serieEvolucionInterior_2}
                            Button("Capitulo 1"){self.showView = .serieEvolucionInterior_1}
                            
                        }
                       // Button("Resumen de Charlas"){}
                        Menu("Análisis de Libros:"){
                            Menu("La Biolgía de la Creencia"){
                                Button("Resumen"){self.showView = .resumenLibroBiologiaCreencia}
                                Button("Práctica"){self.showView = .planLibroBiologiaCreencia}
                            }
                            
                        }
                        Button("Frases"){self.showView = .FrasesBruceL}
                        Button("Resumen Enseñanza"){self.showView = .resumenEnseñanzaBruceL}
                        Button("Bibliografía"){self.showView = .biografíaBruceL}
                        Label("Dr. Bruce Lipton", image: "bruce")
                    }label: {
                        Text("Bruce Lipton")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                    
                    if (self.purchaseStatus || self.yorjPremium){
                        Button{
                            self.showView = .videosTutoriales
                        }label: {
                            Text("Videos Tutoriales")
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                    }else{
                        Button{
                            self.showView = .premium
                        }label: {
                            Text("Versión Extendida")
                                .foregroundStyle(.purple)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
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
                 //Funciones Generales:
                case .setting:
                    Ajustes()
                case .notas:
                    ListNotasViews()
                case .diario:
                    DiarioListView()
                case .lienzo:
                    LienzoMain(texto: "", imagenPrimariaACargar: nil)
                case .premium:
                    PurchaseView()
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
                case .reminder:
                    ReminderListView()
                case .metas:
                    GoalsListView()
                case .enciclopedia:
                    EnciclopediaListView()
                case .evidenciaCientifica:
                    EvidenciaCientificaView()
                case .frases:
                    FrasesListView()
                    
                 //Neville Goddard:
                case .biografiaNeville:
                    ContentTxtShowView(title: "Biografía de Neville Goddard", nombreTxt: AppCons.FileBiografiaNeville, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "nev-min", size: 150)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaNeville)))
                    ])
                case .preguntasNeville:
                    TxtListView(typeOfContent: .preg, title: "Preguntas")
                case .citasNevile:
                    TxtListView(typeOfContent: .citas, title: "Citas")
                case .ayudas:
                    TxtListView(typeOfContent: .ayud, title: "Ayudas")
                case .reflex:
                    ReflexListView()
                case .conferenciasNeville:
                    TxtListView(typeOfContent: .conf, title: "Conferencias")
                case .frasesNeville:
                    FrasesListView(mostrarFrasesDe: .nev)
                case .game:
                    GamePLay()
                case .resumenEnseñanzaNeville:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Neville Goddard", nombreTxt: AppCons.FileResumenEnseñanzaNeville, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaNeville)))
                    ])
                
                    //Joe Dispenza
                case .biografiaJD:
                    ContentTxtShowView(title: "Biografía Joe Dispenza", nombreTxt: AppCons.FileBiografiaJD, type: .NA, blocks:   [
                        ContentBlock(content: .imageLocal(name: "jd", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaJD)))
                    ])
                case .frasesJD:
                    if (self.purchaseStatus || self.yorjPremium){
                        FrasesListView(mostrarFrasesDe: .jd)
                    }else{
                        
                        self.ContenidoPremium(nameAutor: "Dr. Joe Dispenza")
                    }
                       
                case .resumenEnseñanzaJD:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaJD, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaJD)))
                    ], checkPremium: true )
                    
                    
                case .resumenDejaDeSerTu:
                    ContentTxtShowView(title: "Resumen del Libro: Deja De Ser Tu", nombreTxt: AppCons.FileResumenDejaDeSerTu, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDejaDeSerTu)))
                    ], checkPremium: true  )
                case .planDejaDeSerTu:
                    ContentTxtShowView(title: "Plan del Libro: Deja De Ser Tu", nombreTxt: AppCons.FilePlanDejaDeSerTu, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDejaDeSerTu)))
                    ], checkPremium: true )
                case .resumenDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Resumen del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FileResumenDesarrollaTuCerebro, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDesarrollaTuCerebro)))
                    ], checkPremium: true )
                case .planDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Plan del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FilePlanDesarrollaTuCerebro, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDesarrollaTuCerebro)))
                    ], checkPremium: true )
                case .resumenElPlaceboEresTu:
                    ContentTxtShowView(title: "Resumen del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FileResumenElPLaceboEresTu, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenElPLaceboEresTu)))
                    ], checkPremium: true )
                case .planElPlacevoEresTu:
                    ContentTxtShowView(title: "Plan del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FilePlanElPlaceboEresTu, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanElPlaceboEresTu)))
                    ], checkPremium: true )
                case .resumenSuperNatural:
                    ContentTxtShowView(title: "Resumen del Libro: SobreNatural", nombreTxt: AppCons.FileResumenSuperNatural, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenSuperNatural)))
                    ], checkPremium: true )
                case .planSuperNatural:
                    ContentTxtShowView(title: "Plan del Libro: SobreNatural", nombreTxt: AppCons.FilePlanSupernarural, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanSupernarural)))
                    ], checkPremium: true )
                
                    
                    
                    //Gregg Braden:
                case .biografiaGregg:
                    ContentTxtShowView(title: "Biografía Gregg Braden", nombreTxt: AppCons.FileBiografiaGregg, type: .NA, blocks:   [
                        ContentBlock(content: .imageLocal(name: "gregg", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaGregg)))
                    ])
                case .FrasesGregg:
                    if (self.purchaseStatus || self.yorjPremium){
                        FrasesListView(mostrarFrasesDe: .gregg)
                    }else{
                        
                        self.ContenidoPremium(nameAutor: "Gregg Braden")
                    }

                case .resumenEnseñanzaGregg:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaGregg)))
                    ], checkPremium: true   )
                case .resumenLaMatrizDivina:
                    ContentTxtShowView(title: "Resumen del Libro: La Matriz Divina", nombreTxt: AppCons.FileResumenLaMatrizDivinaGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenLaMatrizDivinaGregg)))
                    ], checkPremium: true   )
                case .planLaMatrizDivina:
                    ContentTxtShowView(title: "Plan del Libro: La Matriz Divina", nombreTxt: AppCons.FilePlanLaMatrizDivinaGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanLaMatrizDivinaGregg)))
                    ], checkPremium: true   )
                case .resumenResilienciaDesdeCorazon:
                    ContentTxtShowView(title: "Resumen del Libro: Resilencia desde el Corazón", nombreTxt: AppCons.FileResumenResilenciaCorazonGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenResilenciaCorazonGregg)))
                    ], checkPremium: true   )
                case .planResilienciaDesdeCorazon:
                    ContentTxtShowView(title: "Plan del Libro: Resilencia desde el Corazón", nombreTxt: AppCons.FilePlanResilenciaCorazonGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanResilenciaCorazonGregg)))
                    ], checkPremium: true   )
                case .resumenPuramenteHumanos:
                    ContentTxtShowView(title: "Resumen del Libro: Puramente Humanos", nombreTxt: AppCons.FileResumenPuramenteHumanosGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenPuramenteHumanosGregg)))
                    ], checkPremium: true   )
                case .planPuramenteHumanos:
                    ContentTxtShowView(title: "Plan del Libro: Puramente Humanos", nombreTxt: AppCons.FilePlanPuramenteHumanosGregg, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanPuramenteHumanosGregg)))
                    ], checkPremium: true   )
                    
                    
                    //Bruce Lipton:
                case .biografíaBruceL:
                    ContentTxtShowView(title: "Biografía Dr. Bruce H. Lipton", nombreTxt: AppCons.FileBiografiaBruce, type: .NA, blocks:   [
                        ContentBlock(content: .imageLocal(name: "bruce", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaBruce)))
                    ])
                case .FrasesBruceL:
                    if (self.purchaseStatus || self.yorjPremium){
                        FrasesListView(mostrarFrasesDe: .bruceL)
                    }else{
                        
                        self.ContenidoPremium(nameAutor: "Dr. Bruce Lipton")
                    }

                case .resumenEnseñanzaBruceL:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaBruce, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaBruce)))
                    ], checkPremium: true   )
                case .resumenLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Resumen del Libro: La Biología De La Creencia", nombreTxt: AppCons.FileResumenBiologiaCreencia, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenBiologiaCreencia)))
                    ], checkPremium: true   )
                case .planLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Plan del Libro: La Biología De La Creencia", nombreTxt: AppCons.FilePlanBiologiaCrrencia, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanBiologiaCrrencia)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_1:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 1", nombreTxt: AppCons.FileSerieEvolucionInterior_1, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_1)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_2:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 2", nombreTxt: AppCons.FileSerieEvolucionInterior_2, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_2)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_3:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 3", nombreTxt: AppCons.FileSerieEvolucionInterior_3, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_3)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_4:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 4", nombreTxt: AppCons.FileSerieEvolucionInterior_4, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_4)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_5:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 5", nombreTxt: AppCons.FileSerieEvolucionInterior_5, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_5)))
                    ] , checkPremium: true  )
                case .serieEvolucionInterior_6:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 6", nombreTxt: AppCons.FileSerieEvolucionInterior_6, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_6)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_7:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 7", nombreTxt: AppCons.FileSerieEvolucionInterior_7, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_7)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_8:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 8", nombreTxt: AppCons.FileSerieEvolucionInterior_8, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_8)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_9:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 9", nombreTxt: AppCons.FileSerieEvolucionInterior_9, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_9)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_10:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 10", nombreTxt: AppCons.FileSerieEvolucionInterior_10, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_10)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_11:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 11", nombreTxt: AppCons.FileSerieEvolucionInterior_11, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_11)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_12:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 12", nombreTxt: AppCons.FileSerieEvolucionInterior_12, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_12)))
                    ], checkPremium: true   )
                case .serieEvolucionInterior_13:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 13", nombreTxt: AppCons.FileSerieEvolucionInterior_13, type: .NA, blocks:   [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_13)))
                    ]  )
                    
                    //Videos Tutoriales de la App
                case .videosTutoriales:
                    VStack{
                        Text("Lista de Videos Tutoriales de la las funciones extendidas")
                        //Barra de gadgets de Metas:
                    }
                    
                }
                
                
                
                
                
                
                
                
              
                    
                
            }
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
            
        })
        
        
        
    }
    


    @ViewBuilder
    func ContenidoPremium(nameAutor : String) -> some View{
        NavigationStack{
            ZStack{
                LinearGradient.AtardecerVioleta()
                    .ignoresSafeArea()
                
                VStack{
                    Image("Logo")
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: 100, height: 100)
                        .padding()
                        
                        
                    Spacer()
                    Text("Las Frases y enseñanzas de \(nameAutor) están disponibles en la Versión Extendida")
                        .font(.title2)
                        .bold()
                    
                    NavigationLink("Acceder a la Versión Extendida"){
                        PurchaseView()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                    Spacer()
                }
                .padding(3)
                
            }
        }
    }
    
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





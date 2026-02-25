import SwiftUI

//Todos los posibles item que pueden aparecer en el sidebar:
enum ItemNameSidebar: String{
    case home
    //NevilleGodard:
    case bibliografiaNeville
    case resumenEnseñanzaNeville
    case conferenciasNeville
    case frasesNeville
    case citasNeville
    case preguntasNeville
    case evaluacionNeville
    
    //Joe Dispenza:
    case bibliografiaJoe
    case resumenEnseñanzaJoe
    case frasesJoe
    
    case analisisLibroSobrenatural
    case practicaLibroSobrenatural
    
    case analisisLibroElPlaceboEresTu
    case practicaLibroElPlaceboEresTu
    
    case analisisLibroDejaDeSerTu
    case practicaLibroDejaDeSerTu
    
    case analisisLibroDesarrollaTuCerebro
    case practicaLibroDesarrollaTuCerebro
    
    //Gregg Braden:
    case bibliografiaGregg
    case resumenEnseñanzaGregg
    case frasesGregg
    case analisisLibroPuramenteHumanos
    case practicaLibroPuramenteHumanos
    
    case analisisLibroResilienciaDesdeCorazon
    case practicaLibroResilienciaDesdeCorazon
    
    case analisisLibroLaMatrizDivina
    case practicaLibroLaMatrizDivina
    
    //Bruce Lipton:
    case bibliografiaBruce
    case resumenEnseñanzaBruce
    case frasesBruce
    case analisisLibroBiologiaCreencia
    case practicaLibroBiologiaCreencia
    case serieEvolucionInterior_1, serieEvolucionInterior_2, serieEvolucionInterior_3, serieEvolucionInterior_4, serieEvolucionInterior_5
    case serieEvolucionInterior_6, serieEvolucionInterior_7, serieEvolucionInterior_8, serieEvolucionInterior_9, serieEvolucionInterior_10
    case serieEvolucionInterior_11, serieEvolucionInterior_12, serieEvolucionInterior_13
    
    
    //Recursos Didácticos:
    case frasesGenerales
    case ayudas
    case reflexiones
    case notas
    case diario
    case enciclopedia
    case evidenciaCientifica
    
    //Productividad:
    case canalTelegram
    case crearQR
    case metas
    case recordatorios
    case chatIA
    case lienzo
    
    //Ajustes:
    case ajustes
    
    //Premium
    case premium
}

struct ItemSidebar: Identifiable, Hashable, Equatable {
    var id = UUID()
    var text: ItemNameSidebar
    let icono: String
    
    static func == (lhs: ItemSidebar, rhs: ItemSidebar) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
}







struct ContentViewMac: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var modelSetting : SettingModel
    @EnvironmentObject var modelFrases : FrasesModel
    @EnvironmentObject var modelTxt : TxtContentModel
    @EnvironmentObject var securityModel : SecurityModel //Provee de reactividad al acceso a áreas protegidas: Diario, y notas Protegidas
   // @StateObject private var purchasePremium : PurchaseManager = .shared
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    
    @Environment(\.colorScheme) var theme
    

    //Para Actualizar valores de Setting en tiempo real
    @State var ColorPrimario    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .orange
    @State var ColorSecundario  : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)

   
    //Lanzar Ventana de Novedades una sola vez:
    @State private var  showNovedades : Bool = false

    @State private var categoriaSelected: ItemNameSidebar = .home
    
    
    //Determina si el contenido de las ventanas modales se muestren en Details
    @AppStorage(AppCons.UD_setting_showEnDetails_diario)        var showEnDetails_diario            : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_evaluacion)    var showEnDetails_evaluacion        : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_ajustes)       var showEnDetails_ajustes           : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_chat_ia)       var showEnDetails_chat_ia           : Bool  = false
    
    //Acceso a la opción de en Ajustes
    @AppStorage("setting_DiarioAccesoAjustes") var setting_DiarioAccesoAjustes  : Bool = false
    
  
    
    var body: some View {
            ZStack{
                
                LinearGradient(colors: [self.modelSetting.colorFondo_a, self.modelSetting.colorFondo_b], startPoint: .top, endPoint: .bottom)
                
                NavigationSplitView{
                    
                    ContentSidebar()
                    
                } detail: {
                        NavigationDetailsViewMac(sidebarItemSelected: self.$categoriaSelected )
       
                }
                .navigationViewStyle(.automatic)
      
            }
            .frame(minWidth: 1200, minHeight: 870, idealHeight: 870)
            .onAppear {
                //Lanzar la lista de novedades al inicio
                switch RunFirstTimeModel.CheckStatusAppRun(){
                case .firstLaunchApp:
                    //Actualiza las variables iniciales del Lienzo:
                    UserDefaults.standard.set(true,forKey: LienzoModel.key_visibilidadTextoSecundario) //Visibilidad de Imagen
                    UserDefaults.standard.set(true, forKey: LienzoModel.key_visibilidadImagenLienzo)
                    LienzoModel.shared.saveColorTextoSecundario(colorTexttoSecundario: .black) //Color del Texto Secundario
                    
                    //Muestra la ventana de Resultados
                    showWindow(for: Novedades(),
                               environmentObjects: [],
                               title: "Novedades",
                               size: AppCons.windows_size_content_small,
                               isModal: false
                               
                    )
                    
                    //Popula la Tabla Frases Si es la primera Vez que se instala la App:
                    let frasesModel = FrasesModel.shared
                    Task{
                        await frasesModel.ImportadorDeFrases()
                    }
                    
                    
                    
                case .updateApp:
                    //Muestra la ventana de novedades
                    showWindow(for: Novedades(),
                               environmentObjects: [],
                               title: "Novedades",
                               size: AppCons.windows_size_content_small,
                               isModal: false
                               
                    )
                    
                    //Popula la Tabla Frases Si es la primera Vez que se instala la App:
                    let frasesModel = FrasesModel.shared
                    Task{
                        await frasesModel.ImportadorDeFrases()
                    }
                    
                    
                default:
                    print("La App, ni se ha instalado ni reinstalado. se ha iniciado en modo debug desde Xcode")
                    
                    #if DEBUG
                    //Popula la Tabla Frases Si es la primera Vez que se instala la App:
                    let frasesModel = FrasesModel.shared
                    Task{
                        await frasesModel.ImportadorDeFrases()
                    }
                    #endif
                }

            }
        
        
    }
    
    //Construyendo los items del Sidebar
    @ViewBuilder
    func ContentSidebar() -> some View {
        Group {
            Button("TEST"){
                KeychainHelper.shared.deletePassword()
            }
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.orange.opacity(0.6), lineWidth: 0.5)
                )
                .shadow(radius: 2)
                .padding(.top, 5)
            Text("La Ley").font(.title2).bold().foregroundStyle(.primary)
                .padding(.bottom, 10)
            Text("Imaginar Crea la Realidad")
                .font(.title2)
                .foregroundStyle(self.theme == .light ? .black : .orange)
                .fontDesign(.serif)
                .fontWeight(.heavy)
                //.shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .padding(.vertical, 10)
                .multilineTextAlignment(.center)
                .frame(minWidth: 250)
            
            

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 15) {
                    
                    SidebarCard(iconName: "house", title: "home", onTap: {
                        self.categoriaSelected = .home
                    }){}
                    
                    //Neville Goddard
                    SidebarCard(iconName: "person.circle", title: "Neville Goddard", isExpandable: true){
                        
                        SidebarCard(iconName: "quote.opening", title: "Bibliografía", onTap: {
                            self.categoriaSelected = .bibliografiaNeville
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Resumen de Enseñanza", onTap: {
                            self.categoriaSelected = .resumenEnseñanzaNeville
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Frases", onTap: {
                            self.categoriaSelected = .frasesNeville
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Conferencias", onTap: {
                            self.categoriaSelected = .conferenciasNeville
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Citas", onTap: {
                            self.categoriaSelected = .citasNeville
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Preguntas", onTap: {
                            self.categoriaSelected = .preguntasNeville
                        }){}
                        
                        SidebarCard(iconName: "text.book.closed", title: "Evaluación", onTap: {
                            self.categoriaSelected = .evaluacionNeville
                        }){}
                        
                        
                    }
                    
                    //Joe Dispenza:
                    SidebarCard(iconName: "person.circle", title: "Joe Dispenza", isExpandable: true){
                       
                        SidebarCard(iconName: "quote.opening", title: "Bibliografía", onTap: {
                            self.categoriaSelected = .bibliografiaJoe
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Resumen de Enseñanza", onTap: {
                            self.categoriaSelected = .resumenEnseñanzaJoe
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Frases", onTap: {
                            self.categoriaSelected = .frasesJoe
                        }){}
                        //Libro SobreNatural:
                        SidebarCard(iconName: "quote.opening", title: "Libro: SobreNatural", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroSobrenatural
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroSobrenatural
                            }){}
                        }
                        //Libro Deja de Ser Tu:
                        SidebarCard(iconName: "quote.opening", title: "Libro: Deja de Ser Tú", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroDejaDeSerTu
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroDejaDeSerTu
                            }){}
                        }
                        //Libro El placebo eres Tu:
                        SidebarCard(iconName: "quote.opening", title: "Libro: El PLacebo eres Tú", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroElPlaceboEresTu
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroElPlaceboEresTu
                            }){}
                        }
                        //Libro Desarrolla tu cerebro:
                        SidebarCard(iconName: "quote.opening", title: "Libro: Desarrolla tu Cerebro", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroDesarrollaTuCerebro
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroDesarrollaTuCerebro
                            }){}
                        }
                        
                        
                    }
                     
                    //Gregg:
                    SidebarCard(iconName: "person.circle", title: "Gregg Braden", isExpandable: true){
                        
                        SidebarCard(iconName: "quote.opening", title: "Bibliografía", onTap: {
                            self.categoriaSelected = .bibliografiaGregg
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Resumen de Enseñanza", onTap: {
                            self.categoriaSelected = .resumenEnseñanzaGregg
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Frases", onTap: {
                            self.categoriaSelected = .frasesGregg
                        }){}
                        
                        //Libro Puramente Humanos:
                        SidebarCard(iconName: "quote.opening", title: "Libro: Puramente Humanos", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroPuramenteHumanos
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroPuramenteHumanos
                            }){}
                        }
                        //Libro Resiliencia desde el Corazón:
                        SidebarCard(iconName: "quote.opening", title: "Libro: Resiliencia desde el Corazón", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroResilienciaDesdeCorazon
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroResilienciaDesdeCorazon
                            }){}
                        }
                        //Libro La Matriz Divina:
                        SidebarCard(iconName: "quote.opening", title: "Libro: La Matriz Divina", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroLaMatrizDivina
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroLaMatrizDivina
                            }){}
                        }
                        
                    }
                    
                    
                    //Bruce Lipton:
                    SidebarCard(iconName: "person.circle", title: "Dr. Bruce H. Lipton", isExpandable: true){
                        SidebarCard(iconName: "quote.opening", title: "Bibliografía", onTap: {
                            self.categoriaSelected = .bibliografiaBruce
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Resumen de Enseñanza", onTap: {
                            self.categoriaSelected = .resumenEnseñanzaBruce
                        }){}
                        
                        SidebarCard(iconName: "quote.opening", title: "Frases", onTap: {
                            self.categoriaSelected = .frasesBruce
                        }){}
                        
                        //Libro La Biología de la Creencia:
                        SidebarCard(iconName: "quote.opening", title: "Libro: La biología de la Creencia", isExpandable: true){
                            SidebarCard(iconName: "quote.opening", title: "Resumen", onTap: {
                                self.categoriaSelected = .analisisLibroBiologiaCreencia
                            }){}
                            
                            SidebarCard(iconName: "quote.opening", title: "Práctica", onTap: {
                                self.categoriaSelected = .practicaLibroBiologiaCreencia
                            }){}
                        }
                        SidebarCard(iconName: "quote.opening", title: "Resumen Serie: Evolución Interior", isExpandable: true){
                            
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 1", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_1
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 2", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_2
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 3", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_3
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 4", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_4
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 5", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_5
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 6", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_6
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 7", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_7
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 8", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_8
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 9", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_9
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 10", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_10
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 11", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_11
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 12", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_12
                            }){}
                            SidebarCard(iconName: "quote.opening", title: "Capítulo 13", onTap: {
                                self.categoriaSelected = .serieEvolucionInterior_13
                            }){}
                            
                        }
                        
                    }
                    
                    //Recursos Didácticos:
                    SidebarCard(iconName: "person.circle", title: "Recursos Didácticos", isExpandable: true){
                        SidebarCard(iconName: "quote.opening", title: "Frases", onTap: {
                            self.categoriaSelected = .frasesGenerales
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Notas", onTap: {
                            self.categoriaSelected = .notas
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Enciclopedia", onTap: {
                            self.categoriaSelected = .enciclopedia
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Evidencia Científica", onTap: {
                            self.categoriaSelected = .evidenciaCientifica
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Reflexiones", onTap: {
                            self.categoriaSelected = .reflexiones
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Ayudas", onTap: {
                            self.categoriaSelected = .ayudas
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Diario", onTap: {
                            self.categoriaSelected = .diario
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "ChatIA", onTap: {
                            self.categoriaSelected = .chatIA
                        }){}
                    }
                    
                  //Productividad:
                    SidebarCard(iconName: "person.circle", title: "Productividad", isExpandable: true){
                        SidebarCard(iconName: "quote.opening", title: "Generador de QR", onTap: {
                            self.categoriaSelected = .crearQR
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Metas", onTap: {
                            self.categoriaSelected = .metas
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Recordartorios", onTap: {
                            self.categoriaSelected = .recordatorios
                        }){}
                        SidebarCard(iconName: "quote.opening", title: "Lienzo", onTap: {
                            self.categoriaSelected = .lienzo
                        }){}
                    }
                    
                    //Ajustes:
                    SidebarCard(iconName: "gear", title: "Ajustes", onTap: {
                        self.categoriaSelected = .ajustes
                    }){}
                    
                    //Premium:
                    SidebarCard(iconName: "quote.opening", title: "Versión Extendida", onTap: {
                        self.categoriaSelected = .premium
                    }){}
                    
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            
            
            Spacer()
            
        }
    }
    
    

    
}


//Contenido de Details.
//Mira el contenido de un arreglo de de tipos sidebarItemSelected.
struct NavigationDetailsViewMac: View {
    
    @Binding var sidebarItemSelected : ItemNameSidebar
    
    var body: some View {
        VStack{
            switch self.sidebarItemSelected{
            case .home:
                FrasesHomeMac()
            //Neville Goddard:
            case .bibliografiaNeville:
                ContentTxtShowView(title: "Biografía", nombreTxt: AppCons.FileBiografiaNeville, type: .NA, blocks:   [
                    ContentBlock(content: .imageLocal(name: "nev-min", size: 100)),
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaNeville)))
                ]  )
            case .resumenEnseñanzaNeville:
                ContentTxtShowView(title: "Resumen de la enseñanza: Neville Goddard", nombreTxt: AppCons.FileResumenEnseñanzaNeville, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaNeville)))
                ]  )
            case .frasesNeville:
                FrasesListView(mostrarFrasesDe: .nev)
            case .conferenciasNeville:
                TxtListView(typeOfContent: .conf, title: "Conferencias")
            case .citasNeville:
                TxtListView(typeOfContent: .citas, title: "Citas")
            case .preguntasNeville:
                TxtListView(typeOfContent: .preg, title: "Preguntas")
            case .evaluacionNeville:
                GamePLay()
            
            //Joe Dispenza:
            case .bibliografiaJoe:
                ContentTxtShowView(title: "Biografía", nombreTxt: AppCons.FileBiografiaJD, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaJD)))
                ]  )
            case .resumenEnseñanzaJoe:
                ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaJD, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaJD)))
                ]  )
            case .frasesJoe:
                FrasesListView(mostrarFrasesDe: .jd)
            case .analisisLibroSobrenatural:
                ContentTxtShowView(title: "Análisis del Libro: SobreNatural", nombreTxt: AppCons.FileResumenSuperNatural, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenSuperNatural)))
                ]  )
            case .practicaLibroSobrenatural:
                ContentTxtShowView(title: "Práctica del Libro: SobreNatural", nombreTxt: AppCons.FilePlanSupernarural, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanSupernarural)))
                ]  )
            case .analisisLibroDejaDeSerTu:
                ContentTxtShowView(title: "Análisis del Libro: Deja de ser tú", nombreTxt: AppCons.FileResumenDejaDeSerTu, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDejaDeSerTu)))
                ]  )
            case .practicaLibroDejaDeSerTu:
                ContentTxtShowView(title: "Práctica del Libro: Deja de ser tú", nombreTxt: AppCons.FilePlanDejaDeSerTu, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDejaDeSerTu)))
                ]  )
            case .analisisLibroElPlaceboEresTu:
                ContentTxtShowView(title: "Análisis del Libro: El placebo eres tú", nombreTxt: AppCons.FileResumenElPLaceboEresTu, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenElPLaceboEresTu)))
                ]  )
            case .practicaLibroElPlaceboEresTu:
                ContentTxtShowView(title: "Práctica del Libro: El placebo eres tú", nombreTxt: AppCons.FilePlanElPlaceboEresTu, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanElPlaceboEresTu)))
                ]  )
            case .analisisLibroDesarrollaTuCerebro:
                ContentTxtShowView(title: "Análisis del Libro: Desarrolla tu cerebro", nombreTxt: AppCons.FileResumenDesarrollaTuCerebro, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDesarrollaTuCerebro)))
                ]  )
            case .practicaLibroDesarrollaTuCerebro:
                ContentTxtShowView(title: "Práctica del Libro: Desarrolla tu cerebro", nombreTxt: AppCons.FilePlanDesarrollaTuCerebro, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDesarrollaTuCerebro)))
                ]  )
            
            //Greeg Braden:
            case .bibliografiaGregg:
                ContentTxtShowView(title: "Biografía", nombreTxt: AppCons.FileBiografiaGregg, type: .NA )
            case .resumenEnseñanzaGregg:
                ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaGregg)))
                ]  )
            case .frasesGregg:
                FrasesListView(mostrarFrasesDe: .gregg)
            case .analisisLibroPuramenteHumanos:
                ContentTxtShowView(title: "Análisis del Libro: Puramente Humanos", nombreTxt: AppCons.FileResumenPuramenteHumanosGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenPuramenteHumanosGregg)))
                ]  )
            case .practicaLibroPuramenteHumanos:
                ContentTxtShowView(title: "Práctica del Libro: Puramente Humanos", nombreTxt: AppCons.FilePlanPuramenteHumanosGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanPuramenteHumanosGregg)))
                ]  )
            case .analisisLibroResilienciaDesdeCorazon:
                ContentTxtShowView(title: "Análisis del Libro: Resiliencia desde el Corazón", nombreTxt: AppCons.FileResumenResilenciaCorazonGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenResilenciaCorazonGregg)))
                ]  )
            case .practicaLibroResilienciaDesdeCorazon:
                ContentTxtShowView(title: "Práctica del Libro: Resiliencia desde el Corazón", nombreTxt: AppCons.FilePlanResilenciaCorazonGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanResilenciaCorazonGregg)))
                ]  )
            case .analisisLibroLaMatrizDivina:
                ContentTxtShowView(title: "Análisis del Libro: La Matriz Divina", nombreTxt: AppCons.FileResumenLaMatrizDivinaGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanLaMatrizDivinaGregg)))
                ]  )
            case .practicaLibroLaMatrizDivina:
                ContentTxtShowView(title: "Práctica del Libro: La Matriz Divina", nombreTxt: AppCons.FilePlanLaMatrizDivinaGregg, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanLaMatrizDivinaGregg)))
                ]  )
                
              
            //Bruce Lipton:
            case .bibliografiaBruce:
                ContentTxtShowView(title: "Biografía", nombreTxt: AppCons.FileBiografiaBruce, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaBruce)))
                ]  )
            case .resumenEnseñanzaBruce:
                ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaBruce, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaBruce)))
                ]  )
            case .frasesBruce:
                FrasesListView(mostrarFrasesDe: .bruceL)
            case .analisisLibroBiologiaCreencia:
                ContentTxtShowView(title: "Análisis del Libro: La Biología de la Creencia", nombreTxt: AppCons.FileResumenBiologiaCreencia, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenBiologiaCreencia)))
                ]  )
            case .practicaLibroBiologiaCreencia:
                ContentTxtShowView(title: "Práctica del Libro: La Biología de la Creencia", nombreTxt: AppCons.FilePlanBiologiaCrrencia, type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanBiologiaCrrencia)))
                ]  )
            case .serieEvolucionInterior_1:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 1", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_1)))
                ]  )
            case .serieEvolucionInterior_2:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 2", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_2)))
                ]  )
            case .serieEvolucionInterior_3:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 3", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_3)))
                ]  )
            case .serieEvolucionInterior_4:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 4", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_4)))
                ]  )
                
            case .serieEvolucionInterior_5:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 5", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_5)))
                ]  )
            case .serieEvolucionInterior_6:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 6", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_6)))
                ]  )
            case .serieEvolucionInterior_7:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 7", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_7)))
                ]  )
            case .serieEvolucionInterior_8:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 8", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_8)))
                ]  )
                
            case .serieEvolucionInterior_9:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 9", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_9)))
                ]  )
            case .serieEvolucionInterior_10:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 10", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_10)))
                ]  )
            case .serieEvolucionInterior_11:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 11", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_11)))
                ]  )
            case .serieEvolucionInterior_12:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 12", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_12)))
                ]  )
            case .serieEvolucionInterior_13:
                ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 13", nombreTxt: "", type: .NA, blocks:   [
                    ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_13)))
                ]  )
                
                
            //Recursos Didácticos:
            case .frasesGenerales:
               FrasesListView()
            case .notas:
                VStack{
                        ListNotasViews()
                }
                .background(.blue.opacity(0.4))
            case .enciclopedia:
                    EnciclopediaListView()
                    
            case .evidenciaCientifica:
                EvidenciaCientificaView()
            case .reflexiones:
                ReflexListView()
            case .ayudas:
                TxtListView(typeOfContent: .ayud, title: "Ayudas")
            case .diario: //si se ha fijado abrir el diario en la ventana Details (en Ajustes)
                    DiarioListView()
            case .chatIA:
                if #available(iOS 26.0, macOS 26.0, *){
                    ChatView(textoACargar: nil)
                }
                
            //Productividad:
            case .crearQR:
                GenerateQRView(footer: "")
            case .metas:
                GoalsListView()
            case .recordatorios:
                ReminderListView()
            case .lienzo:
                LienzoMain(texto: "", imagenPrimariaACargar: nil)

                //Ajustes:
            case .ajustes:
                VStack{
                    Ajustes()
                }
                .background(.black.opacity(0.8))
            
           //Premium
            case .premium:
                PurchaseView()
                
            default:
                VStack{
                    Text("No implementado")
                }
            }
        }
       
    }
}


//Pantalla de frases del home
struct FrasesHomeMac: View{
    
    var body: some View {
        VStack{
            Spacer()
            FrasesHomeView()
            Spacer()
            //Barra de Recordatorios:
            ReminderWidgetList_View()
        }
    }
}



struct SidebarCard<Content: View>: View {
    
    let iconName: String
    let title: String
    
    var isExpandable: Bool = false
    
    var onTap: (() -> Void)? = nil
    
    @ViewBuilder var content: () -> Content
    
    @State private var isExpanded: Bool = false
    
    var body: some View {
        
        Button{
            if !isExpandable {
                onTap?()
            }else{
                withAnimation{
                    isExpanded.toggle()
                }
                
            }
        }label: {
            VStack(spacing: 0) {
                
                HStack(spacing: 8) {
                    
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(.black)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    if isExpandable {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .padding(6)
                .background(backgroundGradient)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 4)
                .contentShape(Rectangle())
                
                // Sub-items
                if isExpandable && isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                            content()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 4)
                    
                }
            }
        }
        .buttonStyle(.plain)
        
       
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.55, green: 0.75, blue: 0.89),
                Color(red: 0.40, green: 0.65, blue: 0.87)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    
    
   
}


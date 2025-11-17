import SwiftUI


enum ItemNameSidebar: String{
    case home
    case conferencias
    case frases
    case citas
    case ayudas
    case reflexiones
    case preguntas
    case notas
    case diario
    case bibliografia
    case evaluacion
    case canalTelegram
    case crearQR
    case ajustes
    case chatIA
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
    
    
    
    @Environment(\.colorScheme) var theme
    

    //Para Actualizar valores de Setting en tiempo real
    @State var ColorPrimario    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .orange
    @State var ColorSecundario  : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)

   
    

    
    //Listados de items en el Sidebar
    @State private var  categoriasSideBar : [ItemSidebar] = [
        ItemSidebar(text: .home , icono: "gear"),
        ItemSidebar(text: .conferencias, icono: "gear"),
        ItemSidebar(text: .frases, icono: "gear"),
        ItemSidebar(text: .citas, icono: "gear"),
        ItemSidebar(text: .ayudas, icono: "gear"),
        ItemSidebar(text: .reflexiones, icono: "gear"),
        ItemSidebar(text: .preguntas, icono: "gear"),
        ItemSidebar(text: .notas, icono: "gear"),
        ItemSidebar(text: .bibliografia, icono: "gear")
        //Nota:
        //Los items de Diario, Evaluación y Ajustes se agregan a este array dinámicamente cuando se quiera mostrar en la ventana de Details
        
        
    ]    //["Home", "Conferencias", "Notas"]
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @State private var categoriaSelected: ItemSidebar?
    
    
    //Determina si el contenido de las ventanas modales se muestren en Details
    @AppStorage(AppCons.UD_setting_showEnDetails_diario)        var showEnDetails_diario            : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_evaluacion)    var showEnDetails_evaluacion        : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_ajustes)       var showEnDetails_ajustes           : Bool  = false
    @AppStorage(AppCons.UD_setting_showEnDetails_chat_ia)       var showEnDetails_chat_ia           : Bool  = false
    
    
    var body: some View {
        ZStack{
            
            LinearGradient(colors: [self.modelSetting.colorFondo_a, self.modelSetting.colorFondo_b], startPoint: .top, endPoint: .bottom)
            
            NavigationSplitView{
                
                ContentSidebar()
                
            } detail: {
                
                NavigationDetailsViewMac(sidebarItemSelected: self.$categoriaSelected)
                
            }
            .navigationViewStyle(.automatic)
            
            
        }
    }
    
    //Construyendo los items del Sidebar
    @ViewBuilder
    func ContentSidebar() -> some View {
        Group {
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
                .shadow(color: .gray.opacity(0.5), radius: 2, x: 0, y: 1)
                .padding(.vertical, 10)
                .multilineTextAlignment(.center)
                
                
            // Items del Sidebar
            List(selection: self.$categoriaSelected) {
                ForEach (categoriasSideBar, id: \.id) { itemSidebar in
                    Label(itemSidebar.text.rawValue, systemImage: itemSidebar.icono)
                        .tag(itemSidebar)
                }
                
                //Abre ventana del Diario
                Button{
                    
                    self.securityModel.canOpenDiario = false //Bloquear el Diario siempre antes de abrirse
                    
                    //Consulta la clave en UserDefault
                    if self.showEnDetails_diario{
                        self.categoriaSelected = ItemSidebar(text: .diario, icono: "")
                    }else{
                        //Primero vuelve a cargar home si tenemos cargado en Details una ventana de home, diario o ajustes
                        if (self.categoriaSelected?.text == .diario){
                            self.categoriaSelected = ItemSidebar(text: .home, icono: "")
                        }
                        
                        showWindow(for: DiarioListView(),
                                   environmentObjects: [self.context, self.securityModel],
                                   title: "Diario",
                                   size: .absolute(CGSize(width: 600, height: 450)),
                                   isModal: false
                        )
                    }
                }label:{
                    Label("Diario", systemImage: "gear")
                        .tag(ItemSidebar(text: .diario, icono: ""))
                }
                .buttonStyle(.plain)
                
                
                //Abre ventana de Evaluación:
                Button{
                    
                    if self.showEnDetails_evaluacion {
                        self.categoriaSelected = ItemSidebar(text: .evaluacion, icono: "")
                    }else{
                        //Primero vuelve a cargar home si tenemos cargado en Details una ventana de home, diario o ajustes
                        if (self.categoriaSelected?.text == .evaluacion){
                            self.categoriaSelected = ItemSidebar(text: .home, icono: "")
                        }
                        showWindow(for: GamePLay(),
                                   environmentObjects: [],
                                   title: "Diario",
                                   size: .absolute(CGSize(width: 600, height: 450)),
                                   isModal: false
                        )
                    }
                    
                    
                }label:{
                    Label("Evaluación", systemImage: "gear")
                        .tag(ItemSidebar(text: .evaluacion, icono: ""))
                }
                .buttonStyle(.plain)
                
                
                //Abre la ventana de chatIA
                Button{
                    
                    if self.showEnDetails_chat_ia {
                        self.categoriaSelected = ItemSidebar(text: .chatIA, icono: "")
                    }else{
                        //Primero vuelve a cargar home si tenemos cargado en Details una ventana de home, diario o ajustes
                        if (self.categoriaSelected?.text == .chatIA){
                            self.categoriaSelected = ItemSidebar(text: .chatIA, icono: "")
                        }
                        if #available(iOS 26.0, macOS 26.0, *){
                            showWindow(for: ChatView(textoACargar: nil),
                                       environmentObjects: [],
                                       title: "Ajustes",
                                       size: .absolute(CGSize(width: 600, height: 450)),
                                       isModal: false
                            )
                        }
                    }
                }label:{
                    Label("Chat IA", systemImage: "gear")
                        .tag(ItemSidebar(text: .chatIA, icono: ""))
                }
                .buttonStyle(.plain)
                
                
                //Abre ventana de Ajustes
                Button{
                    
                    if self.showEnDetails_ajustes {
                        self.categoriaSelected = ItemSidebar(text: .ajustes, icono: "")
                    }else{
                        //Primero vuelve a cargar home si tenemos cargado en Details una ventana de home, diario o ajustes
                        if (self.categoriaSelected?.text == .ajustes){
                            self.categoriaSelected = ItemSidebar(text: .home, icono: "")
                        }
                        showWindow(for: Ajustes(),
                                   environmentObjects: [self.context ,self.modelSetting, self.modelFrases, self.modelTxt, self.securityModel],
                                   title: "Ajustes",
                                   size: .absolute(CGSize(width: 600, height: 450)),
                                   isModal: false
                        )
                    }
                }label:{
                    Label("Ajustes", systemImage: "gear")
                        .tag(ItemSidebar(text: .ajustes, icono: ""))
                }
                .buttonStyle(.plain)
                
                
            }
            .listStyle(.sidebar)
            .onAppear {
                //Seleccionando el primer Item en el sidebar
                if categoriaSelected == nil {
                    categoriaSelected = categoriasSideBar.first
                }
            }
            
            Spacer()
            
        }
    }
    
}


//Contenido de Details.
//Mira el contenido de un arreglo de de tipos sidebarItemSelected.
struct NavigationDetailsViewMac: View {
    
    @Binding var sidebarItemSelected : ItemSidebar?
    
    var body: some View {
        VStack{
            switch self.sidebarItemSelected?.text{
            case .home:
                FrasesHomeMac(sidebarItemSelected: self.$sidebarItemSelected)
            case .conferencias:
                TxtListView(typeOfContent: .conf, title: "Conferencias")
            case .frases:
                FrasesListView()
            case .citas:
                TxtListView(typeOfContent: .citas, title: "Citas")
            case .ayudas:
                TxtListView(typeOfContent: .ayud, title: "Ayudas")
            case .reflexiones:
                ReflexListView()
            case .preguntas:
                TxtListView(typeOfContent: .preg, title: "Preguntas")
            case .notas:
                VStack{
                        ListNotasViews()
                }
                .background(.blue.opacity(0.4))
                
            case .bibliografia:
                ContentTxtShowView(title: "Biografía", nombreTxt: "biografia", type: .NA )
            case .diario: //si se ha fijado abrir el diario en la ventana Details (en Ajustes)
                    DiarioListView()
            case .evaluacion:
                GamePLay()
            case .ajustes:
                VStack{
                    Ajustes()
                }
                .background(.black.opacity(0.8))
            case .chatIA:
                if #available(iOS 26.0, macOS 26.0, *){
                    ChatView(textoACargar: nil)
                }
                
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
    @Binding var sidebarItemSelected : ItemSidebar? //De momento no utilizado
    
    var body: some View {
        VStack{
            FrasesView()
        }
    }
}





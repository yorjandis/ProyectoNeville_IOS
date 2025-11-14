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
    @EnvironmentObject var securityModel : SecurityModel
    
    @Environment(\.colorScheme) var theme
    

  
    @State var ColorPrimario    : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_a) ?? .orange
    @State var ColorSecundario  : Color = SettingModel.loadColor(forkey: AppCons.UD_setting_color_main_b) ?? .blue.opacity(0.5)
    
    

    
    //Listados de items en la Sidebar
    @State private var  categoriasSideBar : [ItemSidebar] = [
        ItemSidebar(text: .home , icono: "gear"),
        ItemSidebar(text: .conferencias, icono: "gear"),
        ItemSidebar(text: .frases, icono: "gear"),
        ItemSidebar(text: .citas, icono: "gear"),
        ItemSidebar(text: .ayudas, icono: "gear"),
        ItemSidebar(text: .reflexiones, icono: "gear"),
        ItemSidebar(text: .preguntas, icono: "gear"),
        ItemSidebar(text: .notas, icono: "gear")
        
        
    ]    //["Home", "Conferencias", "Notas"]
    
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @State private var categoriaSelected: ItemSidebar?
    
    
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
                ForEach (categoriasSideBar, id: \.id) { categoria in
                    Label(categoria.text.rawValue, systemImage: categoria.icono)
                        .tag(categoria)
                }
                
                
                //Abre la bibliografia
                Button{

                    showWindow(for: ContentTxtShowView(title: "Biografía", nombreTxt: "biografia", type: .NA ),
                               environmentObjects: [],
                               title: "Bibliografía",
                               size: CGSize(width: 550, height: 400),
                               isModal: false
                    )
                }label:{
                    Label("Bibliografía", systemImage: "gear")
                        .tag(ItemSidebar(text: .bibliografia, icono: ""))
                }
                .buttonStyle(.plain)
                
                //Abre ventana del Diario
                Button{
                    //Bloquear el Diario siempre antes de abrirse:
                    self.securityModel.canOpenDiario = false
                    
                    showWindow(for: DiarioListView(),
                               environmentObjects: [self.context, self.securityModel],
                               title: "Diario",
                               size: CGSize(width: 550, height: 400),
                               isModal: false
                    )
                }label:{
                    Label("Diario", systemImage: "gear")
                        .tag(ItemSidebar(text: .diario, icono: ""))
                }
                .buttonStyle(.plain)
                
                
                //Abre ventana de Evaluación:
                Button{
                    showWindow(for: GamePLay(),
                               environmentObjects: [],
                               title: "Diario",
                               size: CGSize(width: 550, height: 400),
                               isModal: false
                    )
                }label:{
                    Label("Evaluación", systemImage: "gear")
                        .tag(ItemSidebar(text: .evaluacion, icono: ""))
                }
                .buttonStyle(.plain)
                
                
                
                //Abre ventana de Ajustes
                Button{
                    showWindow(for: Ajustes(),
                               environmentObjects: [self.context ,self.modelSetting, self.modelFrases, self.modelTxt, self.securityModel],
                               title: "Ajustes",
                               size: CGSize(width: 550, height: 400),
                               isModal: false
                    )
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


//Contenido de Details:
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
                ListNotasViews()
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





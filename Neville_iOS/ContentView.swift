
import SwiftUI
import CoreData


struct ContentView: View {

    @State  private var showSideMenu = false //Para Abrir/cerrar Menu Lateral
    @State  private var showAddNoteView = false //Abre la view AddNota
    @State  private var showAddNoteList = false //Abre la view NoteList
    @State  private var frase : Frases = manageFrases().getRandomFraseEntity()
    @State  private var isfav  = false //chequea si la frase actual es favorita
    @State  private var isHaveNote = false //Chequea si la frase actual tiene nota
    
    @State  private var fontSize : CGFloat = 24 //Setting para Frases
    @State  private var fontSizeMenu : CGFloat = 24 //Setting para menu
    
    @State private var colorFrase : Color = SettingModel().loadColor(forkey: Constant.setting_color_frases)
    
    @State private var colorFondo_a : Color = SettingModel().loadColor(forkey: Constant.setting_color_main_a)
    @State private var colorFondo_b : Color = SettingModel().loadColor(forkey: Constant.setting_color_main_b)

    
    
    //esto es solo un ejemplo Yprjandis

    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                VStack{
                    Spacer()
                    FrasesView(frase: $frase, isFav: $isfav, isHaveNote: $isHaveNote, fontSize: $fontSize, colorFrase: $colorFrase)
                        .onAppear {
                            readFraseStatus(fraseEntity: frase, isfav: &isfav, isHaveNote: &isHaveNote)
                            fontSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.setting_fontFrasesSize))
                            colorFrase = SettingModel().loadColor(forkey: Constant.setting_color_frases)
                            
                        }
                    Spacer()
                    TabButtonBar(showSideMenu: $showSideMenu, fontFrasesSize: $fontSize, fontMenuSize: $fontSizeMenu, colorFrase: $colorFrase, colorFondo_a: $colorFondo_a, colorFondo_b: $colorFondo_b)
                }
                
                //Menú lateral
                GeometryReader{ geometry in
                    HStack {
                        Spacer()
                        SideMenuView(fontSize: $fontSizeMenu, colorFondo_a: $colorFondo_a, colorFondo_b: $colorFondo_b)
                        .offset(x : showSideMenu ? 0 :  UIScreen.main.bounds.width)
                        
                    }
                    
                }
                //Opacar el fondo cuando se muestre el menú
                .background(Color.black.opacity(showSideMenu ? 0.3 : 0  ))
                
                
            }
            .modifier(mof_ColorGradient(colorInit: $colorFondo_a, colorEnd: $colorFondo_b))
            .navigationTitle( Constant.appName)
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                withAnimation {
                    showSideMenu = false
                }
               
            }
            .gesture(DragGesture().onEnded{ value in
                let start = value.startLocation
                let end = value.location
                
                if start.x > end.x + 24 { //right->left
                    withAnimation {
                        showSideMenu = true }
                }else if start.y > end.y + 24 {//up
                    frase = manageFrases().getRandomFraseEntity()
                    readFraseStatus(fraseEntity: frase, isfav: &isfav, isHaveNote: &isHaveNote)
                }
                else if start.x < end.x - 24 {} //left -> right
                else if start.y < end.y - 24 {} //down
                
            })
            .toolbar{
                HStack(spacing: 10){
                
                    //Solo muestra el botón de fav para frases si se muestra el texto de una frase
                    if frase.frase ?? "" != "" {
                        Button{
                            FavHandlerFrases()
                        }label: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(  isfav ? Constant.favoriteColorOn : Constant.favoriteColorOff)
                                
                                            
                        }
                    }
                    
                    Button{
                        showAddNoteView = true
                    }label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(isHaveNote  ? .orange : .black)
                    }
                    
                }
                .padding(.trailing, 15)
            }
            .sheet(isPresented: $showAddNoteView){ //permite modificar la nota de una frase
                NotaFraseAddView(idFrase: frase.id ?? "", nota: frase.nota ?? "")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                    //.interactiveDismissDisabled() //No deja que se oculte
            }
            .sheet(isPresented: $showAddNoteList){
                ListNotasViews()
            }
            
        }
        
    }//body
    
    
    ///Onclick del botón favorito (toolbar) para frases: marca/des-marca los fav
   private func FavHandlerFrases(){
        if manageFrases().getFavState(fraseID: manageFrases.idFraseActual) { //si esta marcado con fav
            if  manageFrases().updateFavState(fraseID: manageFrases.idFraseActual, statusFav: false) {
                isfav = false
            }
        }else { //Si esta inactivo: marcar como favorito
            if  manageFrases().updateFavState(fraseID: manageFrases.idFraseActual, statusFav: true) {
                isfav = true
            }
        }
    }
    



}//struct

//Frases View
struct FrasesView : View{
    @Binding var frase : Frases
    @Binding var isFav : Bool
    @Binding var isHaveNote : Bool
    @Binding var fontSize : CGFloat
    @Binding var colorFrase : Color
    
    var body: some View{
        VStack{
            Text(frase.frase ?? "")
                .font(.system(size: fontSize, design: .rounded))
                .foregroundStyle(colorFrase)
                .modifier(mof_frases())
                .onTapGesture {
                    frase = manageFrases().getRandomFraseEntity()
                    readFraseStatus(fraseEntity: frase, isfav: &isFav, isHaveNote: &isHaveNote)
                }
        }
    }
    
}




//CustomTabView
struct TabButtonBar : View{
    
    @Binding var showSideMenu : Bool
    @State var showOptionView = false
    @Binding var fontFrasesSize : CGFloat //Setting
    @Binding var fontMenuSize : CGFloat //Setting$
    
    @Binding var colorFrase : Color
    
    @Binding var colorFondo_a : Color
    @Binding var colorFondo_b : Color
    

    let  tabButtons = Constant.tabButtons
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        HStack{
            ForEach (tabButtons, id: \.self ){ idx in
            
                switch idx{
                case "book.pages.fill":
                    
                    NavigationLink{TxtListView( typeContent: .conf)
                    }label: {makeItemlabel(image: idx)}
                    
                case "video.fill":
                    NavigationLink{ YTLisIDstView(typeContent: .video_Conf)
                    }label: {makeItemlabel(image: idx)}
                
                case "house.circle.fill":
                    Button{
                        showOptionView = true
                    }label: {
                        makeItemlabel(image: idx)
                            .font(.system(size: 32, weight: .bold))
                    }
                    
                case "video.badge.waveform.fill":
                    NavigationLink{ YTLisIDstView(typeContent: .aud_libros)
                    }label: {makeItemlabel(image: idx)}
                    
                    
                case "list.bullet":
                    Button{
                        withAnimation {showSideMenu.toggle()
                        }
                    }label: {makeItemlabel(image: showSideMenu ? "xmark" : idx ) }
                default: EmptyView()
                    
                }
                
                //Insertando un espaciado para mantener la distancia entre los items
                if idx != tabButtons.last {
                    Spacer(minLength: 0)
                }
                
            }//ForEach
            
        }
        
        .padding(.horizontal, 25)
        .background(LinearGradient(colors: [.gray, .cyan], startPoint: .top, endPoint: .bottom))
        //.modifier(mof_ColorGradient(colorInit: $colorFondo_a, colorEnd: $colorFondo_b))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 5, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: -5, y: -5)
        .padding(.horizontal)
        
        .sheet(isPresented: $showOptionView) {
            optionView()
                .presentationDetents([.height(180)])
                .presentationDragIndicator(.hidden)
            //Al ocultar las opciones: se actualiza el tamaño de fuente de las frases
                .onDisappear(perform: {
                    fontFrasesSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.setting_fontFrasesSize))
                    fontMenuSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.setting_fontMenuSize))
                    
                    colorFrase = SettingModel().loadColor(forkey: Constant.setting_color_frases)
                    
                    colorFondo_a = SettingModel().loadColor(forkey: Constant.setting_color_main_a)
                    colorFondo_b = SettingModel().loadColor(forkey: Constant.setting_color_main_b)
                })
        }
    }
    
    //Create UI for reusability
    func makeItemlabel(image : String)->some View{
        return Image(systemName: image)
            .renderingMode(.template)
            .foregroundColor( Color.black.opacity(0.4))
            .padding(10)
        
    }
    
}


//Permite guardar una nueva nota en la BD
struct AddNotasViewInbuilt: View {
    @Environment(\.dismiss) var dimiss
    
    @State var title : String = ""
    @State var nota : String = ""
    
    
    
    var body: some View {
        NavigationStack {
            Form{
                Section("Título"){
                    TextField("", text: $title, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    
                }
                Section("Nota"){
                    TextField("", text: $nota, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle("Adicionar una nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar"){
                        if !save() {
                            print("se ha producido un error al guardar la nota")
                        }
                        
                        dimiss()
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar"){
                        dimiss()
                    }
                }
            }
        }
        
    }
    
    ///Guardar un valor y actualiza el arreglo de notas pasado como @Binding
    ///- Returns : true si exito, false otherwise
    func save()-> Bool{
        let title = title.trimmingCharacters(in: .whitespaces)
        let nota = nota.trimmingCharacters(in: .whitespaces)
        
        if (nota.isEmpty || title.isEmpty) {return false}
        
        if  manageNotas().addNote(nota: nota, title: title).0 {
            return true
        }else{
            return false
        }
    }
    
}





///Actualiza el estado de la variable isfav: Se llama cada vez que se carga una frase nueva
///
///El parámetro es pasado in-line y corresponde con una variable @State de ContentView. Esto es una forma de actualizar una variable de estado desde fuera de la struct
///
/// - Parameter isfav : variable @State que controla el color del icono de fav para frases, en la toolBar
func readFraseStatus( fraseEntity : Frases?, isfav : inout Bool, isHaveNote : inout Bool){
    if let frase = fraseEntity {
        isfav = frase.isfav
        let nota = frase.nota
        if nota == "" {
            isHaveNote = false
        }else{
            isHaveNote = true
        }
    }
}



#Preview {
    ContentView()
}

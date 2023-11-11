
import SwiftUI
import CoreData


struct ContentView: View {
    
    @State  private var showSideMenu = false //Para Abrir/cerrar Menu Lateral
    @State  private var showAddNoteList = false //Abre la view AddNota
    
    @State  private var frase : Frases = FrasesModel().getRandomFraseEntity()
    @State  private var isHaveNote = false //Chequea si la frase actual tiene nota
    
    @State  private var fontSize : CGFloat = 24 //Setting para Frases
    @State  private var fontSizeMenu : CGFloat = 24 //Setting para menu
    
    @State private var colorFrase : Color = SettingModel().loadColor(forkey: Constant.UD_setting_color_frases)
    
    @State private var colorFondo_a : Color = SettingModel().loadColor(forkey: Constant.UD_setting_color_main_a)
    @State private var colorFondo_b : Color = SettingModel().loadColor(forkey: Constant.UD_setting_color_main_b)
    
    

    
    
    //esto es solo un ejemplo Yprjandis

    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                VStack{
                    Spacer()
                    FrasesView(frase: $frase, isHaveNote: $isHaveNote, fontSize: $fontSize, colorFrase: $colorFrase)
                        .onAppear {
                            fontSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.UD_setting_fontFrasesSize))
                            colorFrase = SettingModel().loadColor(forkey: Constant.UD_setting_color_frases)
                            
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
                    frase = FrasesModel().getRandomFraseEntity()
                }
                else if start.x < end.x - 24 {} //left -> right
                else if start.y < end.y - 24 {} //down
                
            })
            .toolbar{
                HStack(spacing: 5){
                    
                    NavigationLink{
                        DiarioListView()
                    }label: {
                        Image(systemName: "book")
                            .foregroundStyle(Color.primary)
                    }
           
                }
                .padding(.trailing, 15)
            }
            
            .sheet(isPresented: $showAddNoteList){
                ListNotasViews()
            }
            
            
        }
        
    }//body
    
    

    



}//struct

//Frases View
struct FrasesView : View{
    @Binding var frase : Frases
    @Binding var isHaveNote : Bool
    @Binding var fontSize : CGFloat //setting
    @Binding var colorFrase : Color //setting
    //Para Adicionar una nueva frase
    @State private var showSheetAddFrase = false
    //Para notas en frases
    @State private var showAddNoteView = false
    @State private var isFav = false
    
    
    var body: some View{
        VStack{
            Text(frase.frase ?? "")
                .font(.system(size: fontSize, design: .rounded))
                .foregroundStyle(colorFrase)
                .modifier(mof_frases())
                .onTapGesture {
                    frase = FrasesModel().getRandomFraseEntity()
                    readFraseStatus(fraseEntity: frase, isfav: &isFav, isHaveNote: &isHaveNote)
                }
            
            HStack(spacing:15){
                Spacer()
                
                Button{
                    FavHandlerFrases()
                }label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundStyle(isFav ? Constant.favoriteColorOn : Constant.favoriteColorOff)
                }
                .onAppear{
                    readFraseStatus(fraseEntity: frase, isfav: &isFav, isHaveNote: &isHaveNote)
                }
                
                Menu{
                    Button("Convertir en Nota"){ }
                    NavigationLink("Generar QR"){
                        GenerateQRView(string: frase.frase ?? "", footer: frase.frase ?? "")
                    }
                    Button{
                        showAddNoteView = true
                    }label: {
                        Label("Adicionar una nota", systemImage: "bookmark.fill" )
                    }
                    Button("Nueva Frase"){
                        showSheetAddFrase = true
                    }
                    
                    
                }label: {
                    HStack{
                        Image(systemName: "ellipsis")
                            .tint(.black)
                            .padding(.trailing, 25)
                            .frame(width: 50, height: 50)
                        
                    }
                   
                }
            }
           
        }
        .sheet(isPresented: $showAddNoteView){ //permite modificar la nota de una frase
            FrasesNotasAddView(idFrase: frase.id ?? "", nota: frase.nota ?? "")
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
                //.interactiveDismissDisabled() //No deja que se oculte
        }
        .sheet(isPresented: $showSheetAddFrase){
            FraseAddView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
    
    ///Onclick del botón favorito (toolbar) para frases: marca/des-marca los fav
   private func FavHandlerFrases(){
        if FrasesModel().getFavState(fraseID: FrasesModel.idFraseActual) { //si esta marcado con fav
            if  FrasesModel().updateFavState(fraseID: FrasesModel.idFraseActual, statusFav: false) {
                isFav = false
            }
        }else { //Si esta inactivo: marcar como favorito
            if  FrasesModel().updateFavState(fraseID: FrasesModel.idFraseActual, statusFav: true) {
                isFav = true
            }
        }
    }
    
}




//CustomTabView
struct TabButtonBar : View{
    
    @Binding    var showSideMenu : Bool
    @State      var showOptionView = false
    @Binding    var fontFrasesSize : CGFloat //Setting
    @Binding    var fontMenuSize : CGFloat //Setting$
    
    @Binding    var colorFrase : Color
    
    @Binding    var colorFondo_a : Color
    @Binding    var colorFondo_b : Color
    

    let  tabButtons = ["book.pages.fill","video.fill","house.circle.fill","video.badge.waveform.fill", "list.bullet"]
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        HStack{
            ForEach (tabButtons, id: \.self ){ idx in
            
                switch idx{
                case "book.pages.fill":
                    
                    NavigationLink{TxtListView(type: .conf, title: "Conferencias")
                    }label: {makeItemlabel(image: idx)}
                    
                case "video.fill":
                    NavigationLink{ YTLisIDstView(type: .video_Conf)
                    }label: {makeItemlabel(image: idx)}
                
                case "house.circle.fill":
                    Button{
                        showOptionView = true
                    }label: {
                        makeItemlabel(image: idx)
                            .font(.system(size: 32, weight: .bold))
                    }
                    
                case "video.badge.waveform.fill":
                    NavigationLink{ YTLisIDstView(type: .aud_libros)
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
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.hidden)
            //Al ocultar las opciones: se actualiza el tamaño de fuente de las frases
                .onDisappear(perform: {
                    fontFrasesSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.UD_setting_fontFrasesSize))
                    fontMenuSize = CGFloat(UserDefaults.standard.integer(forKey: Constant.UD_setting_fontMenuSize))
                    
                    colorFrase = SettingModel().loadColor(forkey: Constant.UD_setting_color_frases)
                    
                    colorFondo_a = SettingModel().loadColor(forkey: Constant.UD_setting_color_main_a)
                    colorFondo_b = SettingModel().loadColor(forkey: Constant.UD_setting_color_main_b)
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
        
        if  NotasModel().addNote(nota: nota, title: title) {
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

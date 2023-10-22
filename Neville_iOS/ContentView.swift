
import SwiftUI
import CoreData


struct ContentView: View {

    @State  var showSideMenu = false //Para Abrir/cerrar Menu Lateral
    @State  var showAddNoteView = false //Abre la view AddNota
    @State  var showAddNoteList = false //Abre la view NoteList
    @State  var frase : String = manageFrases().getRandomFrase()
    @State  var isfav  = false
    @State  var isHaveNote = false
    
    

    
    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                VStack{
                    Spacer()
                    FrasesView(frase: $frase, isfav: $isfav)
                    Spacer()
                    TabButtonBar(showSideMenu: $showSideMenu, frase: $frase, isfav: $isfav )
                }
                
                //Menú lateral
                GeometryReader{ geometry in
                    HStack {
                        Spacer()
                        SideMenuView()
                        .offset(x : showSideMenu ? 0 :  UIScreen.main.bounds.width)
                        
                    }
                    
                }
                //Opacar el fondo cuando se muestre el menú
                .background(Color.black.opacity(showSideMenu ? 0.3 : 0  ))
                
                
            }
            .modifier(mof_ColorGradient(colorInit: .brown, colorEnd: .orange, color3: .pink))
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
                    frase = manageFrases().getRandomFrase()
                    readFavInFrases(isfav: &isfav)
                }
                else if start.x < end.x - 24 {} //left -> right
                else if start.y < end.y - 24 {} //down
                
            })
            .toolbar{
                HStack(spacing: 10){
                    
                    //Solo muestra el botón de fav para frases si se muestra el texto de una frase
                    if !frase.isEmpty {
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
                        Image(systemName: "note.text.badge.plus")
                            .foregroundColor(isHaveNote  ? .orange : .black)
                    }
                    
                }
                .padding(.trailing, 15)
            }
            .sheet(isPresented: $showAddNoteView){
                AddNotasViewInbuilt()
                //Custiomizes the sheet:
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
    func FavHandlerFrases(){
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

     @Binding var frase : String
     @Binding var isfav : Bool

    var body: some View{
            VStack{
                    Text(frase)
                    .modifier(mof_frases())
                        .onTapGesture {
                            frase = manageFrases().getRandomFrase()
                            readFavInFrases(isfav: &isfav)
                        }
            }

    }
    
}


//CustomTabView
struct TabButtonBar : View{
    
    @Binding var showSideMenu : Bool
    @Binding var frase : String
    @Binding var isfav : Bool
    @State var showOptionView = false


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
                    
                case "video.circle.fill":
                    NavigationLink{ YTLisIDstView(typeContent: .aud_libros)
                    }label: {makeItemlabel(image: idx)}
                    
                    
                case "slider.vertical.3":
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
        .padding(.vertical, 2)
        .modifier(mof_ColorGradient(colorInit: .white, colorEnd: .orange, color3: nil))
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 5, y: 5)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: -5, y: -5)
        .padding(.horizontal)
        
        .sheet(isPresented: $showOptionView) {
            optionView()
                .presentationDetents([.height(180)])
                .presentationDragIndicator(.hidden)
        }
    }
    
    //Create UI for reusability
    func makeItemlabel(image : String)->some View{
        return Image(systemName: image)
            .renderingMode(.template)
            .foregroundColor( Color.black.opacity(0.4))
            .padding()
        
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
///el parámetro es pasado in-line y corresponde con una variable @State de ContentView. Esto es una forma de actualizar una variable de estado desde fuera de la struct
///
/// - Parameter isfav : variable @State que controla el color del icono de fav para frases, en la toolBar
func readFavInFrases( isfav : inout Bool){
    if manageFrases().getFavState(fraseID: manageFrases.idFraseActual){
        isfav = true
    }else{
        isfav = false
    }
}






#Preview {
    ContentView()
}

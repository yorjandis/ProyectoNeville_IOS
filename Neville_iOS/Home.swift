//
//  Home.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/11/23.
//

import SwiftUI

struct Home: View {

    @State  private var showAddNoteList = false //Abre la view AddNota
    
    @State  private var isHaveNote = false //Chequea si la frase actual tiene nota
    
    @State  private var fontSize : CGFloat = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize)) //Setting para Frases
    @State  private var fontSizeMenu : CGFloat = 24 //Setting para menu
    
    @State private var colorFrase : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_frases)
    
    @State private var colorFondo_a : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a)
    @State private var colorFondo_b : Color = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)
    
    //Para chequeo de actualización de la app:
    @State private var showTextUpdateApp = false
    
    //Para determinar cuando se ha cambiado los colores y actualizar el fondo de pantalla.
    @State private var isSettingChanged : Bool = false

    


    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                
                VStack{
                    //Muestra el texto para indicar nueva actualización
                    if showTextUpdateApp {
                        Button{
                            if let url = URL(string: "https://apps.apple.com/es/app/la-ley/id6472626696"),
                               UIApplication.shared.canOpenURL(url){
                                UIApplication.shared.open(url, options: [:]) { (opened) in
                                    if(opened){
                                        // print("App Store Opened")
                                    }
                                }
                            } else {
                                // print("Can't Open URL on Simulator")
                            }
                        }label: {
                            HStack{
                                Image(systemName: "exclamationmark.circle")
                                    .symbolEffect(.pulse, isActive: true)
                                Text("Existe una nueva versión de la App")
                            }
                            .foregroundStyle(Color.black)
                            .font(.system(size: 15))
                            
                        }
                    }
                    
                    Spacer()
                    
                    FrasesView(isHaveNote: $isHaveNote, fontSize: $fontSize, colorFrase: $colorFrase)
 
                    Spacer()
                    TabButtonBar(fontFrasesSize: $fontSize, fontMenuSize: $fontSizeMenu, colorFrase: $colorFrase, colorFondo_a: $colorFondo_a, colorFondo_b: $colorFondo_b, isSettingChanged: $isSettingChanged)
                }
                .task {
                    do {
                        try await CheckAppStatus().getAppNewVersion { update in
                            if update{
                                showTextUpdateApp = true
                            }else{
                                showTextUpdateApp = false
                            }
                        }
                    }catch{
                        print(error.localizedDescription)
                    }
                    
                }
                .onChange(of: self.isSettingChanged) {
                    fontSize        = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize))
                    colorFrase      = SettingModel().loadColor(forkey: AppCons.UD_setting_color_frases)
                    colorFondo_a    = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_a)
                    colorFondo_b    = SettingModel().loadColor(forkey: AppCons.UD_setting_color_main_b)
                }
                .modifier(mof_ColorGradient(colorInit: $colorFondo_a, colorEnd: $colorFondo_b))
                .navigationTitle( AppCons.appName)
                .navigationBarTitleDisplayMode(.inline)
                .gesture(DragGesture().onEnded{ value in
                    let start = value.startLocation
                    let end = value.location
                    
                    if start.x > end.x + 24 { //right->left
                        withAnimation {
                        }
                    }else if start.y > end.y + 24 {//up
                        
                    }
                    else if start.x < end.x - 24 {} //left -> right
                    else if start.y < end.y - 24 {} //down
                    
                })
                
                .sheet(isPresented: $showAddNoteList){
                    ListNotasViews()
                }
                
                
            }
            
        }
        
    }
    

   

}//struct


//Frases View
struct FrasesView : View{
    @State private var  frase : Frases = FrasesModel().getRandomFraseEntityNoAsync() ?? Frases(context: CoreDataController.shared.context)
    @Binding var isHaveNote : Bool
    @Binding var fontSize : CGFloat //setting
    @Binding var colorFrase : Color //setting
    //Para Adicionar una nueva frase
    @State private var showSheetAddFrase = false
    //Para notas en frases
    @State private var showAddNoteView = false
    @State private var isFav = false
    @State private var animationHeart = 0
    
    
    
    var body: some View{
        
        if (frase.frase?.isEmpty == false) { //Si frase se ha cargado
            VStack{
                Text( frase.frase ?? "")
                    .font(.system(size: fontSize, design: .rounded))
                    .foregroundStyle(colorFrase)
                    .modifier(mof_frases())
                    .id(frase.frase)
                    .animation(.smooth(duration: 2), value: frase.frase)
                    .onTapGesture {
                        frase = FrasesModel().getRandomFraseEntityNoAsync() ?? Frases(context: CoreDataController.shared.context)
                        readFraseStatus(fraseEntity: frase, isfav: &isFav, isHaveNote: &isHaveNote)
                    }
                    .task{
                        self.frase = FrasesModel().getRandomFraseEntityNoAsync() ?? Frases(context: CoreDataController.shared.context)
                    }
                    .onOpenURL(perform: { url in
                        if url.description == AppCons.DeepLink_url_Frase {
                            frase = FrasesModel().GetFraseFromTextFrase(frase: UserDefaults.shared().string(forKey: AppCons.UD_shared_FraseWidgetActual) ?? "")!
                        }
                    })
                    .contextMenu{
                        Button("Convertir en Nota"){
                            //Guarda la nota poniendo como titulo una parte de la cadena
                            _ = NotasModel().addNote(nota: frase.frase ?? "", title: "\(String(String(frase.frase ?? "").prefix(frase.frase!.count / 3 )))...")
                        }
                        NavigationLink("Generar QR"){
                            GenerateQRView(footer: frase.frase ?? "", showImage: true)
                        }
                        Button{
                            showAddNoteView = true
                        }label: {
                            Label("Adicionar una nota", systemImage: "bookmark.fill" )
                        }
                        Button("Nueva Frase"){
                            showSheetAddFrase = true
                        }
                    }
                
                HStack(){
                    Spacer()
                    
                    Button{
                        FrasesModel().handleFavState(frase: frase)
                        isFav = frase.isfav ? true : false
                        animationHeart += 1
                    }label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .foregroundStyle(isFav ? AppCons.favoriteColorOn : AppCons.favoriteColorOff)
                            .symbolEffect(.bounce, value: animationHeart)
                    }
                    .padding(10)
                    .padding(.trailing, 15)
                    .onAppear{
                        readFraseStatus(fraseEntity: frase, isfav: &isFav, isHaveNote: &isHaveNote)
                    }
                }
                
            }
            
            .sheet(isPresented: $showAddNoteView){ //permite modificar la nota de una frase
                FrasesNotasAddView(frase: self.frase, nota: self.frase.nota ?? "")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                //.interactiveDismissDisabled() //No deja que se oculte
            }
            .sheet(isPresented: $showSheetAddFrase){
                FraseAddView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            
        }else{ //Si la frase a cargar no tiene contenido...se intenta recuperar una frase válida
            //Carga una frase de texto del fichero txt del bundle
            ProgressView {
                Text("Recuperando el contenido...")
            }
            .task {
                //Crea una frase temporal, no la almacena en Core Data
                let frastemp = Frases(context: CoreDataController.shared.context)
                frastemp.frase = FrasesModel().getfrasesArrayFromTxtFile().randomElement()
                self.frase = frastemp 
            }
        }
    }

    

}




//CustomTabView
struct TabButtonBar : View{
    
    @State      var showOptionView = false
    @Binding    var fontFrasesSize : CGFloat //Setting
    @Binding    var fontMenuSize : CGFloat //Setting$
    
    @Binding    var colorFrase : Color
    
    @Binding    var colorFondo_a : Color
    @Binding    var colorFondo_b : Color
    
    //Actualiza la UI de Home si cambia valores en setting
    @Binding    var isSettingChanged : Bool ////Para actualizar los valores de configuración
    
    

    @State private var showSetting = false
    
    
    @State private var sellectionTab = 1
    

    @State var  tabButtons = ["book.pages.fill","note.text","house.circle.fill","book", "gear"]
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        HStack{
            ForEach(tabButtons, id:\.self){idx in
                switch idx{
                case "book.pages.fill":
                    NavigationLink{
                        TxtListView(type: .conf, title: "Lecturas")
                    }label: {
                        makeItemlabel(image: idx)
                    }
                    
                case "note.text":
                    NavigationLink{
                       ListNotasViews()
                    }label: {
                        makeItemlabel(image: idx)
                    }
                
                case "house.circle.fill":
                    Button{              
                       showOptionView = true
                    }label: {
                        makeItemlabel(image: idx)
                            .font(.system(size: 30))
                    }
                    
                case "book":
                    NavigationLink{ DiarioListView()
                    }label: {makeItemlabel(image: idx)}
                    
                case "gear":
                    Button{ showSetting = true
                    }label: {makeItemlabel(image: idx)}

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
            optionView(isSettingChanged: $isSettingChanged)
               .presentationDetents([.height(280)])
               .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSetting, content: {
            settingView(isSettingChanged: $isSettingChanged)
        })
    }
    
    //Create UI for reusability
    func makeItemlabel(image : String)->some View{
        return Image(systemName: image)
            .renderingMode(.template)
            .foregroundColor( Color.black.opacity(0.4))
            .padding(10)
        
    }
    
}


//View: Permite guardar una nueva nota en la BD
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

//
//  Home.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 22/11/23.
//

import SwiftUI

struct Home: View {

    @EnvironmentObject private var settingModel : SettingModel
    
    @State  private var showAddNoteList = false //Abre la view AddNota
    
    @State  private var fontSize : CGFloat = CGFloat(UserDefaults.standard.integer(forKey: AppCons.UD_setting_fontFrasesSize)) //Setting para Frases
    @State  private var fontSizeMenu : CGFloat = 24 //Setting para menu
    

    //Para chequeo de actualización de la app:
    @State private var showTextUpdateApp = false

    //Para determinar el cumpleaños de neville:
    // Día y mes del cumpleaños 🎂
        @State private var esCumple = false
        @State private var fechaActual = Date()
        private let dia = 19
        private let mes = 2
    
    private func chequearCumple() {
            let componentes = Calendar.current.dateComponents([.day, .month], from: fechaActual)
            esCumple = (componentes.day == dia && componentes.month == mes)
        }
    
    //Determinar si estamos en modo debug
#if DEBUG
    private let isDebug = true
#else
    private let isDebug = false
#endif

    


    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                
                LinearGradient(gradient: Gradient(colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack{
                    
                    
                    
                    //Muestra un texto para felicitar a neville por su cumpleños(19 Frebrero)
                    if self.esCumple{
                        VStack{
                            Text("Felicidades Maestro Neville! 💖").font(.title).fontDesign(.serif)
                            Text("Gracias por tu Amor y Enseñanzas").font(.callout).fontDesign(.serif)
                        }.foregroundStyle(.black)
                        
                    }
                    
                    
                    
                    
                    //Muestra si estamos en modo debug. Solo aparecerá en la fase de desarrollo
                    if self.isDebug{
                        Text("Modo Debug").padding()
                    }
                    
                    
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
                    
                    FrasesView()
 
                    Spacer()
                    TabButtonBar(
                        fontFrasesSize: $fontSize,
                        fontMenuSize: $fontSizeMenu,
                        colorFrase:  Binding(get: { self.settingModel.colorfrase }, set: { self.settingModel.colorfrase = $0 }),
                        colorFondo_a: Binding(get: { self.settingModel.colorFondo_a }, set: { self.settingModel.colorFondo_a = $0 }),
                        colorFondo_b: Binding(get: { self.settingModel.colorFondo_b }, set: { self.settingModel.colorFondo_b = $0 })
                    )
                }
                .onAppear{
                        self.chequearCumple()
                    }
                .task {
                    do {
                        try await CheckAppStatus().getAppNewVersion { update in
                            if update{
                                DispatchQueue.main.async {
                                    showTextUpdateApp = true
                                } 
                            }else{
                                DispatchQueue.main.async {
                                    showTextUpdateApp = false
                                }
                            }
                        }
                    }catch{
                        print(error.localizedDescription)
                    }
                    
                }
                .navigationTitle("La Ley")
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


//Frases View. Cuadro de frase en la pantalla inicial
struct FrasesView : View{
    @EnvironmentObject private var frasesModel : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    
    @State private var  frase : String = "" //Texto de la Frase
   
    @AppStorage(AppCons.UD_setting_fontFrasesSize) var fontSizeFrases : Int = 24
    //Para Adicionar una nueva frase
    @State private var showSheetAddFrase = false
    
    //Para notas en frases
    @State private var showAddNoteView = false
    @State private var isFav = false //muestra un corazon lleno o vacio según el valor
    @State private var animationHeart = 0

    private var fraseCompartir : String{
        let frase = Frase(texto: self.frase)
        return frase.texto
    }
    
    var body: some View{

            VStack{
                Text(self.frase)
                    .font(.system(size: CGFloat(fontSizeFrases), design: .rounded))
                    .foregroundStyle(self.settingModel.colorfrase)
                    .modifier(mof_frases())
                    .onTapGesture {
                        self.frase = frasesModel.getRandomFrase()
                        self.isFav = frasesModel.isFavFrase(self.frase) //Actualizando el estado
                        frasesModel.favStateOfCurrentFrase = self.isFav
                        frasesModel.fraseActual = self.frase //Guardando la frase actualmente visible en la variable observable
                    }
                    .onOpenURL(perform: { url in
                        if url.description == AppCons.DeepLink_url_Frase {
                            self.frase = UserDefaults.shared().string(forKey: AppCons.UD_shared_FraseWidgetActual) ?? ""
                        }
                        
                    })
                    .contextMenu{
                        Button{
                            //Guarda la nota poniendo como titulo una parte de la cadena
                            _ = NotasModel().addNote(nota: self.frase, title: "\(String(self.frase).prefix(self.frase.count / 3 )))...")
                        }label: {
                            Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
                        }
                        
                        
                        NavigationLink{
                            GenerateQRView(footer: self.frase, showImage: true)
                        }label:{
                            Label("Generar QR", systemImage: "qrcode")
                        }
                        
                        ShareLink(item: self.frase) {
                                        Label("Compartir frase", systemImage: "square.and.arrow.up")
                                    }
                        
                        Button{
                            showAddNoteView = true
                        }label: {
                            Label("Nota de la frase", systemImage: "bookmark.fill" )
                        }
                        
                        if #available(iOS 26.0, *)  {
                            
                            if IAModel.isAvailable(){
                                NavigationLink{
                                    RespondView(nameConference: "", texto: self.frase, tipoSalida: .interpretar)
                                }label: {
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    RespondView(nameConference: "", texto: self.frase, tipoSalida: .practicaConcreta)
                                }label: {
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.purple)
                            }
                            
                            
                            
                        }
                        
                        Button{
                            showSheetAddFrase = true
                        }label: {
                            Label("Nueva frase", systemImage: "square.and.pencil.circle")
                        }
                    }
                
                HStack(){
                    Spacer()
                    
                    //Boton de Favorito de la frase
                    Button{
                        let getState = frasesModel.isFavFrase(self.frase) //Obtiene el estado previo
                        if frasesModel.setFavFrase(self.frase, !getState){
                            isFav = !getState
                            frasesModel.favStateOfCurrentFrase = isFav
                            animationHeart += 1
                        }
                        
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        
                    }label: {
                        Image(systemName: frasesModel.favStateOfCurrentFrase ? "heart.fill" : "heart")
                            .foregroundStyle(.black)
                            .symbolEffect(.bounce, value: animationHeart)
                    }
                    .padding(10)
                    .padding(.trailing, 15)
                    
                }
                
            }
            .onAppear{
                self.frase = frasesModel.getRandomFrase()
                //leyendo el estado isfav de la frase
                isFav = frasesModel.isFavFrase(frase) //Obtiene el estado previo
                frasesModel.favStateOfCurrentFrase = isFav //Actualiza el estado del favorito en la variable observable
                frasesModel.fraseActual = self.frase //Almacenando la frase actualmente visible en Home
                //animationHeart += 1
            }
            
            .sheet(isPresented: $showAddNoteView){ //permite modificar la nota de una frase
                
                FrasesNotasAddView(frase: self.frase, nota: self.frasesModel.GetNotaAsociadaFrase(frase: self.frase))
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

    

}




//CustomTabView
struct TabButtonBar : View{
    
    @EnvironmentObject private var frasesModel : FrasesModel
    @State      var showOptionView = false
    @Binding    var fontFrasesSize : CGFloat //Setting
    @Binding    var fontMenuSize : CGFloat //Setting$
    
    @Binding    var colorFrase : Color
    
    @Binding    var colorFondo_a : Color
    @Binding    var colorFondo_b : Color
    

    @State private var showSetting = false
    
    
    @State private var sellectionTab = 1
    

    @State var  tabButtons = ["book.pages.fill","note.text","house.circle.fill","book", "gear"]
    
    var body: some View{
        
        //Creando La bottom Bar con los item del menu
        VStack{
            HStack{
                ForEach(tabButtons, id:\.self){idx in
                    switch idx{
                    case "book.pages.fill": //Listado de Conferencias
                        NavigationLink{
                            TxtListView(typeOfContent: .conf, title: "Lecturas")
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
                        if #available(iOS 26.0, *){
                            if IAModel.isAvailable(){
                                NavigationLink{
                                        ChatView()
                                }label: {
                                    Image(systemName: "ellipsis.message")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.black.opacity(0.7))
                                        .padding(8)
                                }
                            }else{
                                Button{ showSetting = true
                                }label: {
                                    makeItemlabel(image: idx)
                                    
                                }
                            }
                        }else{
                            Button{ showSetting = true
                            }label: {
                                makeItemlabel(image: idx)
                                
                            }
                        }
                        

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
            .padding(.vertical, 5)
        }
        .onChange(of: self.showOptionView, { oldValue, newValue in
            //Si se ha cerrado la ventana modal del las opciones en la tabBar:
            if !newValue {
                //Actualizando el estado de favorito de la frase actual
                withAnimation {
                    self.frasesModel.favStateOfCurrentFrase = frasesModel.isFavFrase(frasesModel.fraseActual)
                }
                
            }
        })
        
        .sheet(isPresented: $showOptionView) {
            optionView()
               .presentationDetents([.height(280)])
               .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSetting, content: {
            settingView()
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








#Preview {
    ContentView()
}


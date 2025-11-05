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


    var body: some View {
        NavigationStack{
            
            ZStack(alignment: .bottom){
                
                LinearGradient(gradient: Gradient(colors: [settingModel.colorFondo_a, settingModel.colorFondo_b]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                VStack{
                    
                    //Muestra el logo de la App dentro de un rectángulo áureo
                    GoldenLogoNeville()
                    
                    
                    //Muestra un texto para felicitar a neville por su cumpleños(19 Frebrero)
                    MostrarCumpleaños()
                    
                    //Muestra si estamos en modo debug. Solo aparecerá en la fase de desarrollo
                   // MostrarModoDebug()
                    
                    
                    //Muestra el texto para indicar nueva actualización
                    ViewIfNewUpdateAvailable()
                    
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
    
    //Contador para navegar por la frase
    @State private var contadorNavegarPorFrasesAnteriores : Int = 0
    
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
                        //Obtiene una nueva frase
                        self.frase = frasesModel.getRandomFrase()//Obteniendo una nueva frase.
                        self.isFav = frasesModel.isFavFrase(self.frase) //Actualizando el estado del favorito
                        frasesModel.favStateOfCurrentFrase = self.isFav
                        frasesModel.fraseActual = self.frase //Guardando la frase actualmente visible en la variable observable
                        
                        //Almacenando la frase en el vector de navegación de frases
                        if self.frasesModel.fraseAnteriores.count > 9 { //Si la capacidad del arreglo supera el límite de 10 frases
                            
                            self.frasesModel.fraseAnteriores.removeFirst() //Remueve la primera frase
                            self.frasesModel.fraseAnteriores.append(self.frase) //Coloca la frase actual
                            self.contadorNavegarPorFrasesAnteriores = self.frasesModel.fraseAnteriores.count
                        }else{ //Si no se ha superado la capacidad del arreglo, simplemente agrega la frase actual al mismo
                            
                            self.frasesModel.fraseAnteriores.append(self.frase) //Coloca la frase actual
                            self.contadorNavegarPorFrasesAnteriores = self.frasesModel.fraseAnteriores.count
                        }
                        
                    }
                //Gesto de deslizar izquierda a derecha: navega hacia la frase anterior(hasta un máximo de 10 frases)
                    .gesture(
                        DragGesture().onEnded { value in
                            let start = value.startLocation
                            let end = value.location
                            let threshold: CGFloat = 40
                            
                            // Deslizar de izquierda a derecha → ir hacia atrás
                            if end.x > start.x + threshold {
                                if !self.frasesModel.fraseAnteriores.isEmpty && self.contadorNavegarPorFrasesAnteriores > 0 {
                                    self.contadorNavegarPorFrasesAnteriores -= 1
                                    self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                    
                                    self.isFav = self.frasesModel.isFavFrase(self.frase)
                                    self.frasesModel.favStateOfCurrentFrase = self.isFav
                                    self.frasesModel.fraseActual = self.frase
                                }
                            }
                            // Deslizar de derecha a izquierda → ir hacia adelante
                            else if end.x < start.x - threshold {
                                if self.contadorNavegarPorFrasesAnteriores < self.frasesModel.fraseAnteriores.count - 1 {
                                    self.contadorNavegarPorFrasesAnteriores += 1
                                    
                                    self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                    
                                    self.isFav = self.frasesModel.isFavFrase(self.frase)
                                    self.frasesModel.favStateOfCurrentFrase = self.isFav
                                    self.frasesModel.fraseActual = self.frase
                                }
                            }
                        }
                    )
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
                            
                            if IAModelAppleIntelligence.isAvailable(){
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
                                
                                NavigationLink{
                                    ChatView(textoACargar: self.frase)
                                }label: {
                                    Label("Charlar con IA", systemImage: "sparkles")
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
                if self.frase.isEmpty{
                    self.frase = frasesModel.getRandomFrase()
                    //leyendo el estado isfav de la frase
                    isFav = frasesModel.isFavFrase(frase) //Obtiene el estado previo
                    frasesModel.favStateOfCurrentFrase = isFav //Actualiza el estado del favorito en la variable observable
                    frasesModel.fraseActual = self.frase //Almacenando la frase actualmente visible en Home
                } 
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
                            if IAModelAppleIntelligence.isAvailable(){
                                NavigationLink{
                                    ChatView(textoACargar: nil)
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


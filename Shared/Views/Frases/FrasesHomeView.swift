//
//  FrasesHomeView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 6/11/25.
//

//Frases View. Cuadro de frase en la pantalla inicial

import SwiftUI






struct FrasesHomeView : View{
    @EnvironmentObject private var frasesModel : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    
    @State private var  frase : Frases? = nil
   
    @AppStorage(AppCons.UD_setting_fontFrasesSize) var fontSizeFrases : Int = 24
    @AppStorage(AppCons.UD_setting_showHide_autor_in_frases) var showHideAutorInFrases : Bool = true // Muestra / oculta el aurtor en las frases del Home
    @AppStorage(AppCons.UD_ProgresoUI_PopulandoFrases) private var populandoFrases: Bool = false
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    
    //Para Adicionar una nueva frase
    @State private var showSheetAddFrase = false
    
    //Para notas en frases
    @State private var showAddNoteView = false
    @State private var isFav = false //muestra un corazon lleno o vacio según el valor
    @State private var animationHeart = 0
    
    //Contador para navegar por la frase
    @State private var contadorNavegarPorFrasesAnteriores : Int = 0
    
    
    //Mostrar información de la frase
    @State private var showFraseInformation : Bool = false
    
    private var fraseCompartir : String{
        return frase?.frase ?? ""
    }
    
    //Mostrar Alerta
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    //Pruebas
    @State private var showListaRecordatorios : Bool = false

    //Parámetros para las vistas de autores:
    var authorFilter: String? = nil //Filtro de frases de autores, restringido por acceso premium
    var colorTextAutor : Color? = .white //Color del texto del autor
    
    var body: some View{
        
            VStack{
                if let frase = self.frase{
                    
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)

                                Text(frase.frase ?? "")
                                    .font(.system(size: CGFloat(fontSizeFrases), design: .rounded))
                                    .foregroundStyle( self.colorTextAutor != nil ? self.colorTextAutor!  : self.settingModel.colorfrase)
                                    .modifier(mof_frases())
                                    .frame(maxWidth: .infinity, alignment: .center)

                                HStack{
                                    if self.showHideAutorInFrases {
                                        Text(frase.autor ?? "").font(.footnote).italic().padding(.horizontal)
                                    }
                                    
                                    Spacer()
                                    
                                    #if os(iOS)
                                    //Botón de Favorito de la frase
                                    Button{
                                        self.frase?.isfav.toggle()
                                        self.frasesModel.guardarCambios()
                                        animationHeart += 1

                                    }label: {
                                        Image(systemName: (self.frase?.isfav ?? false) ? "heart.fill" : "heart")
                                            .foregroundStyle(.black)
                                            .symbolEffect(.bounce, value: animationHeart)
                                    }
                                    .padding(10)
                                    .padding(.trailing, 15)
                                    #endif
                                    
                                    #if os(macOS)
                                    //navegación de frases: Mac
                                    HStack(spacing: 5){
                                        Image(systemName: self.contadorNavegarPorFrasesAnteriores == 0 ? "arrow.left.circle" : "arrow.left.circle.fill")
                                            .foregroundStyle(.black)
                                            .onTapGesture {
                                                if !self.frasesModel.fraseAnteriores.isEmpty && self.contadorNavegarPorFrasesAnteriores > 0 {
                                                    self.contadorNavegarPorFrasesAnteriores -= 1
                                                    self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                                    
                                                    self.isFav = self.isFav
                                                    self.frasesModel.fraseActual = self.frase
                                                }
                                            }
                                        Image(systemName: self.contadorNavegarPorFrasesAnteriores == self.frasesModel.fraseAnteriores.count-1 ? "arrow.right.circle" : "arrow.right.circle.fill")
                                            .foregroundStyle(.black)
                                            .onTapGesture {
                                                if self.contadorNavegarPorFrasesAnteriores < self.frasesModel.fraseAnteriores.count - 1 {
                                                    self.contadorNavegarPorFrasesAnteriores += 1
                                                    
                                                    self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                                    
                                                    self.isFav = self.frase?.isfav ?? false
                                                    self.frasesModel.fraseActual = self.frase
                                                }
                                            }
                                    }
                                    .padding(.horizontal, 15)
                                    
                                    //Favoritos: Mac
                                    Image(systemName: (self.frase?.isfav ?? false) ? "heart.fill" : "heart")
                                        .foregroundStyle(.black)
                                        .symbolEffect(.bounce, value: animationHeart)
                                        .padding(10)
                                        .padding(.trailing, 15)
                                        .onTapGesture {
                                            self.frase?.isfav.toggle()
                                            self.frasesModel.guardarCambios()
                                            animationHeart += 1
                                           
                                        }
                                    #endif
                                }
                                .padding(.top, 4)

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height)
                        }
                        .onTapGesture {
                            //Obtiene una nueva frase
                            self.frase = self.getRandomFraseByScope()
                            if self.frase != nil {
                                self.isFav = self.frase?.isfav ?? false
                                frasesModel.fraseActual = self.frase //Guardando la frase actualmente visible en la variable observable
                                
                                //Almacenando la frase en el vector de navegación de frases
                                if self.frasesModel.fraseAnteriores.count > 9 { //Si la capacidad del arreglo supera el límite de 10 frases
                                    
                                    self.frasesModel.fraseAnteriores.removeFirst() //Remueve la primera frase
                                    self.frasesModel.fraseAnteriores.append(self.frase!) //Coloca la frase actual
                                    self.contadorNavegarPorFrasesAnteriores = self.frasesModel.fraseAnteriores.count
                                }else{ //Si no se ha superado la capacidad del arreglo, simplemente agrega la frase actual al mismo
                                        self.frasesModel.fraseAnteriores.append(self.frase!) //Coloca la frase actual
                                        self.contadorNavegarPorFrasesAnteriores = self.frasesModel.fraseAnteriores.count
         
                                }
                            }
                            
                            
                        }
                    //Gesto de deslizar izquierda a derecha: navega hacia la frase anterior(hasta un máximo de 10 frases)
                        #if os(iOS)
                        .simultaneousGesture(
                            DragGesture().onEnded { value in
                                let start = value.startLocation
                                let end = value.location
                                let threshold: CGFloat = 40
                                
                                // Deslizar de izquierda a derecha → ir hacia atrás
                                if end.x > start.x + threshold {
                                    if !self.frasesModel.fraseAnteriores.isEmpty && self.contadorNavegarPorFrasesAnteriores > 0 {
                                        self.contadorNavegarPorFrasesAnteriores -= 1
                                        self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                        
                                        self.isFav = self.frase?.isfav ?? false
                                        self.frasesModel.fraseActual = self.frase
                                    }
                                }
                                // Deslizar de derecha a izquierda → ir hacia adelante
                                else if end.x < start.x - threshold {
                                    if self.contadorNavegarPorFrasesAnteriores < self.frasesModel.fraseAnteriores.count - 1 {
                                        self.contadorNavegarPorFrasesAnteriores += 1
                                        
                                        self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                        
                                        self.isFav = self.frase?.isfav ?? false
                                        self.frasesModel.fraseActual = self.frase
                                    }
                                }
                            }
                        )
                        #endif
                        .onOpenURL(perform: { url in
                            //Navega hasta la frase actualmente seleccionada:
                            if url.description == AppCons.DeepLink_url_Frase {
                                do{
                                    let textoFrase = UserDefaults.shared().string(forKey: AppCons.UD_shared_FraseWidgetActual) ?? ""
                                    if let frase = try Frases.getFraseByText(fraseTexto: textoFrase, context: CoreDataController.shared.context ){
                                        self.frase = frase
                                    }
                                }catch{
                                    msg("No se ha podido obtener la frase actual")
                                }
                                
                               
                            }
                            
                        })
                        .contextMenu{
                            
                            //Information about frases
                            Button{
                                self.alertMessage = """
                                    Autor: \(frase.getNameAutor)  
                                    
                                    Contextos: \n - \((frase.contextosArray.map{$0.nombre ?? ""}).joined(separator: "\n- "))
                                    """
                                self.showAlert = true
                                
                            }label:{
                                Label("Información", systemImage: "info.circle")
                            }
                            
                            Button{
                                //Guarda la nota poniendo como título una parte de la cadena
                                _ = NotasModel().addNote(nota: self.frase?.frase ?? "", title: "\(String(self.frase?.frase ?? "").prefix((self.frase?.frase ?? "").count / 3 )))...")
                            }label: {
                                Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
                            }
                            
                    
                            #if os(macOS)
                            Button{
                                showWindow(for: GenerateQRView(footer: self.frase?.frase ?? "", showImage: true),
                                           environmentObjects: [self.frasesModel],
                                           size: AppCons.windows_size_content,
                                           isModal: false) //Debe ser una ventana no modal, de lo contrario no funciona el compartir la imagen en macOS
                            }label:{
                                Label("Generar QR", systemImage: "qrcode")
                            }
                            #else
                            NavigationLink{
                                GenerateQRView(footer: self.frase?.frase ?? "", showImage: true)
                            }label:{
                                Label("Generar QR", systemImage: "qrcode")
                            }
                            
                            #endif
                            #if os(macOS)
                            Button{
                                showWindow(for: LienzoMain(texto: self.frase?.frase ?? "", imagenPrimariaACargar: LienzoModel.getImagenAutor(autor: self.frase?.autor ?? "nev" )),
                                           environmentObjects: [],
                                           title: "Lienzo",
                                           size: .absolute(CGSize(width: 650, height: 750)),
                                           isModal: false)
                                
                            }label: {
                                Label("Lienzo", systemImage: "heart.text.square")
                            }
                            
                            #else
                            NavigationLink{
                                LienzoMain(texto: self.frase?.frase ?? "",imagenPrimariaACargar: LienzoModel.getImagenAutor(autor: self.frase?.autor ?? ""))
                            }label: {
                                Label("Lienzo", systemImage: "heart.text.square")
                            }
                            #endif
                            
                            
                            #if os(macOS)
                            
                            Button{
                                showWindow(for: ReminderEditorView(reminderAEditar: nil, titleAImportar: nil, textoAImportar: self.frase?.frase ?? "", onSave: {}),
                                           environmentObjects: [],
                                           title: "Lienzo",
                                           size: .absolute(CGSize(width: 650, height: 750)),
                                           isModal: false)
                            }label:{
                                Label("Recordatorios", systemImage: "heart.text.square")
                            }
                            
                            #else
                            
                            NavigationLink{
                                ReminderEditorView(reminderAEditar: nil, titleAImportar: nil, textoAImportar: self.frase?.frase ?? "", onSave: {})
                            }label:{
                                Label("Recordatorios", systemImage: "heart.text.square")
                            }
                            
                            #endif
                            
                            
                            ShareLink(item: self.frase?.frase ?? "") {
                                            Label("Compartir frase", systemImage: "square.and.arrow.up")
                                        }
                            
                            Button{
                                #if os(macOS)
                                showWindow(for: FrasesNotasAddView(frase: self.frase!),
                                           environmentObjects: [self.frasesModel],
                                           title: "Nota de Frase",
                                           size: AppCons.windows_size_content_small,
                                           isModal: true)
                                #else
                                showAddNoteView = true
                                #endif
                            }label: {
                                Label("Nota de la frase", systemImage: "bookmark.fill" )
                            }
                            
                            //Funciones de Inteligencia: IA
                            if #available(iOS 26.0, macOS 26.0,  *)  {
                                
                                if IAModelAppleIntelligence.isAvailable(){
                                    Menu{
                                    #if os(macOS)
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: self.frase?.frase ?? "", tipoSalida: .interpretar, autorRespuesta: self.frase?.autor ?? "nev"),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: AppCons.windows_size_content,
                                                       isModal: true,
                                                       isIAWindows: true)
                                            
                                        }label: {
                                            Label("Interpretar", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: self.frase?.frase ?? "", tipoSalida: .practicaConcreta, autorRespuesta: self.frase?.autor ?? "nev"),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: AppCons.windows_size_content,
                                                       isModal: true,
                                                       isIAWindows: true)
                                           
                                        }label: {
                                            Label("Aplicación Práctica", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: ChatView(textoACargar: self.frase?.frase ?? ""),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                                                        size: AppCons.windows_size_content,
                                                       isModal: false,
                                                       isIAWindows: true)
                                            
                                        }label: {
                                            Label("Charlar con la IA", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        
                                    #else
                                        NavigationLink{
                                            RespondView(nameConference: "", texto: self.frase?.frase ?? "", tipoSalida: .interpretar, autorRespuesta: frase.autor ?? "nev")
                                        }label: {
                                            Label("Interpretar", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        NavigationLink{
                                            RespondView(nameConference: "", texto: self.frase?.frase ?? "", tipoSalida: .practicaConcreta, autorRespuesta: self.frase?.autor ?? "nev" )
                                        }label: {
                                            Label("Aplicación Práctica", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        NavigationLink{
                                            ChatView(textoACargar: self.frase?.frase ?? "")
                                        }label: {
                                            Label("Charlar con IA", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                    #endif
                                    }label:{
                                        Label("Funciones IA", systemImage: "sparkles")
                                    }
                                    
                                    
                                    
                                }

                            }
                            
                            Button{
                                #if os(macOS)
                                showWindow(
                                    for: FraseAddView(),
                                    environmentObjects: [self.frasesModel, self.settingModel],
                                    title: "Yorjandis",
                                    size: AppCons.windows_size_content_small,
                                    isModal: true)
                                #else
                                showSheetAddFrase = true
                                #endif
                                
                            }label: {
                                Label("Nueva frase", systemImage: "square.and.pencil.circle")
                            }
                        }
                    }

                }else{
                    EmptyView()
                }
                
                
                
            }
            .task{
                self.cargarFraseInicialSiEsNecesario()
            }
            .onChange(of: self.populandoFrases) { _, isPopulating in
                if !isPopulating {
                    self.cargarFraseInicialSiEsNecesario()
                }
            }
            
            .sheet(isPresented: $showAddNoteView){ //permite modificar la nota de una frase
                
                FrasesNotasAddView(frase: self.frase!, nota: self.frase?.nota ?? "")
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
                //.interactiveDismissDisabled() //No deja que se oculte
                
            }
            .sheet(isPresented: $showSheetAddFrase){
                FraseAddView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            .alert(isPresented: self.$showAlert){
                Alert(title: Text("La Ley"), message: Text(self.alertMessage))
            }


            
        
    }

    
    private func cargarFraseInicialSiEsNecesario() {
        guard (self.frase?.frase ?? "").isEmpty else { return }
        guard let fraseInicial = self.getRandomFraseByScope() else { return }

        self.frase = fraseInicial
        self.isFav = fraseInicial.isfav
        frasesModel.fraseActual = fraseInicial

        if let fraseID = fraseInicial.id,
           !self.frasesModel.fraseAnteriores.contains(where: { $0.id == fraseID }) {
            self.frasesModel.fraseAnteriores.append(fraseInicial)
            self.contadorNavegarPorFrasesAnteriores = max(self.frasesModel.fraseAnteriores.count - 1, 0)
        }
    }

    private func getRandomFraseByScope() -> Frases? {
        // Sin Premium, solo se permiten frases de Neville.
        guard (self.purchaseStatus || self.yorjPremium) else {
            return self.frasesModel.getListFrasesByAutor(autor: "nev").randomElement()
        }

        if let authorFilter, !authorFilter.isEmpty {
            return self.frasesModel.getListFrasesByAutor(autor: authorFilter).randomElement()
        }
        return self.frasesModel.getRandomFrase()
    }

}

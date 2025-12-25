//
//  FrasesHomeView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 6/11/25.
//

import SwiftUI//Frases View. Cuadro de frase en la pantalla inicial





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
        return frase
    }
    
    //Pruebas
    @State private var showListaRecordatorios : Bool = false
    
    var body: some View{

            VStack{
                
                #if os(macOS)
                Button("Crear Recordatorio"){
                    ReminderNotificationManager.shared.requestPermission()
                    ReminderNotificationManager.shared.scheduleAndStore(title: "Yorjandis", message: "Esto es un ejemplo", frequency: .interval(hours: 0, minutes: 1))
                }
                
                Button("Lista de Recordatorios"){
                    showWindow(for: ReminderListView(),
                    environmentObjects: [],
                    title: "Recordatorios",
                               size: .absolute(CGSize(width: 650, height: 700)),
                    isModal: false)
                }
                #endif
                
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
                    #if os(iOS)
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
                    #endif
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
                        
                        #if os(macOS)
                        Button{
                            showWindow(for: GenerateQRView(footer: self.frase, showImage: true),
                                       environmentObjects: [self.frasesModel],
                                       size: AppCons.windows_size_content,
                                       isModal: false) //Debe ser una ventana no modal, de lo contrario no funciona el compartir la imagen en macOS
                        }label:{
                            Label("Generar QR", systemImage: "qrcode")
                        }
                        #else
                        NavigationLink{
                            GenerateQRView(footer: self.frase, showImage: true)
                        }label:{
                            Label("Generar QR", systemImage: "qrcode")
                        }
                        
                        #endif
                        #if os(macOS)
                        Button{
                            showWindow(for: LienzoMain(texto: self.frase),
                                       environmentObjects: [],
                                       title: "Lienzo",
                                       size: .absolute(CGSize(width: 650, height: 750)),
                                       isModal: false)
                            
                        }label: {
                            Label("Lienzo", systemImage: "heart.text.square")
                        }
                        
                        #else
                        NavigationLink{
                            LienzoMain(texto: self.frase)
                        }label: {
                            Label("Lienzo", systemImage: "heart.text.square")
                        }
                        #endif
                        
                        
                        
                        ShareLink(item: self.frase) {
                                        Label("Compartir frase", systemImage: "square.and.arrow.up")
                                    }
                        
                        Button{
                            #if os(macOS)
                            showWindow(for: FrasesNotasAddView(frase: self.frase),
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
                                #if os(macOS)
                                Button{
                                    showWindow(for: RespondView(nameConference: "", texto: self.frase, tipoSalida: .interpretar),
                                               environmentObjects: [self.frasesModel, self.settingModel],
                                               size: AppCons.windows_size_content,
                                               isModal: true,
                                               isIAWindows: true)
                                    //RespondView(nameConference: "", texto: self.frase, tipoSalida: .interpretar)
                                }label: {
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                Button{
                                    showWindow(for: RespondView(nameConference: "", texto: self.frase, tipoSalida: .practicaConcreta),
                                               environmentObjects: [self.frasesModel, self.settingModel],
                                               size: AppCons.windows_size_content,
                                               isModal: true,
                                               isIAWindows: true)
                                    //RespondView(nameConference: "", texto: self.frase, tipoSalida: .practicaConcreta)
                                }label: {
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                Button{
                                    showWindow(for: ChatView(textoACargar: self.frase),
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
                                #endif
                                
                                
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
                
                HStack(){
                    Spacer()
                    
                    #if os(iOS)
                    //Botón de Favorito de la frase
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
                                    
                                    self.isFav = self.frasesModel.isFavFrase(self.frase)
                                    self.frasesModel.favStateOfCurrentFrase = self.isFav
                                    self.frasesModel.fraseActual = self.frase
                                }
                            }
                        Image(systemName: self.contadorNavegarPorFrasesAnteriores == self.frasesModel.fraseAnteriores.count-1 ? "arrow.right.circle" : "arrow.right.circle.fill")
                            .foregroundStyle(.black)
                            .onTapGesture {
                                if self.contadorNavegarPorFrasesAnteriores < self.frasesModel.fraseAnteriores.count - 1 {
                                    self.contadorNavegarPorFrasesAnteriores += 1
                                    
                                    self.frase = self.frasesModel.fraseAnteriores[self.contadorNavegarPorFrasesAnteriores]
                                    
                                    self.isFav = self.frasesModel.isFavFrase(self.frase)
                                    self.frasesModel.favStateOfCurrentFrase = self.isFav
                                    self.frasesModel.fraseActual = self.frase
                                }
                            }
                    }
                    .padding(.horizontal, 15)
                    
                    
                    //Favoritos: Mac
                    Image(systemName: frasesModel.favStateOfCurrentFrase ? "heart.fill" : "heart")
                        .foregroundStyle(.black)
                        .symbolEffect(.bounce, value: animationHeart)
                        .padding(10)
                        .padding(.trailing, 15)
                        .onTapGesture {
                            let getState = frasesModel.isFavFrase(self.frase) //Obtiene el estado previo
                            if frasesModel.setFavFrase(self.frase, !getState){
                                isFav = !getState
                                frasesModel.favStateOfCurrentFrase = isFav
                                animationHeart += 1
                            }
                        }
                    
                    #endif
                }
                
            }
            .onAppear{
                if self.frase.isEmpty{
                    self.frase = frasesModel.getRandomFrase()
                    //leyendo el estado isfav de la frase
                    isFav = frasesModel.isFavFrase(frase) //Obtiene el estado previo
                    frasesModel.favStateOfCurrentFrase = isFav //Actualiza el estado del favorito en la variable observable
                    frasesModel.fraseActual = self.frase //Almacenando la frase actualmente visible en Home
                    self.frasesModel.fraseAnteriores.append(self.frase) //Coloca la frase en el vector de navegación
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



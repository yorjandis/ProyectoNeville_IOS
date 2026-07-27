//
//  FrasesHomeView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 6/11/25.
//

//Frases View. Cuadro de frase en la pantalla inicial

import SwiftUI
import CoreData






struct FrasesHomeView : View{
    private enum FraseFiltro: Hashable {
        case favoritos
        case conNotas
    }

    @EnvironmentObject private var frasesModel : FrasesModel
    @EnvironmentObject private var settingModel : SettingModel
    
    @State private var  frase : Frases? = nil
   
    @AppStorage(AppCons.UD_setting_fontFrasesSize) var fontSizeFrases : Int = 24
    @AppStorage(AppCons.UD_setting_showHide_autor_in_frases) var showHideAutorInFrases : Bool = true // Muestra / oculta el aurtor en las frases del Home
    @AppStorage(AppCons.UD_ProgresoUI_PopulandoFrases) private var populandoFrases: Bool = false
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
        return frase?.localizedText ?? ""
    }
    
    //Mostrar Alerta
    @State private var showAlert : Bool = false
    @State private var alertMessage : String = ""
    
    //Pruebas
    @State private var showListaRecordatorios : Bool = false

    //Parámetros para las vistas de autores:
    var authorFilter: String? = nil //Filtro de frases de autores
    var colorTextAutor : Color? = nil //Color del texto del autor
    var showAutorLabel : Bool = true //Color del texto del autor
    var showFraseFilterControl: Bool = false //Control de filtros en la esquina superior derecha

    @State private var filtrosActivos: Set<FraseFiltro> = []
    
    var body: some View{
        
            VStack{
                if let frase = self.frase{
                    
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)

                                Text(frase.localizedText)
                                    .font(.system(size: CGFloat(fontSizeFrases), design: .rounded))
                                    .foregroundStyle( self.colorTextAutor != nil ? self.colorTextAutor!  : self.settingModel.colorfrase)
                                    .modifier(mof_frases())
                                    .frame(maxWidth: .infinity, alignment: .center)

                                HStack{
                                    //Opción para vista de autores
                                    if self.showAutorLabel{
                                        if self.showHideAutorInFrases {
                                            Text(frase.autor ?? "").font(.footnote).italic().padding(.horizontal)
                                        }
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
                        .overlay(alignment: .topTrailing) {
                            if self.showFraseFilterControl {
                                self.filterButton
                                    .padding(.top, 10)
                                    .padding(.trailing, 10)
                            }
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
                                    
                                    Contextos: \n - \((frase.contextosArray.map(\.localizedName)).joined(separator: "\n- "))
                                    """
                                self.showAlert = true
                                
                            }label:{
                                Label("Información", systemImage: "info.circle")
                            }
                            
                            Button{
                                //Guarda la nota poniendo como título una parte de la cadena
                                let text = self.frase?.localizedText ?? ""
                                _ = NotasModel().addNote(nota: text, title: "\(String(text.prefix(text.count / 3)))...")
                            }label: {
                                Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
                            }

                            Button {
                                self.addCurrentPhraseToCalmList()
                            } label: {
                                Label("Añadir a Espacio Calma", systemImage: "leaf")
                            }
                            
                    
                            #if os(macOS)
                            Button{
                                showWindow(for: GenerateQRView(footer: self.frase?.localizedText ?? "", showImage: true),
                                           environmentObjects: [self.frasesModel],
                                           size: AppCons.windows_size_content,
                                           isModal: false) //Debe ser una ventana no modal, de lo contrario no funciona el compartir la imagen en macOS
                            }label:{
                                Label("Generar QR", systemImage: "qrcode")
                            }
                            #else
                            NavigationLink{
                                GenerateQRView(footer: self.frase?.localizedText ?? "", showImage: true)
                            }label:{
                                Label("Generar QR", systemImage: "qrcode")
                            }
                            
                            #endif
                            #if os(macOS)
                            Button{
                                showWindow(for: LienzoMain(texto: self.frase?.localizedText ?? "", imagenPrimariaACargar: LienzoModel.getImagenAutor(autor: self.frase?.autor ?? "nev" )),
                                           environmentObjects: [],
                                           title: "Lienzo",
                                           size: .absolute(CGSize(width: 650, height: 750)),
                                           isModal: false)
                                
                            }label: {
                                Label("Lienzo", systemImage: "heart.text.square")
                            }
                            
                            #else
                            NavigationLink{
                                LienzoMain(texto: self.frase?.localizedText ?? "",imagenPrimariaACargar: LienzoModel.getImagenAutor(autor: self.frase?.autor ?? ""))
                            }label: {
                                Label("Lienzo", systemImage: "heart.text.square")
                            }
                            #endif
                            
                            
                            #if os(macOS)
                            
                            Button{
                                showWindow(for: ReminderEditorView(reminderAEditar: nil, titleAImportar: nil, textoAImportar: self.frase?.localizedText ?? "", onSave: {}),
                                           environmentObjects: [],
                                           title: "Lienzo",
                                           size: .absolute(CGSize(width: 650, height: 750)),
                                           isModal: false)
                            }label:{
                                Label("Recordatorios", systemImage: "heart.text.square")
                            }
                            
                            #else
                            
                            NavigationLink{
                                ReminderEditorView(reminderAEditar: nil, titleAImportar: nil, textoAImportar: self.frase?.localizedText ?? "", onSave: {})
                            }label:{
                                Label("Recordatorios", systemImage: "heart.text.square")
                            }
                            
                            #endif
                            
                            
                            ShareLink(item: self.frase?.localizedText ?? "") {
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
                                
                                if IAModelAppleIntelligence.hasAvailableContentProvider(){
                                    Menu{
                                    #if os(macOS)
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: self.frase?.localizedText ?? "", tipoSalida: .interpretar, autorRespuesta: self.frase?.autor ?? "nev"),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: AppCons.windows_size_content,
                                                       isModal: true,
                                                       isIAWindows: true)
                                            
                                        }label: {
                                            Label("Interpretar", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: RespondView(nameConference: "", texto: self.frase?.localizedText ?? "", tipoSalida: .practicaConcreta, autorRespuesta: self.frase?.autor ?? "nev"),
                                                       environmentObjects: [self.frasesModel, self.settingModel],
                                                       size: AppCons.windows_size_content,
                                                       isModal: true,
                                                       isIAWindows: true)
                                           
                                        }label: {
                                            Label("Aplicación Práctica", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        Button{
                                            showWindow(for: ChatView(textoACargar: self.frase?.localizedText ?? ""),
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
                                            RespondView(nameConference: "", texto: self.frase?.localizedText ?? "", tipoSalida: .interpretar, autorRespuesta: frase.autor ?? "nev")
                                        }label: {
                                            Label("Interpretar", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        NavigationLink{
                                            RespondView(nameConference: "", texto: self.frase?.localizedText ?? "", tipoSalida: .practicaConcreta, autorRespuesta: self.frase?.autor ?? "nev" )
                                        }label: {
                                            Label("Aplicación Práctica", systemImage: "sparkles")
                                        }
                                        .tint(.purple)
                                        
                                        NavigationLink{
                                            ChatView(textoACargar: self.frase?.localizedText ?? "")
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
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack {
                                Spacer(minLength: 0)
                                Text("No hay frases para los filtros seleccionados")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 14)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geometry.size.height)
                        }
                        .overlay(alignment: .topTrailing) {
                            if self.showFraseFilterControl {
                                self.filterButton
                                    .padding(.top, 10)
                                    .padding(.trailing, 10)
                            }
                        }
                        .onTapGesture {
                            self.recargarFrasePorFiltros()
                        }
                    }
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
            .onChange(of: self.filtrosActivos) { _, _ in
                self.recargarFrasePorFiltros()
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
        guard (self.frase?.localizedText ?? "").isEmpty else { return }
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
        let frasesFiltradas = self.getFrasesByScope().filter(self.cumpleFiltros)
        guard !frasesFiltradas.isEmpty else { return nil }

        return frasesFiltradas.randomElement()
    }

    private func getFrasesByScope() -> [Frases] {
        if let authorFilter, !authorFilter.isEmpty {
            return self.frasesModel.getListFrasesByAutor(autor: authorFilter)
        }
        return self.frasesModel.getAllFrasesGet()
    }

    private func cumpleFiltros(_ frase: Frases) -> Bool {
        if self.filtrosActivos.contains(.favoritos), !frase.isfav {
            return false
        }

        if self.filtrosActivos.contains(.conNotas),
           (frase.nota ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }

        return true
    }

    private func toggleFiltro(_ filtro: FraseFiltro) {
        if self.filtrosActivos.contains(filtro) {
            self.filtrosActivos.remove(filtro)
        } else {
            self.filtrosActivos.insert(filtro)
        }
    }

    private func limpiarFiltros() {
        self.filtrosActivos.removeAll()
    }

    private func recargarFrasePorFiltros() {
        self.frase = self.getRandomFraseByScope()
        self.isFav = self.frase?.isfav ?? false
        self.frasesModel.fraseActual = self.frase
    }

    private var filterButton: some View {
        Menu {
            Text("Filtrar por:")
            Button {
                self.limpiarFiltros()
            } label: {
                Label("Todos", systemImage: self.filtrosActivos.isEmpty ? "checkmark" : "play")
            }

            Button {
                self.toggleFiltro(.favoritos)
            } label: {
                Label("Favoritos", systemImage: self.filtrosActivos.contains(.favoritos) ? "checkmark" : "play")
            }

            Button {
                self.toggleFiltro(.conNotas)
            } label: {
                Label("Con Notas", systemImage: self.filtrosActivos.contains(.conNotas) ? "checkmark" : "play")
            }
        } label: {
            Circle()
                .fill(Color.black.opacity(0.05))
                .frame(width: 30, height: 30)
                .padding(3)
        }
        .buttonStyle(.plain)
        //.offset(y: -17)
    }

    private func addCurrentPhraseToCalmList() {
        guard let phrase = self.frase else { return }
        let text = phrase.localizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let context = CoreDataController.shared.context
        guard let model = context.persistentStoreCoordinator?.managedObjectModel,
              model.entitiesByName["CalmUserPhrase"] != nil,
              let entity = NSEntityDescription.entity(forEntityName: "CalmUserPhrase", in: context) else {
            self.alertMessage = "No se encontró la entidad de frases de Espacio Calma."
            self.showAlert = true
            return
        }

        let object = NSManagedObject(entity: entity, insertInto: context)
        object.setValue(UUID(), forKey: "id")
        object.setValue(text, forKey: "phrase")
        object.setValue(Date(), forKey: "createdAt")

        do {
            try context.save()
            self.alertMessage = "Frase agregada a Espacio Calma."
        } catch {
            context.rollback()
            self.alertMessage = "No se pudo guardar la frase en Espacio Calma."
        }
        self.showAlert = true
    }

}

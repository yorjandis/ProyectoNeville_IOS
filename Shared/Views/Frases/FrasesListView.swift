//
//  FrasesNotasListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 27/10/23.
//
//Muesta y maneja el listado de frases en una ventana dedicada

import SwiftUI
import CoreData



struct FrasesListView: View {
    
    enum AutorFrase : String{
        case nev, jd, gregg, bruceL
    }
    
    @Environment(\.colorScheme) private var theme
    @StateObject private var frasesModel: FrasesModel = FrasesModel.shared //El modelo ya viene con la precarga de todas las frases en su inicializador init(){}
    @EnvironmentObject private var settingModel: SettingModel
    @Environment(\.managedObjectContext) private var context
    
    var mostrarFrasesDe : AutorFrase? = nil //Permite filtrar la lista de frases por un autor determinado
    
    @AppStorage(AppCons.UD_setting_fontFrasesSize)     var fontSizeFrases      : Int = 24
    
    @State private var showAddFrase = false
    @State private var subtitle = "Todas las Frases"
    
    //Buscar en la lista actual
    @State private var showAlertSearchInFrase = false
    @State private var textFieldFrase = ""
    @FocusState private var focused: Bool
    
    
    //Buscar en todas las frases
    @State private var showAlertSearchInFraseAll = false
    @State private var textFieldFraseAll = ""
    
    //Buscar en notas de frase
    @State private var showAlertSearchInNotaFrase = false
    @State private var textFieldNota = ""
    
    //Eliminar una frase
    @State private var showConfirmDialogDeleteFrase : Bool = false
    @State private var TextoFraseAEliminar : Frases?
    
    
    //Alert
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    //Mostrar la vista de frases relacionadas
    @State private var showTabViewFrasesRelac: Bool = false
    @State private var ModoListado: Bool = false
    @State private var fraseRelacionadaMain: Frases?
    
    
    
    @AppStorage(AppCons.UD_PopulandoFrases, store: UserDefaults(suiteName: "group.com.ypg.nev.group")) private var PopulandoFrases: Bool = false
    

    var body: some View {
        NavigationStack{
            VStack {
                
                //Si esta trabajando en popular las frases, entonces se muestra una barra de progreso
                if self.PopulandoFrases {
                    
                    ProgressView()
                    
                }else{
                    //Muestra un panel superior de Frases Relacionadas
                    if self.showTabViewFrasesRelac {
                        
                        if self.fraseRelacionadaMain != nil{
                            FraseRelacionadasTabView(frase: self.fraseRelacionadaMain!, showTabViewFrasesRelac: self.$showTabViewFrasesRelac, ModoListado: self.$ModoListado)
                        }
                        
                     }

                    //Si el modo Listado de frases Relacionadas esta activo:
                    if self.ModoListado {
                        
                        if self.fraseRelacionadaMain != nil {
                            ScrollView{
                                
                                FrasesRelacionasListView(fraseMain: self.fraseRelacionadaMain!)
                            }
                            
                        }
                        
                        
                    }else{
                        
                        //-----Listado de frases:
                        
                        //Búsqueda:
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Buscar", text: self.$textFieldFrase)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 20))
                                .padding(8)
                                .focused(self.$focused)
                                .onSubmit {
                                    Task{
                                        msg(frasesModel.buscarEn)
                                        frasesModel.criterioFiltroActual = .Buscar
                                        await frasesModel.FiltrarListado(textAbuscar: self.textFieldFrase)
                                    }
                                    
                                }
                                
                        }
                        .padding(.horizontal)
                        #if os(macOS)
                        .background(.windowBackground)
                        #endif
                        
                        VStack{}
                            .frame(height: 0)
                            .onAppear {
                                if let filtrarPorAutor = self.mostrarFrasesDe{
                                    frasesModel.listfrases.removeAll()
                                    switch filtrarPorAutor{
                                    case .nev :
                                        frasesModel.listfrases = frasesModel.getListFrasesByAutor(autor: AutorFrase.nev.rawValue )
                                    case .jd:
                                        frasesModel.listfrases = frasesModel.getListFrasesByAutor(autor: AutorFrase.jd.rawValue)
                                    default:
                                        msg("No se ha seleccionado un autor")
                                    
                                    }
                                }
                            }
                        
                        
                        List(frasesModel.listfrases, id: \.self){ frase in
                            VStack(alignment: .leading){
                                #if os(macOS)
                                //Vista de listado de Frases desde macOS, con un Menu al principio de cada frase
                                HStack{
                                    RowFraseMenu(frase: frase , frasesModel: self.frasesModel, settingModel: self.settingModel,showTabViewFrasesRelac: self.$showTabViewFrasesRelac, fraseRelacionadaMain: self.$fraseRelacionadaMain )
                                    
                                    
                                    //Mostrar Un icono de favorito si la frase es favorita
                                    if self.frasesModel.isFavFrase(fraseID: frase.id ?? "") {
                                        Image(systemName: "heart.fill")
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 5)
                                    }
                                    VStack(alignment: .leading ,spacing: 2){
                                        Text(frase.frase ?? "")
                                            .font(.system(size: 22))
                                            .fontDesign(.serif)
                                            .foregroundStyle(.black).bold()
                                            .textSelection(.enabled)
                                            .padding(.vertical, 15)
                                        HStack{
                                            Text(frase.autor ?? "").font(.footnote).italic()
                                            Spacer()
                                            if !frase.relacionadasArray.isEmpty{
                                                Button{
                                                    self.fraseRelacionadaMain = frase
                                                    self.showTabViewFrasesRelac = true
                                                }label:{
                                                    Image(systemName: "personalhotspot")
                                                        .font(.footnote)
                                                }
                                            }
                                            
                                        }
                                    }
                                    
                                    
                                    Spacer()

                                }

                                #else
                                VStack( alignment: .leading , spacing: 2){
                                    
                                    Text(frase.frase ?? "")
                                        .font(.system(size: 20))
                                        .textSelection(.enabled)
                                    HStack{
                                        Text(frase.autor ?? "").font(.footnote).italic()
                                        Spacer()
                                        
                                        if !frase.relacionadasArray.isEmpty{
                                             Button{
                                                 self.fraseRelacionadaMain = frase
                                                 self.showTabViewFrasesRelac = true
                                             }label:{
                                                 Image(systemName: "personalhotspot")
                                                     .font(.footnote)
                                             }
                                         }
                                         
                                        
                                        
                                    }
                                    
                                    
                                }
                                
                                
                                //SelectableText(frase) //No funciona, no se ve el texto de la frase. Puede ser porque esta embebido en una List
                                #endif
                                
                            }
                            #if os(iOS) || os(ipadOS)
                            //Modificar el campo nota de una frase
                            .swipeActions(edge: .leading, allowsFullSwipe: true){
                                //Esta View no se mostrará si Apple Intelligence no esta disponible
                                if #available(iOS 26.0, macOS 26.0,  *) {
                                    if IAModelAppleIntelligence.isAvailable() {
                                        Menu{
                                            NavigationLink{
                                                RespondView(nameConference: "", texto: frase.frase ?? "", tipoSalida: .interpretar )
                                            }label:{
                                                Label("Interpretar", systemImage: "sparkles")
                                            }
                                            .tint(.orange)
                                            
                                            NavigationLink{
                                                RespondView(nameConference: "", texto: frase.frase ?? "", tipoSalida: .practicaConcreta)
                                            }label:{
                                                Label("Aplicación Práctica", systemImage: "sparkles")
                                            }
                                            .tint(.orange)
                                            
                                            NavigationLink{
                                                ChatView(textoACargar: frase.frase ?? "")
                                            }label: {
                                                Label("Charlar con IA", systemImage: "sparkles")
                                            }
                                            .tint(.orange)
                                            
                                        }label:{
                                            Image(systemName: "sparkles")
                                        }
                                        .tint(.purple)
                                    }
                                }
                                //Notas de la Frase
                                NavigationLink{
                                     FrasesNotasAddView( frase: frase)
                                }label: {
                                    Image(systemName: "bookmark")
                                        .tint(.green)
                                }
                                
                                //Guardar la frase a Notas
                                Button{
                                    
                                     //Guarda la nota poniendo como titulo una parte de la cadena
                                    if  NotasModel().addNote(nota: frase.frase ?? "", title: "\(String(frase.frase ?? "").prefix((frase.frase ?? "").count / 3 )))..."){
                                         self.alertMessage = "Frase almacenada en Notas"
                                         self.showAlert = true
                                     }
                                     
                                    
                                }label: {
                                    Label("Almacenar en Notas", systemImage: "list.bullet.clipboard")
                                }
                                
                                //Compartir la frase:
                                ShareLink(item: frase.frase ?? "") {
                                                Label("Compartir frase", systemImage: "square.and.arrow.up")
                                            }
                                
                                //Si la Frase es personal, permite eliminarla
                                if frasesModel.isNoInbuilt(fraseID: frase.id ?? "") ?? false{
                                    Button{
                                        self.TextoFraseAEliminar = frase
                                        self.showConfirmDialogDeleteFrase = true
                                    }label:{
                                        Image(systemName: "minus.circle.fill")
                                            .tint(.red.opacity(0.8))
                                    }
                                }
                               
                                
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true){
                                
                                //Menú de opciones para frases Relacionadas:
                                 Menu{
                                     
                                      if (self.showTabViewFrasesRelac && self.fraseRelacionadaMain != nil) {
                                          Button{
                                              frase.vincularCon(self.fraseRelacionadaMain!)
                                              //Persistiendo
                                              guardarCambios()
                                          }label:{
                                              Label("Agregar Frase", systemImage: "tray.and.arrow.up.fill")
                                                  .tint(.purple)
                                          }
                                      }

                                      //Modo edición de frases relacionadas
                                      Button{
                                          self.fraseRelacionadaMain = frase
                                          self.showTabViewFrasesRelac = true
                                      }label:{
                                      Label("Modo Edición", systemImage: "graduationcap.circle")
                                          .tint(.blue)
                                      }
                                      
                                     
                                     
                                     //Mostrar/Ocultar el ponel de frases relacionadas
                                     if frase.relacionadasArray.count > 0 {
                                         NavigationLink{
                                             FrasesMainListRelacionadas(fraseMain: frase)
                                         }label:{
                                             Label("Modo Lista", systemImage: "append.page")
                                                 .tint(.blue)
                                         }
                                     }
                                      

                                 }label:{
                                     Image(systemName: "graduationcap.circle")
                                         .tint(.blue)
                                 }
                                 

                                //Editar la frase: Solo si es Personal
                                if let fraseCoreData = self.frasesModel.getFraseCoreData(FraseID: frase.id ?? ""){
                                    if fraseCoreData.noinbuilt == true{
                                        NavigationLink{
                                            FrasesUpdateView(frase: fraseCoreData)
                                        }label:{
                                            Image(systemName: "square.and.pencil")
                                                .tint(.green)
                                        }
                                    }
                                }
                                
                                //Generando el QR de la frase
                                NavigationLink{
                                    GenerateQRView(footer: frase.frase ?? "")
                                }label: {
                                    Image(systemName: "qrcode")
                                        .tint(.brown)
                                }
                                
                                //Lienzo
                                NavigationLink{
                                    LienzoMain(texto: frase.frase ?? "")
                                }label: {
                                    Image(systemName: "heart.text.square")
                                        .tint(.brown)
                                }
                                
                                //Ajustar el estado de favorito de una frase
                                Button{
                                    
                                     let current = self.frasesModel.isFavFrase(fraseID: frase.id ?? "")
                                     let newValue = !current
                                     if self.frasesModel.setFavFrase(fraseID: frase.id ?? "", newValue) {
                                         Task {
                                             await self.frasesModel.FiltrarListado()
                                         }
                                         
                                     }
                                     
                                    
                                }label: {
                                    Image(systemName: "heart")
                                        .tint( self.frasesModel.isFavFrase(fraseID: frase.id ?? "") ? .orange : .gray)
                                }
                                
                                
                                
                            }
                            #endif
                        }
                        .scrollContentBackground(.hidden)
                        
                        
                        //Actualiza la información de la cantidad de elementos en la barra de estado inferior
                        HStack{
                            Text("Frases: \(self.frasesModel.listfrases.count)")
                            Spacer()
                        }.padding(.horizontal)
                        
                        .navigationTitle("Listado de Frases")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                         .toolbar{
                             
                             if #available(iOS 26.0, macOS 26.0,  *) {
                                 ToolbarSpacer(.fixed)
                             }
                             
                             //Aplica varios filtros al listado de Frases
                             ToolbarItem {
                                 Menu{
                                     
                                     CreateMenuItemButton(text: "Todas las Frases", sysImageStr: "text.magnifyingglass") {
                                         Task {
                                             frasesModel.criterioFiltroActual = .ListadoFull
                                             frasesModel.buscarEn = .TodasFrases
                                             await frasesModel.FiltrarListado()
                                         }
                                         
                                     }
                                     
                                     
                                     
                                     CreateMenuItemButton(text: "Frases Personales", sysImageStr: "text.magnifyingglass") {
                                         Task {
                                             frasesModel.criterioFiltroActual = .FrasesPersonales
                                             frasesModel.buscarEn = .FrasesPersonales
                                            await frasesModel.FiltrarListado()
                                         }
                                     }
                                    
                                     CreateMenuItemButton(text: "Frases Favoritas", sysImageStr: "text.magnifyingglass") {
                                         Task {
                                             frasesModel.criterioFiltroActual = .FrasesFavoritas
                                             frasesModel.buscarEn = .FrasesFavoritas
                                             await frasesModel.FiltrarListado()
                                         }
                                     }
                                     
                                     CreateMenuItemButton(text: "Frases con notas", sysImageStr: "text.magnifyingglass") {
                                         Task {
                                             frasesModel.criterioFiltroActual = .FrasesConNotas
                                             frasesModel.buscarEn = .FrasesConNotas
                                           await  frasesModel.FiltrarListado()
                                         }
                                     }

                                     CreateMenuItemButton(text: "Buscar en nota de frase", sysImageStr: "text.magnifyingglass") {
                                         subtitle = "Búsqueda en nota de Frase"
                                         showAlertSearchInNotaFrase = true
                                     }
                                     
                                     //Crea un Menú para filtrar por todos los Autores Disponibles
                                     Menu{
                                         let autores = self.frasesModel.getAllAutoresList().sorted()
                                         ForEach (autores, id: \.self) { autor in
                                             Button(autor){
                                                 self.frasesModel.listfrases = self.frasesModel.getListFrasesByAutor(autor: autor)
                                             }
                                         }
                                     }label: {
                                         Label("Por Autor", systemImage: "text.quote")
                                     }
                                     
                                 }label: { //Label del Menú
                                     Image(systemName: "line.3.horizontal.decrease")
                                         .foregroundStyle(.primary)
                                 }
                             }
                             
                             if #available(iOS 26.0, macOS 26.0,  *) {
                                 ToolbarSpacer(.fixed)
                             }
                             ToolbarItem{
                                 //Boton Adicionar una frase
                                 Button{
                                     #if os(macOS)
                                     showWindow(for: FraseAddView(),
                                                environmentObjects: [self.frasesModel],
                                                title: "Adicionar Frase",
                                                size: AppCons.windows_size_content_small,
                                                isModal: false) {
                                         //Si el listado actual es frases personales se actualiza al cerrar la ventana:
                                             Task{ @MainActor in
                                                 
                                                     await self.frasesModel.FiltrarListado() //Actualizando...
                                             
                                         }
                                     }
                                     #else
                                     showAddFrase = true
                                     #endif
                                     
                                 }label: {
                                     Image(systemName: "plus")
                                         .foregroundStyle(theme ==  .dark ? .white :  .black)
                                 }
                             }

                             
                         }
                        
                    }
                }
            }
            #if os(macOS)
            .background{
                LinearGradient(colors: [ .blue.opacity(0.6),.blue.opacity(0.7), .blue.opacity(0.5) ], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            #endif
             .sheet(isPresented: $showAddFrase){
                 FraseAddView()
                 .presentationDetents([.medium])
                 .presentationDragIndicator(.hidden)
             }
             .alert("Buscar en nota de Frase", isPresented: $showAlertSearchInNotaFrase){
                 TextField("", text: $textFieldNota)
                 Button("Buscar"){
                     if !self.textFieldNota.isEmpty{
                         self.frasesModel.buscarEn = .ResultadosDeBusquedaEnNotas
                         Task{
                             self.frasesModel.criterioFiltroActual = .BuscarEnNotas
                             self.frasesModel.buscarEn = .ResultadosDeBusquedaEnNotas
                             await frasesModel.FiltrarListado(textAbuscar: self.textFieldNota)
                         }
                     }
                     
                 }
                 
             }
             //Dialogo de conformación para elimnar una nota
             .confirmationDialog(
                 "Confirme que desea Eliminar la Frase",
                 isPresented: $showConfirmDialogDeleteFrase
             ) {
                 Button("Eliminar", role: .destructive) {
                     eliminarFrase()
                 }
             } message: {
                 Text("La frase será removida!!!")
             }
             .alert(isPresented: self.$showAlert){
                 Alert(title: Text("La Ley"), message: Text(self.alertMessage))
             }
             
            
            
        }
    }
    
    
    private func eliminarFrase() {
        if let frase = self.TextoFraseAEliminar{
            withAnimation {
                if frasesModel.DeleteFraseInbuilt(fraseID: frase.id ?? "") {
                    Task {
                        frasesModel.criterioFiltroActual = .FrasesPersonales
                        await frasesModel.FiltrarListado()
                    }
                }
            }
        }
        
    }
    
    //Persistir cambios en las relaciones entre frases
    func guardarCambios() {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            msg("Error guardando relaciones:", error.localizedDescription)
        }
    }
}








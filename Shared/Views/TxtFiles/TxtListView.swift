//
//  TxtConfelistadoView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 9/11/23.
//
//lista los elementos TXT de contenido que tienen prefijos: conf_, cita_, preg: y ayud_

import Foundation
import SwiftUI
import CoreData

struct TxtListView: View {
    
    @Environment(\.colorScheme) var theme
    @Environment(\.managedObjectContext) var context
    @StateObject private var settingModel : SettingModel = SettingModel()
    @StateObject private var modeloTxt : TxtContentModel = TxtContentModel.shared
    
    @EnvironmentObject private var clipBoardModel : ClipboardObserver
    
    
    let typeOfContent : TipoDeContenido //Tipo de contenido a cargar
    
    @State var title : String //Es el título
    
    @AppStorage(AppCons.UD_setting_fontListaSize)  var fontSizeLista : Int = 20
    
    
    //Para Agregar notas
    @State var showAlertAddNote = false
    @State var textFiel = ""
    
    //Para buscar en texto:
    @State var showAlertSearchInTxt = false
    @State var textFiel2 = ""
    
    //Para buscar en notas:
    @State var showAlertSearchInNotas = false
    @State var textFiel3 = ""
    
    
    //Buscar en la lista actual
    @State private var showAlertSearchInTitles = false
    @State private var textFieldTxtTitles = ""
    @State private var listadoTemporal : [String] =  []
    @FocusState private var focused: Bool
    
    //Mostrar/Ocultar las últimas conferencias Vistas
    @AppStorage("ultimasConferenciasVistas") var lastConferencesViewer : Bool = false
    
    //Configuración de columnas
    let columnas: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    
    var body: some View {
        
        NavigationStack{
            VStack{
                //Búsqueda:
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Buscar", text: self.$textFieldTxtTitles)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 20))
                        .padding(10)
                        .focused(self.$focused)
                        .onChange(of: self.focused) { oldValue, newValue in
                            //Me aseguro de hacer una copia del listado original una sola vez
                            //Mientras se usa el cuadro de búsqueda
                            if self.textFieldTxtTitles.isEmpty{
                                if newValue{
                                    self.listadoTemporal = modeloTxt.getArrayOfAllFileTxtOfType(type: self.typeOfContent)
                                }
                            }
                        }
                        .onChange(of: self.textFieldTxtTitles, { oldValue, newValue in
                            if newValue.isEmpty{
                                modeloTxt.textList = self.listadoTemporal //restaura el listado actual
                            }else{ //Ejecuta el filtro
                                let filtro = self.listadoTemporal.filter{$0.lowercased().contains(newValue.lowercased()) }
                                modeloTxt.textList = filtro //Actualiza el listado con el filtro
                            }
                        })
                }
                .padding(.horizontal)
#if os(macOS)
                .background(.windowBackground)
#endif
                
      //En macOS: el listado se divide en dos columnas
#if os(macOS)
                //Listado de las últimas 5 conferencias Vistas
                if (self.typeOfContent == .conf && self.lastConferencesViewer) {
                    VStack{
                        
                        VStack(spacing: 0){
                            Group{
                                ScrollView {
                                    LazyVGrid(columns: columnas, alignment: .leading, spacing: 12) {
                                        ForEach(self.modeloTxt.lastFiveConferences, id: \.self) { nombreTxt in
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Image(systemName: "leaf.fill")
                                                        .padding(.horizontal, 5)
                                                        .foregroundStyle(
                                                            .linearGradient(
                                                                colors: [
                                                                    (modeloTxt.getIsFavOfTxt(
                                                                        nombreTxt: nombreTxt,
                                                                        type: self.typeOfContent
                                                                    )) ? .orange : .black,
                                                                    (modeloTxt.isNotaOfTxt(
                                                                        nombreTxt: nombreTxt,
                                                                        type: typeOfContent
                                                                    )) ? .green : .black
                                                                ],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                    
                                                    Button {
                                                        // Manejar el vector de conferencias vistas
                                                        self.modeloTxt.handleLastFiveConferences(nombreTxt: nombreTxt)
                                                        
                                                        showWindow(
                                                            for: ContentTxtShowView(
                                                                title: self.title,
                                                                nombreTxt: nombreTxt,
                                                                type: self.typeOfContent
                                                            ),
                                                            environmentObjects: [
                                                                self.modeloTxt,
                                                                self.settingModel,
                                                                self.clipBoardModel
                                                            ],
                                                            title: "\(self.title) - \(nombreTxt)",
                                                            size: AppCons.windows_size_content,
                                                            isModal: false,
                                                            onClose: {
                                                                Task { @MainActor in
                                                                    self.modeloTxt.saveLastFiveConferences()
                                                                }
                                                            }
                                                        )
                                                    } label: {
                                                        Text(nombreTxt)
                                                            .font(.system(size: CGFloat(self.fontSizeLista)))
                                                            .fontDesign(.serif)
                                                            .bold()
                                                            .foregroundStyle(.black)
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            Divider()
                                .frame(width: 450, height: 2, alignment: .leading)
                                .foregroundStyle(.black)
                        }
                        .frame(height: 150)
                        
                    }
                }
                
                
                ScrollView {
                    
                    LazyVGrid(columns: columnas, alignment: .leading, spacing: 12) {
                        ForEach(modeloTxt.textList, id: \.self) { nombreTxt in
                            
                            HStack(alignment: .center) {
                                Image(systemName: "leaf.fill")
                                    .padding(.horizontal, 5)
                                    .foregroundStyle(.linearGradient(
                                        colors: [
                                            modeloTxt.getIsFavOfTxt(
                                                nombreTxt: nombreTxt,
                                                type: self.typeOfContent
                                            ) ? .orange : .black,
                                            modeloTxt.isNotaOfTxt(
                                                nombreTxt: nombreTxt,
                                                type: typeOfContent
                                            ) ? .green : .black
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                
                                Button {
                                    //Manejar el vector de conferencias Vistas
                                    self.modeloTxt.handleLastFiveConferences(nombreTxt: nombreTxt)
                                    
                                    showWindow(
                                        for: ContentTxtShowView(
                                            title: self.title,
                                            nombreTxt: nombreTxt,
                                            type: self.typeOfContent
                                        ),
                                        environmentObjects: [self.modeloTxt, self.settingModel, self.clipBoardModel],
                                        title: "\(self.title) - \(nombreTxt)",
                                        size: AppCons.windows_size_content,
                                        isModal: false,onClose: {
                                            //Salvando el vector de configuración
                                            Task{ @MainActor in
                                                self.modeloTxt.saveLastFiveConferences()
                                            }  
                                        }
                                    )
                                } label: {
                                    Text(nombreTxt)
                                        .font(.system(size: CGFloat(self.fontSizeLista)))
                                        .fontDesign(.serif)
                                        .bold()
                                        .foregroundStyle(.black)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                }
                
#else
                
                // iOS / iPadOS conservan tu List original
                VStack{
                    //Listado de las últimas 5 conferencias Vistas
                    if ( self.typeOfContent == .conf && self.lastConferencesViewer){
                            VStack(spacing: 0){
                                Group{
                                    Text("Últimas lecturas visitadas:").font(.headline)
                                        List(self.modeloTxt.lastFiveConferences, id: \.self){ nombreTxt in
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Image(systemName: "leaf.fill")
                                                        .padding(.horizontal, 5)
                                                        .foregroundStyle(.linearGradient(colors: [
                                                            (modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent)) ? .orange : .black,
                                                            (modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: typeOfContent)) ? .green : .black
                                                        ], startPoint: .leading, endPoint: .trailing))
                                                    
                                                    NavigationLink {
                                                        ContentTxtShowView(title: self.title, nombreTxt: nombreTxt, type: self.typeOfContent)
                                                            .environmentObject(self.modeloTxt)
                                                            .environmentObject(self.settingModel)
                                                            .environmentObject(self.clipBoardModel)
                                                    } label: {
                                                        Text(nombreTxt)
                                                            .font(.system(size: CGFloat(self.fontSizeLista)))
                                                    }
                                                }
                                                
                                            }
                                            .swipeActions(edge: .leading) {
                                                Button {
                                                    var temp = modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: typeOfContent)
                                                    temp.toggle()
                                                    if TxtContentModel.shared.setIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent, isFav: temp) {
                                                        self.modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                                                    }
                                                } label: {
                                                    Image(systemName: "heart")
                                                        .tint(Color.orange)
                                                }
                                                
                                                NavigationLink {
                                                    EditNoteTxt(nameTxt: nombreTxt, typeOfContent: self.typeOfContent)
                                                } label: {
                                                    Image(systemName: "bookmark")
                                                        .tint(Color.green)
                                                }
                                            }
                                           
                                        }
                                        .frame(height: CGFloat(self.modeloTxt.lastFiveConferences.count) * 73)
                                }
                                
                            }
                        }
                    
                    //Listado de Conferencias
                    List(modeloTxt.textList, id: \.self) { nombreTxt in
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .padding(.horizontal, 5)
                                    .foregroundStyle(.linearGradient(colors: [
                                        (modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent)) ? .orange : .black,
                                        (modeloTxt.isNotaOfTxt(nombreTxt: nombreTxt, type: typeOfContent)) ? .green : .black
                                    ], startPoint: .leading, endPoint: .trailing))
                                
                                NavigationLink{
                                    ContentTxtShowView(title: self.title, nombreTxt: nombreTxt, type: self.typeOfContent)
                                        .environmentObject(self.modeloTxt)
                                        .environmentObject(self.settingModel)
                                        .environmentObject(self.clipBoardModel)
                                        .onAppear{
                                            //"Se ha abierto una conferencia")
                                                self.modeloTxt.handleLastFiveConferences(nombreTxt: nombreTxt)
                                            
                                        }
                                        .onDisappear{
                                                self.modeloTxt.saveLastFiveConferences()//Salva la conferencia
                                            
                                        }
                                } label: {
                                    Text(nombreTxt)
                                        .font(.system(size: CGFloat(self.fontSizeLista)))
                                }
                                
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                var temp = modeloTxt.getIsFavOfTxt(nombreTxt: nombreTxt, type: typeOfContent)
                                temp.toggle()
                                if TxtContentModel.shared.setIsFavOfTxt(nombreTxt: nombreTxt, type: self.typeOfContent, isFav: temp) {
                                    self.modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                                }
                            } label: {
                                Image(systemName: "heart")
                                    .tint(Color.orange)
                            }
                            
                            NavigationLink {
                                EditNoteTxt(nameTxt: nombreTxt, typeOfContent: self.typeOfContent)
                            } label: {
                                Image(systemName: "bookmark")
                                    .tint(Color.green)
                            }
                        }
                    }
                    
                }
                
                
#endif
            }
            .navigationTitle(self.title)
            .background{
                LinearGradient(colors: [ .gray.opacity(0.4),.blue.opacity(0.2) ], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar{
                if self.typeOfContent == .conf{
                    ToolbarItem{
                        Button{
                            if (!self.modeloTxt.lastFiveConferences.isEmpty){
                                withAnimation {
                                    self.lastConferencesViewer.toggle()
                                }
                               
                            }
                        }label:{
                            Image(systemName: "mount.fill")
                        }
                        .help("Ver las últimas conferencias")
                    }
                    
                    
                    if #available(iOS 26.0, macOS 26.0, *){
                        ToolbarSpacer(.fixed)
                    }
                }
                
                
                ToolbarItem{
                    Menu{
                        
                        CreateMenuItemButton(text: "Todas las \(self.title)", sysImageStr: "text.magnifyingglass") {
                            withAnimation {
                                modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
                            }
                        }
                        
                        CreateMenuItemButton(text: "\(self.title) favoritas", sysImageStr: "text.magnifyingglass") {
                            withAnimation {
                                modeloTxt.textList = modeloTxt.getArrayFavTxt(type: self.typeOfContent)
                            }
                        }
                        
                        CreateMenuItemButton(text: "\(self.title) con notas", sysImageStr: "text.magnifyingglass") {
                            withAnimation {
                                modeloTxt.textList = modeloTxt.getArrayNoteTxt(type: self.typeOfContent)
                            }
                        }
                        
                        CreateMenuItemButton(text: "Buscar en el contenido", sysImageStr: "text.magnifyingglass") {
                            showAlertSearchInTxt = true
                        }
                        
                        CreateMenuItemButton(text: "Buscar en las notas", sysImageStr: "text.magnifyingglass") {
                            showAlertSearchInNotas = true
                        }
                        
                    }label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(theme ==  .dark ? .white :  .black)
                    }
                }
                
                
            }
            .task{
                modeloTxt.getAllFileTxtOfType(type: self.typeOfContent)
            }
            .alert("Buscar en contenido", isPresented: $showAlertSearchInTxt){
                TextField("", text: $textFiel2, axis: .vertical)
                Button("Cancelar"){showAlertSearchInTxt = false}
                    .multilineTextAlignment(.leading)
                Button("Buscar"){
                    modeloTxt.textList = modeloTxt.searchInTxt(str: self.textFiel2, type: self.typeOfContent)
                }
                
            }
            .alert("Buscar en las notas", isPresented: $showAlertSearchInNotas){
                TextField("", text: $textFiel3, axis: .vertical)
                Button("Cancelar"){showAlertSearchInNotas = false}
                    .multilineTextAlignment(.leading)
                Button("Buscar"){
                    modeloTxt.textList = modeloTxt.searchInNotesTxt(str: self.textFiel3, type: self.typeOfContent)
                }
                
            }
            
        }
        
    }
    
    
    
    
    
}





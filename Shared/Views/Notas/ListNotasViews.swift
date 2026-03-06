//
//  ListNotasViews.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 3/10/23.
//
//Lista todas las notas creadas y permite modificarlas y eliminarlas
// Y buscar dentro de ellas

import SwiftUI
import CoreData
import LocalAuthentication


struct ListNotasViews: View {
    @Environment(\.dismiss) var dimiss
    
    @StateObject private var modelNotas = NotasModel()
    
    @State private var showAddNoteView = false
    //@State private var list : [Notas]  = []
    //Buscar en notas
    @State var showAlertSearch = false
    @State var textField = ""
    //Buscar en titulos de notas
    @State var showAlertSearchTitle = false
    @State var textFieldTitle = ""
    //Autenticacion FaceID
   private  let contextLA = LAContext()
    @State var canOpenNotas = false
    @State var showAlert = false
    @State var alertMessage = ""
    
    
    
    private var filtered : [Notas] {
        if self.textFieldTitle.isEmpty {return self.modelNotas.notas}
        return self.modelNotas.notas.filter{$0.title?.localizedCaseInsensitiveContains(self.textFieldTitle) ?? false}
    }
 
    var body: some View {
        NavigationStack {
            ZStack{
                
                LinearGradient.JadeProfundo()
                    .ignoresSafeArea()
                
                VStack{
                    if ( canOpenNotas == true  ||   UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false) {
                        ScrollView(.vertical){
                            
                            ForEach (self.filtered.reversed()){ nota in
                                cardNotas(nota: nota)
                                    .environmentObject(self.modelNotas)
                            }
                            #if os(macOS)
                            .searchable(text: $textFieldTitle, prompt: "Buscar")
                            #else
                            .searchable(text: $textFieldTitle, placement: .navigationBarDrawer(displayMode: .always)  , prompt:"Buscar")
                            #endif
                            
                            .task {
                                self.modelNotas.getAllNotasToModel()
                            }
                        }
                    }else{
                       
                            Spacer()
                                   autenticationView()
                    }
                        

                            Spacer()
                           
                            Divider()
                            HStack(spacing: 30){
                                Spacer()
                                #if os(iOS)
                                Button("Volver"){
                                    dimiss()
                                }
                                .foregroundStyle(.black)
                                .buttonStyle(.bordered)
                                .padding(.trailing, 20)
                                #endif
                            }
                        
                            .padding(.bottom, 20)
                }
                
                
            }
                .navigationTitle("Notas")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar{
                    
                    //Chequea si esta habilitado la protección de las notas
                    if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false { //No esta habilitada la protección
                       
                        ToolbarItem {
                            Menu{
                                Button{
                                    withAnimation {
                                        self.modelNotas.getAllNotasToModel()
                                    }
                                }label:{
                                    Label("Todas las notas", systemImage: "text.magnifyingglass.rtl")
                                }
                                
                                Button{
                                    withAnimation {
                                        modelNotas.notas = NotasModel().getFavNotas()
                                    }
                                    
                                }label:{
                                    Label("Notas Favoritas", systemImage: "text.magnifyingglass.rtl")
                                }
                                
                                Button{
                                    showAlertSearch = true
                                }label:{
                                    Label("Buscar en Notas", systemImage: "text.magnifyingglass.rtl")
                                }
                                
                            }label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                        
                        if #available(iOS 26.0, macOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                        ToolbarItem {
                            Button{
                                #if os(macOS)
                                
                                showWindow(for: AddNotasView(),
                                           environmentObjects: [self.modelNotas],
                                           title: "Crear Nota",
                                           size: AppCons.windows_size_content,
                                           isModal: false
                                )
                                
                                #else
                                showAddNoteView = true
                                #endif
                                
                            }label: {
                                Image(systemName: "plus")
                            }
                        }
                        
                        
                    }else{ //Si esta habilitada la protección de las notas
                        
                        //Chequear si se tiene acceso al contenido
                        if self.canOpenNotas {
                            
                            ToolbarItem {
                                Menu{
                                    Button("Todas las notas"){
                                        withAnimation {
                                            self.modelNotas.getAllNotasToModel()
                                        }
                                    }
                                    Button("Notas Favoritas"){
                                        withAnimation {
                                            
                                            self.modelNotas.notas = self.modelNotas.getFavNotas()
                                        }
                                        
                                    }
                                    Button("Buscar en Notas"){
                                        showAlertSearch = true
                                    }
                                    
                                }label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                }
                            }
                            
                            if #available(iOS 26.0, macOS 26.0, *) {
                                ToolbarSpacer(.fixed)
                            }
                            
                            ToolbarItem {
                                Button{
                                    #if os(macOS)
                                    
                                    showWindow(for: AddNotasView(),
                                               environmentObjects: [self.modelNotas],
                                               title: "Crear Nota",
                                               size: AppCons.windows_size_content_small,
                                               isModal: false
                                    )
                                    
                                    #else
                                    showAddNoteView = true
                                    #endif
                                }label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                    
                    
                    
                    
                }
                .sheet(isPresented: $showAddNoteView) {
                    AddNotasView()
                        .environmentObject(self.modelNotas)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
                    
                }
                .alert("Buscar en Notas", isPresented: $showAlertSearch){
                    TextField("", text: $textField, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textField, donde: .nota)
                        if temp.count > 0 {
                            self.modelNotas.notas = temp
                        }
                    }
                }
                .alert("Buscar en título de Notas", isPresented: $showAlertSearchTitle){
                    TextField("", text: $textFieldTitle, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textFieldTitle, donde: .titulo)
                        if temp.count > 0 {
                            self.modelNotas.notas = temp
                        }
                    }
                }
                .alert(isPresented: $showAlert){
                    Alert(title: Text("Notas"), message: Text(alertMessage))
                }
                
            
        }
        

    }
    
   
    //Actualiza una nota
    func updateYorj(nota : Notas){
        
        if  self.modelNotas.updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            self.modelNotas.getAllNotasToModel()
        }
        
        
    }
    

    
    @ViewBuilder // View Extract
    func autenticationView()-> some View {
        VStack(alignment: .center,  spacing: 20) {
             
             Text("Se ha habilitado la protección de las Notas")
                 .foregroundStyle(.orange.opacity(0.7))
                 .font(.system(size: 18))
                 .bold()
            
            //Chequeando si existe biometría en el dispositivo
            if BiometryCheckerSupport.checkBiometricSupport() == .available{
                Button{
                    UtilFuncs.autent(HabilitarContenido: self.$canOpenNotas) //Lanzando el chequeo biométrico
                }label: {
                    Image(systemName: "key.viewfinder")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.orange.opacity(0.7))
                        .symbolEffect(.pulse, isActive: true)
                }
                Text("Toque la imagen de arriba para abrir las Notas")
                
                //Permitir acceder también por contraseña. Si existe una contraseña guardada
                if KeychainHelper.shared.getPassword() != nil{
                    VStack{
                        NavigationLink("Acceder por contraseña"){
                            LogginView(ente: .Notas)
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                    }.padding(.vertical, 25)
                }
                
                
            }else{ // Si no existe biometría en el dispositivo
                
                //Determinamos que haya una contraseña Guardada:
                if KeychainHelper.shared.getPassword() != nil{ //Hay contraseña en el llavero
                    VStack{
                        Text("Parece que su dispositivo no admite biometría. Utilice el botón debajo para entrar por contraseña.")
                        NavigationLink("Acceder por contraseña"){
                            LogginView(ente: .Notas)
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .padding()
                        
                        Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                            .font(.footnote)
                    }
                }else{ //No existe una contrasela en el llavero. Permitir crear una
                    VStack{
                        Text("Parece que su dispositivo no admite biometría. Establezca una contraseña para tener acceso seguro a las Notas Protegidas")
                        NavigationLink("Crear una contraseña"){
                         CreatePasswordView()
                           
                        }
                        .buttonStyle(.bordered)
                        .tint(.primary)
                        .padding()
                        
                        Text("Si no recuerda la contraseña puede consultarla en Ajustes, en un dispositivo con biometría asociado a la misma cuenta de iCloud")
                            .font(.footnote)
                    }
                }
                
                
            }
            
             
         }
    }

}

//Card notas:
struct cardNotas: View{
    let nota : Notas?
    @EnvironmentObject var modelNotas : NotasModel
    @State private var expandText = false
    @State private var isfav = false
    @State private var expandNota = false
    
    //Opciones:
    @State private var showConfirmDialogDeleteNota = false
    @State private var showUpdateNoteView = false
    
    @AppStorage(AppCons.UD_setting_fontListaSize)  var fontSizeLista : Int = 20

    
    var body: some View{
        VStack(){
            HStack{

                Text(nota?.title ?? "")
                    .bold()
                    .fontDesign(.serif)
                    .font(.system(size: CGFloat(self.fontSizeLista)))
                #if os(macOS)
                    .foregroundStyle(Color.primary)
                #else
                    .foregroundStyle(.black)
                #endif
                    
                    .bold()
                    .padding(8)
                    .onTapGesture(count: 2) {
                        withAnimation {
                            showUpdateNoteView = true
                        }
                        
                    }
                    .onTapGesture {
                        withAnimation {
                            expandNota.toggle()
                        }
                            
                    }
                Spacer()
                if isfav {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LinearGradient(colors: [.orange, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .onTapGesture {
                            _ = NotasModel().updateFav(NotaID: nota?.id ?? "", favState: false)
                            withAnimation {
                                isfav = nota?.isfav ?? false ? true : false
                            }
                        }
                }

                Menu{
                        Text("< \(nota?.title ?? "") >")
                    #if os(macOS)
                    Button{
                        if self.nota?.id != nil {
                            showWindow(for: UpdateNotasView(NotaId: nota!.id!, title: nota!.title!, nota: nota!.nota!),
                                       environmentObjects: [self.modelNotas],
                                       title: "Editar Nota",
                                       size: AppCons.windows_size_content_small,
                                       isModal: true
                            )
                        }
                    }
                        label:{
                        Label("Editar...", systemImage: "highlighter.badge.ellipsis")
                    }
                    #else
                    
                    NavigationLink{
                        if self.nota?.id != nil {
                            UpdateNotasView(NotaId: nota!.id!, title: nota!.title!, nota: nota!.nota!)
                                .environmentObject(self.modelNotas)
                        }
                          
                    }
                        label:{
                        Label("Editar...", systemImage: "highlighter.badge.ellipsis")
                    }
                    
                    #endif
                    
                    
                    
                    
                        Button{
                        if nota!.isfav {
                            _ = NotasModel().updateFav(NotaID: nota!.id ?? "", favState: false)
                        }else{
                            _ = NotasModel().updateFav(NotaID: nota!.id ?? "", favState: true)
                        }
                            withAnimation {
                                isfav = nota!.isfav ? true : false
                            }
                        
                        }label:{
                            Label(nota!.isfav ? "Quitar Favorito" : "Hacer Favorito", systemImage: nota!.isfav ? "heart.slash" : "heart")
                        }
                    NavigationLink{
                        let isfav = nota!.isfav
                        let texto = "\(AppCons.zspNota)\(nota!.title ?? "")::\(nota!.nota ?? "")::\(isfav == true  ? "si" : "no")"
                            GenerateQRView(footer: texto, showImage: true)
                    }label:{
                        Label("Generar QR...", systemImage: "qrcode")
                    }
                    
                    #if os(macOS)
                    Button{
                        showWindow(for: LienzoMain(texto: nota?.nota ?? "", imagenPrimariaACargar: nil),
                                   environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false
                        )
                        
                    }label:{
                        Label("Lienzo", systemImage: "heart.text.square")
                    }
                    
                    #else
                    NavigationLink{
                        LienzoMain(texto: nota?.nota ?? "", imagenPrimariaACargar: nil)
                    }label:{
                        Label("Lienzo", systemImage: "heart.text.square")
                    }
                    #endif
                    
                    
                    #if os(macOS)
                    
                    Button{
                        showWindow(for: ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: self.nota?.nota, onSave: {}),
                                   environmentObjects: [],
                                   title: "Lienzo",
                                   size: .absolute(CGSize(width: 650, height: 750)),
                                   isModal: false)
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #else
                    
                    NavigationLink{
                        ReminderEditorView(reminderAEditar: nil, titleAImportar: self.nota?.title, textoAImportar: nota?.nota, onSave: {})
                    }label:{
                        Label("Recordatorios", systemImage: "heart.text.square")
                    }
                    
                    #endif
                    
                    
                    
                    Button{
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(nota?.nota ?? "", forType: .string)
                        #else
                        UIPasteboard.general.string = nota?.nota ?? ""
                        #endif
                        
                    }label:{
                        Label("Copiar Nota...", systemImage: "square.fill.on.square.fill")
                    }
                    
                    
                    ShareLink(item: "\(nota!.title ?? "")\n \(nota!.nota ?? "")")
                    
                    //Funciones de inteligencia: IA
                    if #available(iOS 26.0, macOS 26.0, *) {
                        if IAModelAppleIntelligence.isAvailable(){
                            
                            #if os(macOS)
                            Button{
                                if let  temp = nota!.nota{
                                    showWindow(for: RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar, autorRespuesta: "nev" ),
                                    environmentObjects: [],
                                               title: "Interpretar Nota",
                                               size: AppCons.windows_size_content,
                                               isModal: true
                                    )
                                    
                                }
                                

                            }label:{
                                Label("Interpretar", systemImage: "sparkles")
                            }
                            .tint(.purple)
                            
                            Button{
                                if let  temp = nota!.nota{
                                    showWindow(for: RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta, autorRespuesta: "nev"),
                                    environmentObjects: [],
                                               title: "Aplicación Práctica - Nota",
                                               size: AppCons.windows_size_content,
                                               isModal: true
                                    )
                                    
                                }
                                
                            }label:{
                                Label("Aplicación Práctica", systemImage: "sparkles")
                            }
                            .tint(.purple)
                    
                    Button{
                        if let  temp = nota!.nota{
                            showWindow(for:   ChatView(textoACargar: nota!.nota),
                            environmentObjects: [],
                                       title: "Charlar - Notas",
                                       size: AppCons.windows_size_content,
                                       isModal: false
                            )
                        }
                    }label: {
                        Label("Charlar con IA", systemImage: "sparkles")
                    }
                    .tint(.purple)
                            
                            #else
                            Menu{
                                NavigationLink{
                                    if let  temp = nota!.nota{
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar, autorRespuesta: "nev" )
                                    }
                                    
                                    
                                }label:{
                                    Label("Interpretar", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    if let  temp = nota!.nota{
                                        RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta, autorRespuesta: "nev")
                                    }
                                    
                                }label:{
                                    Label("Aplicación Práctica", systemImage: "sparkles")
                                }
                                .tint(.purple)
                                
                                NavigationLink{
                                    ChatView(textoACargar: nota!.nota)
                                }label: {
                                    Label("Charlar con IA", systemImage: "sparkles")
                                }
                                .tint(.purple)
                            }label:{
                                Label("Funciones IA", systemImage: "sparkles")
                            }
                           
                    #endif
 
                        }
                    }
                    
                    Button{
                        showConfirmDialogDeleteNota = true
                    }label:{
                        Label("Eliminar nota...", systemImage: "trash")
                    }
                    .tint(.red)
   
                }label: {
                    Image(systemName: "ellipsis")
                        .tint(.primary)
                        .padding(15)
                }
                
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    expandNota.toggle()
                }
                
            }
            .onAppear{
                isfav = nota!.isfav
            }
            //Dialogo de confirmación para elimnar una nota
            .confirmationDialog("Esta seguro?", isPresented: $showConfirmDialogDeleteNota){
                Button("Eliminar Nota", role: .destructive){
                    
                    withAnimation {
                        modelNotas.deleteNota(nota: nota!)
                        self.modelNotas.getAllNotasToModel()
                    }

                }
            } message: {
                Text("La nota será removida!!!")
            }

            if expandNota {
                    //Divider()
                    HStack{
                        SelectableText(text: nota!.nota ?? "")
                       // Text(nota!.nota ?? "")
                            .font(.system(size: 20))
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                            .contentShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 5)
                            .background{
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.55, green: 0.75, blue: 0.89), // azul claro
                                        Color(red: 0.55, green: 0.75, blue: 0.89)  // azul un poco más oscuro
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}








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
    @State private var showAddNoteView = false
    @State private var list : [Notas] = NotasModel().getAllNotas()
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
        if self.textFieldTitle.isEmpty {return self.list}
        return self.list.filter{$0.title?.localizedCaseInsensitiveContains(self.textFieldTitle) ?? false}
    }
 
    var body: some View {
        NavigationStack {
            if ( canOpenNotas == true  ||   UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false) {
                ScrollView(.vertical){
                    
                    ForEach (self.filtered.reversed()){ nota in
                        cardNotas(nota: nota, notas: $list)
                    }
                    .searchable(text: $textFieldTitle, placement: .navigationBarDrawer(displayMode: .always)  , prompt:"Buscar")
                    .task {
                            list = NotasModel().getAllNotas()
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
                    
                    Button("Volver"){
                        dimiss()
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
                .navigationTitle("Notas")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    
                    //Chequea si esta habilitado la protección de las notas
                    if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID) == false { //No esta habilitada la protección
                       
                       
                        
                        
                        ToolbarItem {
                            Menu{
                                Button("Todas las notas"){
                                    withAnimation {
                                        list.removeAll()
                                        list = NotasModel().getAllNotas()
                                    }
                                }
                                Button("Notas Favoritas"){
                                    withAnimation {
                                        list.removeAll()
                                        list = NotasModel().getFavNotas()
                                    }
                                    
                                }
                                Button("Buscar en Notas"){
                                    showAlertSearch = true
                                }
                                
                            }label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                        
                        if #available(iOS 26.0, *) {
                            ToolbarSpacer(.fixed)
                        }
                        
                        ToolbarItem {
                            Button{
                                showAddNoteView = true
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
                                            list.removeAll()
                                            list = NotasModel().getAllNotas()
                                        }
                                    }
                                    Button("Notas Favoritas"){
                                        withAnimation {
                                            list.removeAll()
                                            list = NotasModel().getFavNotas()
                                        }
                                        
                                    }
                                    Button("Buscar en Notas"){
                                        showAlertSearch = true
                                    }
                                    
                                }label: {
                                    Image(systemName: "line.3.horizontal.decrease")
                                }
                            }
                            
                            if #available(iOS 26.0, *) {
                                ToolbarSpacer(.fixed)
                            }
                            
                            ToolbarItem {
                                Button{
                                    showAddNoteView = true
                                }label: {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                    }
                    
                    
                    
                    
                }
                .sheet(isPresented: $showAddNoteView) {
                    AddNotasView(notas: $list)
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.hidden)
                    
                }
                .alert("Buscar en Notas", isPresented: $showAlertSearch){
                    TextField("", text: $textField, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textField, donde: .nota)
                        if temp.count > 0 {
                            list.removeAll()
                            list = temp
                        }
                    }
                }
                .alert("Buscar en título de Notas", isPresented: $showAlertSearchTitle){
                    TextField("", text: $textFieldTitle, axis: .vertical)
                    Button("Buscar"){
                        let temp = NotasModel().searchTextInNotas(text: textFieldTitle, donde: .titulo)
                        if temp.count > 0 {
                            list.removeAll()
                            list = temp
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
        
        if  NotasModel().updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            list.removeAll()
            list.append(contentsOf: NotasModel().getAllNotas())
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
                         LogginView(ente: "Notas", canOpen: self.$canOpenNotas)
                           
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
                         LogginView(ente: "Notas", canOpen: self.$canOpenNotas)
                           
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
    let nota : Notas
    @Binding var  notas : [Notas]
    @State private var expandText = false
    @State private var isfav = false
    @State private var expandNota = false
    
    //Opciones:
    @State private var showConfirmDialogDeleteNota = false
    @State private var showUpdateNoteView = false
    
    var body: some View{
        VStack(){
            HStack{

                Text(nota.title ?? "")
                    .bold()
                    .fontDesign(.serif)
                    .padding(8)
                    .onTapGesture(count: 2) {
                        showUpdateNoteView = true
                    }
                    .onTapGesture {
                            expandNota.toggle()
                    }
                Spacer()
                if isfav {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(LinearGradient(colors: [.orange, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .onTapGesture {
                            _ = NotasModel().updateFav(NotaID: nota.id ?? "", favState: false)
                            withAnimation {
                                isfav = nota.isfav ? true : false
                            }
                        }
                }

                Menu{
                        Text("< \(nota.title ?? "") >")
                    
                        Button("Editar..."){showUpdateNoteView = true}
                        Button(nota.isfav ? "Quitar Favorito" : "Hacer Favorito"){
                        if nota.isfav {
                            _ = NotasModel().updateFav(NotaID: nota.id ?? "", favState: false)
                        }else{
                            _ = NotasModel().updateFav(NotaID: nota.id ?? "", favState: true)
                        }
                            withAnimation {
                                isfav = nota.isfav ? true : false
                            }
                        
                        }
                    NavigationLink("Generar QR..."){
                            let isfav = nota.isfav
                            let texto = "nota>>\(nota.title ?? "")>>\(nota.nota ?? "")>>isfav:\(isfav == true  ? "Si" : "No")"
                            GenerateQRView(footer: texto, showImage: true)
                        }
                    Button("Copiar Nota"){
                        UIPasteboard.general.string = nota.nota
                    }
                    ShareLink(item: "\(nota.title ?? "")\n \(nota.nota ?? "")")
                    
                    if #available(iOS 26.0, *) {
                        if IAModel.isAvailable(){

                                    
                                    NavigationLink{
                                        if let  temp = nota.nota{
                                            RespondView(nameConference: "", texto: temp, tipoSalida: .interpretar )
                                        }
                                        

                                    }label:{
                                        Label("Interpretar", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                                    
                                    NavigationLink{
                                        if let  temp = nota.nota{
                                            RespondView(nameConference: "", texto: temp, tipoSalida: .practicaConcreta)
                                        }
                                        
                                    }label:{
                                        Label("Aplicación Práctica", systemImage: "sparkles")
                                    }
                                    .tint(.purple)
                             
                        }
                    }
                    
                    
                    Button("Eliminar..."){showConfirmDialogDeleteNota = true}
   
                }label: {
                    Image(systemName: "ellipsis")
                        .tint(.primary)
                        .padding(15)
                }
                
            }
            .contentShape(Rectangle())
            .onTapGesture {
                expandNota.toggle()
            }
            .onAppear{
                isfav = nota.isfav
            }
            //Dialogo de conformación para elimnar una nota
            .confirmationDialog("Esta seguro?", isPresented: $showConfirmDialogDeleteNota){
                Button("Eliminar Nota", role: .destructive){
                    withAnimation {
                        NotasModel().deleteNota(nota: nota)
                          notas.removeAll()
                          notas.append(contentsOf: NotasModel().getAllNotas())
                    }

                }
            } message: {
                Text("La nota será removida!!!")
            }
            .sheet(isPresented: $showUpdateNoteView){
                UpdateNotasView(NotaId: nota.id ?? "", title:  nota.title ?? "", nota: nota.nota ?? "", notas: $notas)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.hidden)
            }
            if expandNota {
                    //Divider()
                    HStack{
                        Text(nota.nota ?? "")
                            .font(.system(size: 18))
                            .italic()
                            .padding(.vertical, 4)
                            .padding(.horizontal, 5)
                            .fontDesign(.serif)
                            //.lineLimit(expandText ? nil :  1)
                            
                            .onTapGesture {
                                    expandText.toggle()
                            }
                        Spacer()
                }
            
            
            }
            
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        //.shadow(radius: 5)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
    
    
    
}






#Preview("Home") {
    ListNotasViews()
}

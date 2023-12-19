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
    @Environment(\.colorScheme) var theme
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
 
    var body: some View {
        NavigationStack {
            //Solo muestra el contenido
            if canOpenNotas {
                List(list,id: \.id){nota in
                   Row(notas: $list, nota: nota)
                }
                .onAppear {
                    list = NotasModel().getAllNotas()
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
                    HStack{
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
                            Button("Buscar en títulos"){
                                showAlertSearchTitle = true
                            }
                            
                            
                        }label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundStyle(theme ==  .dark ? .white :  .black)
                        }
                        Button{
                            showAddNoteView = true
                        }label: {
                            Image(systemName: "plus")
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
            else{
                ZStack{
                    VStack(spacing: 20) {
                        Text("Se ha habilitado la protección de las Notas")
                            .foregroundStyle(.orange.opacity(0.7))
                            .font(.system(size: 18))
                            .bold()
                        Button{
                            autent()
                        }label: {
                            Image(systemName: "key.viewfinder")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.orange.opacity(0.7))
                                .symbolEffect(.pulse, isActive: true)
                        }
                    }
                    
                }
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID){
                canOpenNotas = false
            }else{
                canOpenNotas = true
            }
        }

    }
    
   
    
    func updateYorj(nota : Notas){
        
        if  NotasModel().updateNota(NotaID: nota.id ?? "", newTitle: nota.title ?? "", newNota: nota.nota ?? "") {
            list.removeAll()
            list.append(contentsOf: NotasModel().getAllNotas())
        }
        
        
    }
    
//Autentificación con FaceID
    func autent(){
        var error : NSError?
        if contextLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            contextLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor autentícate para tener acceso a Notas") { success, error in
                        if success {
                             //Habilitación del contenido
                            withAnimation {
                                canOpenNotas = true
                            }
                            
                        } else {
                            alertMessage = "Error en la autenticación biométrica"
                            showAlert = true
                        }
                    }
            
            
        }else{
            UserDefaults.standard.setValue(false, forKey: AppCons.UD_setting_NotasFaceID)
            alertMessage = "El dispositivo no soporta autenticación Biométrica. Se ha deshabilitado la protección de Notas"
            showAlert = true
            canOpenNotas = true //Deshabilitando la protección del Diario.
        }
    }
    
    

}




//Representa un item de la lista
struct Row : View {

    @State private var confirm = false
    @State private var showUpdateNoteView = false
    
    @Binding var notas : [Notas] //Listado de Notas cargadas
    var nota: Notas //La nota para esta fila
    @State private var showConfirmDialogDeleteNota = false
   
    
    var body: some View {
        NavigationLink{
            ShowNotaView(nota: nota, notass: $notas)
        } label: {
            Text(nota.title ?? "")
        }
        .swipeActions(edge: .leading){
            Button{
                var stateFav = nota.isfav
                stateFav.toggle()
                _ =   NotasModel().updateFav(NotaID: nota.id ?? "", favState: stateFav)
                 
            }label: {
                Image(systemName: "heart")
                    .tint(.orange)
            }
            NavigationLink{
                let isfav = nota.isfav
                let texto = "nota>>\(nota.title ?? "")>>\(nota.nota ?? "")>>isfav:\(isfav == true  ? "Si" : "No")"
                GenerateQRView(footer: texto, showImage: true)
            }label: {
                Image(systemName: "qrcode")
                    .tint(.gray)
            }
        }
        .swipeActions(edge: .trailing){ //Eliminar una nota
            Button{
                showUpdateNoteView = true
            }label: {
                Image(systemName: "pencil.and.scribble")
                    .tint(.green)
            }
            Button{
                showConfirmDialogDeleteNota = true
            }label: {
                Image(systemName: "minus.circle")
                    .tint(.red)
            }
            
            
        }
        
        //Sheets:
        .sheet(isPresented: $showUpdateNoteView){
            UpdateNotasView(NotaId: nota.id ?? "", title:  nota.title ?? "", nota: nota.nota ?? "", notas: $notas)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
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

    }
    
}

















#Preview("Home") {
    ContentView()
        .dynamicTypeSize(.xxxLarge)
}

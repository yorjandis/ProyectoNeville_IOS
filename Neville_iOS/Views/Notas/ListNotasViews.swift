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
    private var filtered : [Notas] {
        if self.textFieldTitle.isEmpty {return self.list}
        return self.list.filter{$0.title?.localizedCaseInsensitiveContains(self.textFieldTitle) ?? false}
    }
 
    var body: some View {
        NavigationStack {
            if canOpenNotas {
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
                .onAppear {
                    if UserDefaults.standard.bool(forKey: AppCons.UD_setting_NotasFaceID){
                        canOpenNotas = false
                    }else{
                        canOpenNotas = true
                    }
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
        

    }
    
   
    //Actualiza una nota
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
    
    @ViewBuilder // View Extract
    func autenticationView()-> some View {
        VStack(alignment: .center,  spacing: 20) {
             
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

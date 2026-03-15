//
//  cardItem.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 25/11/25.
//


import SwiftUI
import CoreData

struct cardItemDiario: View{
    @Environment(\.colorScheme) var theme
    
    @State var diario : Diario //Entrada a mostrar
    var onEntryDeleted: (Date?) -> Void = { _ in }
    var onEntryUpdated: (Date?) -> Void = { _ in }
    
    @StateObject private var diarioModel = DiarioModel.shared
    
    @State private var expandText = false //Permite expandir/contraer el texto de una entrada
    @State private var isEditing = false
    @State private var textfield = ""
    //Alert: Modificar titulo
    @State private var showAlert = false
    @State private var title = ""
    //Alert Eliminar Entrada
    @State private var showAlertDeleteEntry = false
    //Edit Content
    @State private var showSheet = false
    //favorito
    @State private var isfav : Bool = false
    //Animation
    @State private var animValue = 0
    

    var body: some View{
        VStack(spacing: 20){
            //EmotioIcon
            HStack{
                Menu{
                    ForEach(Emociones.allCases, id: \.self) { emocion in
                        Button {
                            diarioModel.UpdateEmoticono(emoticono: emocion, diario: diario)
                            withAnimation {
                                diarioModel.getAllItem()
                            }
                        } label: {
                            HStack {
                                Text(emocion.rawValue)
                                Text(emocion.emoji)
                            }
                        }
                    }
                }label: {
                    Text(Emociones.emoji(from: diario.emotion))
                        .font(.system(size: 40))
                }
                
                //Título
                Text(diario.title ?? "")
                    .font(.headline).bold()
                    .onTapGesture(count: 2) {
                        self.title = diario.title ?? ""
                        #if os(macOS)
                        showWindow(for: VStack{
                            TextField("Nuevo título", text: $title)
                                .foregroundStyle(theme == .dark ? .white : .black)
                            Button("Cancelar"){
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                            }
                            Button("Guardar"){
                                diarioModel.UpdateTitle(title: title, diario: diario)
                                onEntryUpdated(diario.fecha)
                                //Saliendo
                                if let window = NSApp.keyWindow {
                                    closeWindow(window)
                                }
                            }
                        }.padding(10),
                                   environmentObjects: [self.diarioModel],
                                   title: "Editar Entrada Diario",
                                   size: AppCons.windows_size_content_small,
                                   isModal: true
                        
                        )
                        #else
                        showAlert = true
                        #endif
                        
                    }
                Spacer()
                
            }
            
            
            //Contenido
                Text(diario.content ?? "")
                    .font(.system(size: 18))
                    .foregroundStyle(.black)
                    .italic()
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .lineLimit(self.diarioModel.expandirEntrada == self.diario.fecha?.formatted() ? nil :  1) //Aquí es donde se contrae o se expande las lineas
                    .onTapGesture{
                        withAnimation {
                            if self.diarioModel.expandirEntrada == self.diario.fecha?.formatted(){
                                self.diarioModel.expandirEntrada = ""
                            }else{
                                self.diarioModel.expandirEntrada = self.diario.fecha?.formatted() ?? ""
                            }
                        }
                    }
                    .onTapGesture(count: 2) {
                        
                        #if os(macOS)
                        showWindow(for: editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral"), onEntryUpdated: onEntryUpdated),
                                   environmentObjects: [self.diarioModel],
                                   title: "Editar entrada Diario",
                                   size: AppCons.windows_size_content,
                                   isModal: false
                        
                        )
                        
                        #else
                        self.showSheet = true
                        #endif
                        
                        
                       
                    }

            
            
                
            
            //Fecha, fav y ContextMenu
            VStack {
                Divider()
                HStack{
                    VStack{
                        HStack{
                            Text("Modificado:")
                            .font(.system(size: 10))
                            Text(diario.fechaM ?? Date.now, style: .date)
                                .font(.caption2).bold()
                            Text(diario.fechaM ?? Date.now, style: .time)
                                .font(.caption2).bold()
                        }
                        HStack{
                            Text("       Creado:")
                            .font(.system(size: 10))
                            Text(diario.fecha ?? Date.now, style: .date)
                                .font(.caption2).bold()
                            Text(diario.fecha ?? Date.now, style: .time)
                                .font(.caption2).bold()
                        }
   
                    }
                    Spacer()
                    //Favorito
                    Button{
                        isfav.toggle()
                        diarioModel.UpdateFav(isFav: isfav, diario: diario)
                        animValue += 1
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred() //Leve vibración al tocal el boton
                        #endif
                        
                    }label: {
                        Image(systemName: isfav ? "heart.fill" : "heart")
                            .foregroundStyle(.black)
                            .padding(.trailing, 10)
                            .symbolEffect(.bounce, value: animValue)
                    }
                    .buttonStyle(.plain)
                    .onAppear{
                        isfav = diario.isFav
                    }
                    
                    //Context Menu
                    Menu{
                        Button{
                            #if os(macOS)
                            showWindow(for: editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral"), onEntryUpdated: onEntryUpdated),
                                       environmentObjects: [self.diarioModel],
                                       title: "Editar entrada Diario",
                                       size: AppCons.windows_size_content,
                                       isModal: true
                                       
                            )
                            
                            #else
                            self.showSheet = true
                            #endif
                        }label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive){
                            showAlertDeleteEntry = true
                        }label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        
                    }label: {
                        Image(systemName: "ellipsis")
                            .tint(.black)
                            .frame(width: 25, height: 25)
                            .contentShape(Rectangle())
                    
                }//menu
                .buttonStyle(.plain)
                    
                }
            }
        }

        .alert("Modificar Título", isPresented: $showAlert){
            TextField("Nuevo título", text: $title)
                .foregroundStyle(theme == .dark ? .white : .black)
            Button("Cancelar"){
                showAlert = false
            }
            Button("Guardar"){
                diarioModel.UpdateTitle(title: title, diario: diario)
                onEntryUpdated(diario.fecha)
            }
            
        }
        .alert("¿Desea eliminar la entrada? \n Esta acción no puede deshacerse", isPresented: $showAlertDeleteEntry, actions: {
            Button("Eliminar", role: .destructive){
                withAnimation {
                    let deletedDate = diario.fecha
                    diarioModel.DeleteItem(diario: diario)
                    onEntryDeleted(deletedDate)
                }
            }
        })
        .sheet(isPresented: $showSheet){
            editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral"), onEntryUpdated: onEntryUpdated)
        }
        
    }
}

//
//  FilterByDiarioView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 9/2/24.
//


//Yorj: Habilitar pronto!

 import SwiftUI
 struct FilterByDiarioView: View {
     @StateObject private var modelWatch = watchModel.shared
     @Environment(\.dismiss) private var dismiss
     
 @State private var showSheetTitulo      = false
 @State private var showSheetTexto       = false
 @State private var showSheetEmocion     = false
 @State private var showSheetFecha       = false
 @State private var showSheetRangoFecha  = false
 @State private var showSheetAntiguedad  = false
 @State private var fecha1 = Date.now
 @State private var fecha2 = Date.now
 @State private var searchText = ""
 
 
 var body: some View {
     VStack{
         Text("Filtrar Diario por...")
         Divider()
         ScrollView {
             Button("Título"){
                 showSheetTitulo = true
             }
             
             Button("Contenido"){
                 showSheetTexto = true
             }
             
             Button("Favoritos"){
                 Task{
                     modelWatch.listDiario = modelWatch.getDiarioEntradasFavoritas()
                     dismiss()
                 }
             }
             Button("Emoción"){
                 self.showSheetEmocion = true
             }
             
             Button("Fecha Creación"){
                 self.showSheetFecha = true
             }
             Button("Rango de Fecha"){
                 self.showSheetRangoFecha = true
             }
             Button("Antiguedad"){
                 self.showSheetAntiguedad = true
             }
             
         }
         
         
     }
     .sheet(isPresented: $showSheetTitulo){
         VStack {
             TextField("Texto de la entrada", text: $searchText)
             Button("Buscar") {
                 modelWatch.listDiario = modelWatch.searchTextInDiario(text: searchText, donde: .titulo)
                 showSheetTitulo = false
                 dismiss()
             }
         }
         .padding()
         .onAppear {
             searchText = ""
         }
         
     }
     .sheet(isPresented: $showSheetTexto){
         VStack {
             TextField("Contenido de la entrada", text: $searchText)
             Button("Buscar") {
                 modelWatch.listDiario = modelWatch.searchTextInDiario(text: searchText, donde: .contenido)
                 showSheetTexto = false
                 dismiss()
             }
         }
         .padding()
         .onAppear {
             searchText = ""
         }
         
     }
     .sheet(isPresented: $showSheetFecha){
         VStack{
             DatePicker("Fecha de creación", selection: $fecha1, displayedComponents: [.date])
                 .padding(.top, 50)
             Button{
                 Task{
                     modelWatch.listDiario = modelWatch.searchPorFecha(for: self.fecha1)
                     dismiss()
                 }
             }label: {
                 Text("Buscar")
                     .padding(.vertical, 10)
                     .foregroundColor(.black)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .background(.orange)
                     .clipShape(RoundedRectangle(cornerRadius: 20))
             }
             .padding([.vertical, .horizontal])
             .buttonStyle(PlainButtonStyle())
             
         }
         
         .ignoresSafeArea()
         
     }
     .sheet(isPresented: $showSheetRangoFecha){
         ScrollView{
             DatePicker("Fecha Inicio", selection: $fecha1, displayedComponents: [.date])
                 .frame(height: 70)
                 .padding(.top, 30)
             
             DatePicker("Fecha final", selection: $fecha2, displayedComponents: [.date])
                 .frame(height: 70)
             
             Button{
                 Task{
                     modelWatch.listDiario = modelWatch.searchPorRangoFecha(from: self.fecha1, to: self.fecha2)
                     dismiss()
                 }
             }label: {
                 Text("Buscar")
                     .padding(.vertical, 10)
                     .foregroundColor(.black)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .background(.orange)
                     .clipShape(RoundedRectangle(cornerRadius: 20))
             }
             .padding([.vertical, .horizontal])
             .buttonStyle(PlainButtonStyle())
             
         }
         .ignoresSafeArea()
         
     }
     .sheet(isPresented: $showSheetAntiguedad){
         VStack {
             Text("Filtrar por antiguedad")
             Divider()
             ScrollView{
                 Button("Tres días atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .tresDias)
                         dismiss()
                     }
                 }
                 Button("Semana pasada"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .semana)
                         dismiss()
                     }
                 }
                 Button("Quicena pasada"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .quincena)
                         dismiss()
                     }
                 }
                 Button("Mes anterior"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .mes)
                         dismiss()
                     }
                 }
                 Button("Dos meses atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .dosMeses)
                         dismiss()
                     }
                 }
                 Button("Tres meses atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .tresMeses)
                         dismiss()
                     }
                 }
                 Button("Seis meses atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .seisMeses)
                         dismiss()
                     }
                 }
                 Button("Un año atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .unAno)
                         dismiss()
                     }
                 }
                 Button("Dos año atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .dosAnos)
                         dismiss()
                     }
                 }
                 Button("Tres año atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .tresAnos)
                         dismiss()
                     }
                 }
                 Button("Cinco año atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .cincoAnos)
                         dismiss()
                     }
                 }
                 Button("Diez año atrás"){
                     Task{
                         modelWatch.listDiario = modelWatch.searchPorAntiguedad(for: .diezAnos)
                         dismiss()
                     }
                 }
             }
         }
     }
     .sheet(isPresented: $showSheetEmocion){
         VStack{
             
             ScrollView{
                 ForEach (Emoticono2.allCases, id: \.self) {item in
                     Button{
                         Task{
                             modelWatch.listDiario = modelWatch.getDiarioEntradasPorEmotion(emotion: item.txt)
                             dismiss()
                         }
                         
                     }label: {
                         HStack{
                             Text(item.rawValue).font(.system(size: 40))
                             Text(item.txt)
                             Spacer()
                         }
                     }
                     
                 }
             }
         }
     }
 }
     

     
 }
 
 #Preview {
 FilterByDiarioView()
 }

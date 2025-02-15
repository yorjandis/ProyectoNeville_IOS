//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData

struct DiarioListView: View {

    @Environment(\.dismiss) var dimiss
    @StateObject private var diarioModel = DiarioModel.shared
    
    //Para filtros en fechas
    enum TypeOfSearch{case fix, interval}
    
    //Para Buscar en títulos
    @State private var showAlertFilterByTitles = false
    @State private var textfielTitles = ""
    //Para Buscar en contenido
    @State private var showAlertFilterByContent = false
    @State private var showFilterByDate = false
    @State private var showFilterByIntervalDate = false
    @State private var datepicker : Date = Date.now
    @State private var textfielContent = ""
 

    
    let titlesExamples : [(String,String)] = [
    ("Revisión de este día", "neutral"),
    ("¿Como me he sentido hoy?", "neutral" ),
    ("Hoy agradezco:", "feliz"),
    ("¿Que debo mejorar?", "desanimado"),
    ("¿Que he aprendido hoy?","neutral"),
    ("Mi vida es maravillosa porque...", "feliz"),
    ("!Hoy se ha materializado un deseo!","feliz"),
    ("!No es maravillo si...!","feliz"),
    ("!Lo he logrado!","feliz")]
    

    @State var canOpenDiario : Bool = false 
    
    //Alert:
    @State var showAlert = false
    @State var alertMessage = ""
    
    //Mostrar la ventana de FeedBackReview
    @State private var sheetShowFeedBackReview: Bool = false
    

    var body: some View {
        NavigationStack {
            ZStack{
                
                 LinearGradient(colors: [Color(red:0.45, green:0.50, blue: 0.50), .orange], startPoint: .top, endPoint: .bottom)
                 .ignoresSafeArea()
                
                if self.canOpenDiario{
                    VStack{
                        VStack{
                            VStack{
                                ScrollView(){
                                    if canOpenDiario {
                                        ForEach(diarioModel.list){ item in
                                            cardItem(diario: item )
                                                .padding(15)
                                                .frame(maxWidth: .infinity)
                                                .foregroundStyle(Color.black)
                                                .background(.white.opacity(0.7))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .shadow(radius: 5)
                                                .padding(.horizontal, 15)
                                                .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }
                            .task{
                              diarioModel.getAllItem()
                            }
                            .scrollIndicators(.hidden)
                        }
                    }
                    
                }else{ //Ventana de Autenticación
                    
                    VStack{
                        Text("El Diario le permite llevar un registro de las actividades y hechos del día. Está protegido y solo usted tiene acceso.")
                            .multilineTextAlignment(.center)
                            .italic()
                            .fontWeight(.heavy)
                            .fontDesign(.serif)
                            .font(.system(size: 25))
                            .foregroundStyle(.black)
                            .padding(15)
                        
                        Button{
                            UtilFuncs.autent(HabilitarContenido: self.$canOpenDiario)
                            
                        }label:{
                            Image(systemName: "key.viewfinder")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.black.opacity(0.7))
                                .symbolEffect(.pulse, isActive: true)
                        }
                    }
                }
            }
            .toolbar{
                HStack(spacing: 5){
                    
                    if canOpenDiario {
                        
                        Menu{
                            Button("Todas las entradas"){withAnimation {
                                diarioModel.getAllItem()}
                            }
                            Button("favoritas"){ diarioModel.list =  diarioModel.filterByFav()}
                            Menu{
                                Button{withAnimation {
                                    diarioModel.list =  diarioModel.filterByEmoticono(criterio: Emociones.feliz.rawValue)
                                }
                                }label: {
                                    Label(Emociones.feliz.rawValue.capitalized, image: Emociones.feliz.rawValue)
                                }
                                Button{withAnimation {
                                    diarioModel.list = diarioModel.filterByEmoticono(criterio: Emociones.neutral.rawValue)
                                }
                                }label: {
                                    Label(Emociones.neutral.rawValue.capitalized, image: Emociones.neutral.rawValue)
                                }
                                Button{ withAnimation {
                                    diarioModel.list = diarioModel.filterByEmoticono(criterio: Emociones.desanimado.rawValue)
                                }
                                }label: {
                                    Label(Emociones.desanimado.rawValue.capitalized, image: Emociones.desanimado.rawValue)
                                }
                                Button{withAnimation {
                                    diarioModel.list = diarioModel.filterByEmoticono(criterio: Emociones.enfado.rawValue)
                                }
                                }label: {
                                    Label(Emociones.enfado.rawValue.capitalized, image: Emociones.enfado.rawValue)
                                }
                                Button{withAnimation {
                                    diarioModel.list = diarioModel.filterByEmoticono(criterio: Emociones.distraido.rawValue)
                                }
                                }label: {
                                    Label(Emociones.distraido.rawValue.capitalized, image: Emociones.distraido.rawValue)
                                }
                                Button{withAnimation {
                                    diarioModel.list = diarioModel.filterByEmoticono(criterio: Emociones.sorpresa.rawValue)
                                }
                                }label: {
                                    Label(Emociones.sorpresa.rawValue.capitalized, image: Emociones.sorpresa.rawValue)
                                }
                            }label: {
                                Text("Por emoción")
                            }
                            Button("Buscar en Títulos"){
                                showAlertFilterByTitles = true
                            }
                            Button("Buscar en Contenido"){
                                showAlertFilterByContent = true
                            }
                            Menu{
                                Button("Fecha"){showFilterByDate = true}
                                Button("Intervalo"){showFilterByIntervalDate = true}
                                Menu{
                                    Button("Semana anterior"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .day, value: -7, to: Date.now) ?? Date.now)
                                    }}
                                    Button("Quincena anterior"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .day, value: -15, to: Date.now) ?? Date.now)
                                    } }
                                    Button("Mes anterior"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .month, value: -1, to: Date.now) ?? Date.now)
                                    }}
                                    Button("Dos meses"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .month, value: -2, to: Date.now) ?? Date.now)
                                    }}
                                    Button("Seis meses"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .month, value: -6, to: Date.now) ?? Date.now)
                                    }}
                                    Button("Un año"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .year, value: -1, to: Date.now) ?? Date.now)
                                    }}
                                    Button("Dos año"){Task{
                                        await calcByIntervalDate(fechaInicial: Calendar.current.date(byAdding: .year, value: -2, to: Date.now) ?? Date.now)
                                    }}
                                }label:{
                                    Text("Sugerencias")
                                }
                                
                                
                            }label:{
                                Text("Fecha de creación")
                            }
                        }label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .tint(.black)
                            
                        }
                        
                        Button(action: {
                            //Nada por aqui
                        }, label: {
                            Menu{
                                Button("Nueva Entrada"){
                                    if  diarioModel.addItem(title: "Título", emocion: .neutral, content: "Nuevo Contenido!") {
                                        withAnimation {
                                             diarioModel.getAllItem()
                                        }
                                        if FeedBackModel.checkReviewRequest() {
                                            self.sheetShowFeedBackReview = true
                                        }
                                    }
                                    
                                    
                                }
                                
                                Menu{
                                    ForEach(0..<titlesExamples.count, id: \.self){ value in
                                        Button(titlesExamples[value].0){
                                            if  diarioModel.addItem(title: titlesExamples[value].0, emocion: diarioModel.getEmocionesFromStr(value: titlesExamples[value].1) , content: "Nuevo contenido!"){
                                                
                                                withAnimation {
                                                    diarioModel.getAllItem()
                                                }
                                                if FeedBackModel.checkReviewRequest() {
                                                    self.sheetShowFeedBackReview = true
                                                }
                                            }
                                            
                                        }
                                    }
                                }label: {
                                    Label("Sugerencias", systemImage: "wand.and.rays")
                                }
                                
                            }label:{
                                Image(systemName: "plus")//"wand.and.rays")
                                    .tint(.black)
                            }
                            
                        })
                        
                    }
                    
                    
                }
            }
            .navigationTitle("Diario")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Filtrar por Título", isPresented: $showAlertFilterByTitles) {
                TextField("", text: $textfielTitles)
                Button("Cancelar"){
                    textfielTitles = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        diarioModel.list = diarioModel.filterByTitle(criterio: textfielTitles)
                    }
                    textfielTitles = ""
                }
                
            }
            .alert("Filtrar por Contenido", isPresented: $showAlertFilterByContent) {
                TextField("", text: $textfielContent)
                Button("Cancelar"){
                    textfielContent = ""
                    dimiss()
                }
                Button("Filtrar"){
                    withAnimation {
                        diarioModel.list = diarioModel.filterByContent(criterio: textfielContent)
                    }
                    
                    textfielContent = ""
                }
            }
            .sheet(isPresented: $showFilterByDate, content: {
                findBydate(typeOfSearch: TypeOfSearch.fix)
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(25)
                    .presentationDragIndicator(.hidden)
            })
            .sheet(isPresented: $showFilterByIntervalDate, content: {
                findBydate(typeOfSearch: TypeOfSearch.interval)
                    .presentationDetents([.height(150)])
                    .presentationCornerRadius(25)
                    .presentationDragIndicator(.hidden)
            })
            .sheet(isPresented: self.$sheetShowFeedBackReview, content: {
                FeedbackView(showTextBotton: true)
            })
            .alert("Diario", isPresented: $showAlert) {
                
            } message: {
                Text(self.alertMessage)
            }
  
         }
    }
    

    
    //View: Filtrar por una fecha dada y por un intervalo:
    struct findBydate : View {

        @State var dateSelection : Date = Date.now
        @State var dateSelection2 : Date = Date.now
        var typeOfSearch : TypeOfSearch = .fix
        @StateObject var diarioModel = DiarioModel.shared
        
        
        var body: some View {
            VStack(spacing: 15){
                HStack(spacing: 10){
                    if typeOfSearch == .fix { //Para fecha fija
                        DatePicker("Fecha", selection: $dateSelection, displayedComponents: .date)
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .opacity(0.8)
                    }else{ //Para intervalo de fecha
                        DatePicker("Fecha inicial", selection: $dateSelection, displayedComponents: .date)
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .opacity(0.8)
                        DatePicker("Fecha final", selection: $dateSelection2, displayedComponents: .date)
                        .labelsHidden()
                        .contentShape(Rectangle())
                        .opacity(0.8)
                    }
                }
                    
                
                    Button("Buscar"){
                        let array = diarioModel.getAllItemGET()
                        var result : [Diario] = []
                        switch typeOfSearch {
                            case .fix:
                                let temp = array.filter { item in
                                    item.fecha?.formatted(date: .long, time: .omitted) == dateSelection.formatted(date: .long, time: .omitted)
                                }
                                if !temp.isEmpty {
                                    diarioModel.list = temp
                                }
                        case .interval:
                            let range = dateSelection...dateSelection2
                            for i in array {
                                if range.contains(i.fecha ?? Date.now + 1){
                                    result.append(i)
                                }
                            }
                            if !result.isEmpty {
                                diarioModel.list = result
                            }
                        }
   
                    }
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 10)
        }
    }
    
    //Función async que devuelve un arreglo de entradas si estan en un intervalo de fecha dado
    func calcByIntervalDate(fechaInicial : Date) async{
        diarioModel.list.removeAll()
        var result : [Diario] = []
        let range = fechaInicial...Date.now
        let array = diarioModel.getAllItemGET()
        for i in array {
            if range.contains(i.fecha ?? Date.now){
                result.append(i)
            }
        }
        if !result.isEmpty {
            diarioModel.list = result
        }
        
    }

}





//Card Item
struct cardItem: View{
    @Environment(\.colorScheme) var theme
    
    @State var diario : Diario //Entrada a mostrar
    
    @StateObject private var diarioModel = DiarioModel.shared
    
    @State private var expandText = false
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
    

    
   private let emociones : [Emociones] = [.neutral,.feliz,.enfado,.desanimado,.distraido,.sorpresa]
    
    
    var body: some View{
        VStack(spacing: 20){
            //EmotioIcon
            HStack{
                Menu{
                    ForEach(0..<6){idx in
                        Button{
                            diarioModel.UpdateEmoticono(emoticono:  emociones[idx], diario: diario)
                            withAnimation {
                                diarioModel.getAllItem()
                            }
                            
                            
                        }label: {
                            Label(emociones[idx].rawValue, image: emociones[idx].rawValue )
                        }
                            
                    }
                    
                    
                }label: {
                    Image(diario.emotion ?? "neutral")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .shadow(radius: 5)
                }
                
                //Título
                Text(diario.title ?? "")
                    .font(.headline).bold()
                    .onTapGesture(count: 2) {
                        showAlert = true
                    }
                Spacer()
            }
            
            
            //Contenido
                Text(diario.content ?? "")
                    .font(.system(size: 18))  
                    #if os(macOS)
                    .foregroundStyle(theme == .dark ? Color.white : Color.black)
                    #endif
                    .italic()
                    .fontDesign(.serif)
                    .fontWeight(.heavy)
                    .lineLimit(expandText ? nil :  3)
                    .onTapGesture{
                        withAnimation {
                            expandText.toggle()
                        }
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
                    Button{
                        isfav.toggle()
                        diarioModel.UpdateFav(isFav: isfav, diario: diario)
                        animValue += 1
                    }label: {
                        Image(systemName: isfav ? "heart.fill" : "heart")
                            .foregroundStyle(isfav ? .orange : .black)
                            .padding(.trailing, 10)
                            .symbolEffect(.bounce, value: animValue)
                    }
                    .onAppear{
                        isfav = diario.isFav
                    }

                    Menu{
                        Button{
                            showSheet.toggle()
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
                            .frame(width: 20, height: 20)
                    
                }
                    
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
                diarioModel.getAllItem()
            }
            
        }
        .alert("¿Desea eliminar la entrada? \n Esta acción no puede deshacerse", isPresented: $showAlertDeleteEntry, actions: {
            Button("Eliminar", role: .destructive){
                withAnimation {
                    diarioModel.DeleteItem(diario: diario)
                    diarioModel.getAllItem()
                }
            }
        })
        .sheet(isPresented: $showSheet){
            editContent(diario: $diario, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral"))
        }
        
    }
}


//View: Editar el contenido de una entrada del diario
struct editContent : View {
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    @StateObject private var diarioModel = DiarioModel.shared
    
    @Binding var diario : Diario
    
    @State  var textTitle : String
    @State  var textContent : String
    @State  var emoticono : Emociones
    
    private let emociones : [Emociones] = [.neutral,.feliz,.enfado,.desanimado,.distraido,.sorpresa]
    
    var body: some View {
        NavigationStack {
            List{
                Section("Título"){
                    HStack(spacing: 5){
                        Menu{
                            ForEach(0..<6){idx in
                                Button{
                                    emoticono = emociones[idx]
                                    
                                }label: {
                                    Label(emociones[idx].rawValue, image: emociones[idx].rawValue )
                                }
                                
                            }
                            
                            
                        }label: {
                            Image(emoticono.rawValue)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50)
                                .shadow(radius: 5)
                        }
                        
                        
                        TextField("", text: $textTitle, axis: .vertical)
                            .font(.title2)
                            .multilineTextAlignment(.leading)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                }
                
                Section("Contenido"){
                    TextField("", text: $textContent, axis: .vertical)
                        .font(.title2)
                        .multilineTextAlignment(.leading)
                        .textFieldStyle(.roundedBorder)
                }
                
            }
            //Al inicio actualiza el icono de emocion
            .foregroundStyle(theme == .dark ? .white : .black)
            .onAppear{
                emoticono = diarioModel.getEmocionesFromStr(value: diario.emotion ?? "neutral")
            }
            .navigationTitle("Modificar Entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("OK"){
                    diarioModel.UpdateItem(diario: diario, title: textTitle, content: textContent, emoticono: emoticono)
                    diarioModel.getAllItem()
                    dimiss()
                }
                .foregroundStyle(theme == .dark ? .white : .black)
            }
        }
    }
}





#Preview {
    DiarioListView()
}



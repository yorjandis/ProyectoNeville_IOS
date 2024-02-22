//
//  DiarioListView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 7/11/23.
//

import SwiftUI
import CoreData
import LocalAuthentication





struct DiarioListView: View {

    @Environment(\.dismiss) var dimiss
    @State  var list : [Diario] = DiarioModel().getAllItem()
    

    
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
    
    //Autenticaxción segura
    let contextLA = LAContext()
    @State var canOpenDiario = false //False, No se puede ver ni agregar entradas al usuario
    
    //Alert:
    @State var showAlert = false
    @State var alertMessage = ""
    
    

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(red:0.45, green:0.50, blue: 0.50), .orange], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView(.vertical){
                    if canOpenDiario {
                        ForEach($list){ item in
                            cardItem(diario: item, list: $list)
                                .padding(15)
                                .frame(maxWidth: .infinity)
                            #if os(iOS)
                                .foregroundStyle(Color.black)
                            #endif
                            #if os(macOS)
                                .foregroundStyle(theme == .dark ?  Color.black : Color.white)
                            #endif
                                .background(.white.opacity(0.7))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(radius: 5)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 8)
                        }
                        
                    } 
                }
                .task{
                    list = DiarioModel().getAllItem()
                }
                .scrollIndicators(.hidden)
                .navigationTitle("Diario")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar{
                    HStack(spacing: 5){
                        
                        if canOpenDiario {
                            
                            Menu{
                                Button("Todas las entradas"){withAnimation {
                                    list.removeAll(); list = DiarioModel().getAllItem()}
                                }
                                Button("favoritas"){list.removeAll(); list = DiarioModel().filterByFav()}
                                Menu{
                                    Button{withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.feliz.rawValue)
                                    }
                                    }label: {
                                        Label(Emociones.feliz.rawValue.capitalized, image: Emociones.feliz.rawValue)
                                    }
                                    Button{withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.neutral.rawValue)
                                    }
                                    }label: {
                                        Label(Emociones.neutral.rawValue.capitalized, image: Emociones.neutral.rawValue)
                                    }
                                    Button{ withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.desanimado.rawValue)
                                    }
                                    }label: {
                                        Label(Emociones.desanimado.rawValue.capitalized, image: Emociones.desanimado.rawValue)
                                    }
                                    Button{withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.enfado.rawValue)
                                    }
                                    }label: {
                                        Label(Emociones.enfado.rawValue.capitalized, image: Emociones.enfado.rawValue)
                                    }
                                    Button{withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.distraido.rawValue)
                                    }
                                    }label: {
                                        Label(Emociones.distraido.rawValue.capitalized, image: Emociones.distraido.rawValue)
                                    }
                                    Button{withAnimation {
                                        list.removeAll() ; list = DiarioModel().filterByEmoticono(criterio: Emociones.sorpresa.rawValue)
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
                                        DiarioModel().addItem(title: "Título", emocion: .neutral, content: "Nuevo Contenido!")
                                        withAnimation {
                                            list.removeAll()
                                            list = DiarioModel().getAllItem()
                                        }
                                        
                                    }
                                    
                                    Menu{
                                        ForEach(0..<titlesExamples.count, id: \.self){ value in
                                            Button(titlesExamples[value].0){
                                                DiarioModel().addItem(title: titlesExamples[value].0, emocion: DiarioModel().getEmocionesFromStr(value: titlesExamples[value].1) , content: "Nuevo contenido!")
                                                withAnimation {
                                                    list.removeAll()
                                                    list = DiarioModel().getAllItem()
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
                .alert("Filtrar por Título", isPresented: $showAlertFilterByTitles) {
                    TextField("", text: $textfielTitles)
                    Button("Cancelar"){
                        textfielTitles = ""
                        dimiss()
                    }
                    Button("Filtrar"){
                        withAnimation {
                            list.removeAll()
                            list = DiarioModel().filterByTitle(criterio: textfielTitles)
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
                            list.removeAll()
                            list = DiarioModel().filterByContent(criterio: textfielContent)
                        }
                        
                        textfielContent = ""
                    }
                }
                .sheet(isPresented: $showFilterByDate, content: {
                    findBydate(lista: $list, typeOfSearch: TypeOfSearch.fix)
                        .presentationDetents([.height(150)])
                        .presentationCornerRadius(25)
                        .presentationDragIndicator(.hidden)
                })
                .sheet(isPresented: $showFilterByIntervalDate, content: {
                    findBydate(lista: $list, typeOfSearch: TypeOfSearch.interval)
                        .presentationDetents([.height(150)])
                        .presentationCornerRadius(25)
                        .presentationDragIndicator(.hidden)
                })
                .alert("Diario", isPresented: $showAlert) {
                    
                } message: {
                    Text(self.alertMessage)
                }


                    
            }
            .overlay {
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
                        autent()
                    }label:{
                        Image(systemName: "key.viewfinder")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.black.opacity(0.7))
                            .symbolEffect(.pulse, isActive: true)
                    }
                    }
                .opacity(canOpenDiario ? 0 : 1)
                
            }

        }
        
    }
    
    func autent(){
        var error : NSError?
        if contextLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error){
            
            contextLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Por favor autentícate para tener acceso a su Diario") { success, error in
                        if success {
                             //Habilitación del contenido
                            withAnimation {
                                canOpenDiario = true
                            }
                            
                        } else {
                            print("Error en la autenticación biométrica")
                        }
                    }
            
            
        }else{
            alertMessage = "El dispositivo no soporta autenticación Biométrica. Se ha deshabilitado la protección del Diario"
            showAlert = true
            canOpenDiario = true //Deshabilitando la protección del Diario.
        }
    }
    
    //View: Filtrar por una fecha dada y por un intervalo:
    struct findBydate : View {

        @State var dateSelection : Date = Date.now
        @State var dateSelection2 : Date = Date.now
        @Binding var lista : [Diario]
        var typeOfSearch : TypeOfSearch = .fix
        
        
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
                        lista.removeAll()
                        let array = DiarioModel().getAllItem()
                        var result = [Diario]()
                        switch typeOfSearch {
                            case .fix:
                                let temp = array.filter { item in
                                    item.fecha?.formatted(date: .long, time: .omitted) == dateSelection.formatted(date: .long, time: .omitted)
                                }
                                if !temp.isEmpty {
                                    lista = temp
                                }
                        case .interval:
                            let range = dateSelection...dateSelection2
                            for i in array {
                                if range.contains(i.fecha ?? Date.now + 1){
                                    result.append(i)
                                }
                            }
                            if !result.isEmpty {
                                lista = result
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
        self.list.removeAll()
        var result = [Diario]()
        let range = fechaInicial...Date.now
        let array = DiarioModel().getAllItem()
        for i in array {
            if range.contains(i.fecha ?? Date.now){
                result.append(i)
            }
        }
        if !result.isEmpty {
            self.list = result
        }
        
    }
    
}


//Card Item
struct cardItem: View{
    @Environment(\.colorScheme) var theme
    @Binding var diario : Diario
    @Binding var list : [Diario]
    
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
                            DiarioModel().UpdateEmoticono(emoticono:  emociones[idx], diario: diario)
                            withAnimation {
                                list.removeAll()
                                list = DiarioModel().getAllItem()
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
                        DiarioModel().UpdateFav(isFav: isfav, diario: diario)
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
                DiarioModel().UpdateTitle(title: title, diario: diario)
                list.removeAll()
                list = DiarioModel().getAllItem()
            }
            
        }
        .alert("¿Desea eliminar la entrada? \n Esta acción no puede deshacerse", isPresented: $showAlertDeleteEntry, actions: {
            Button("Eliminar", role: .destructive){
                withAnimation {
                    DiarioModel().DeleteItem(diario: diario)
                    list.removeAll()
                    list = DiarioModel().getAllItem()
                }
            }
        })
        .sheet(isPresented: $showSheet){
            editContent(diario: $diario, list: $list, textTitle:diario.title ?? "", textContent: diario.content ?? "", emoticono: DiarioModel().getEmocionesFromStr(value: diario.emotion ?? "neutral"))
        }
        
    }
}


//View: Editar el contenido de una entrada del diario
struct editContent : View {
    @Environment(\.dismiss) var dimiss
    @Environment(\.colorScheme) var theme
    
    @Binding var diario : Diario
    @Binding var list : [Diario]
    
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
                emoticono = DiarioModel().getEmocionesFromStr(value: diario.emotion ?? "neutral")
            }
            .navigationTitle("Modificar Entrada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar{
                Button("OK"){
                    DiarioModel().UpdateItem(diario: diario, title: textTitle, content: textContent, emoticono: emoticono)
                    list.removeAll()
                    list = DiarioModel().getAllItem()
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



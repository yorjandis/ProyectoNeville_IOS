//
//  FilterByDiarioView.swift
//  La Ley Watch App
//
//  Created by Yorjandis Garcia on 9/2/24.
//

import SwiftUI
import CloudKit

struct FilterByDiarioView: View {
    
    @Binding var listRecord : [CKRecord] //Permite actualizar el listado original
    @Binding var showListOptions : Bool //permite cerrar la ventana de opciones de filtro
    @State private var showSheetTitulo      = false
    @State private var showSheetTexto       = false
    @State private var showSheetEmocion     = false
    @State private var showSheetFecha       = false
    @State private var showSheetRangoFecha  = false
    @State private var showSheetAntiguedad  = false
    @State private var fecha1 = Date.now
    @State private var fecha2 = Date.now
    
    
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
                    self.listRecord.removeAll()
                    Task{
                        self.listRecord = await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .favoritoDiario)
                        showListOptions = false
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
            VStack{
                TextFieldLink("🔍 Título a buscar",prompt: Text("Texto de la entrada")) { str in
                    listRecord.removeAll()
                    Task{
                        listRecord =  await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .tituloDiario, textoABuscar: str)
                        self.showSheetTitulo = false
                        self.showListOptions = false
                    }
                }
            }
            
        }
        .sheet(isPresented: $showSheetTexto){
            VStack{
                TextFieldLink("🔍 Contenido a buscar",prompt: Text("Contenido de la entrada")) { str in
                    listRecord.removeAll()
                    Task{
                        listRecord =  await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .contenidoDiario, textoABuscar: str)
                        self.showSheetTitulo = false
                        self.showListOptions = false
                    }
                }
            }
            
        }
        .sheet(isPresented: $showSheetFecha){
            VStack{
                DatePicker("Fecha de creación", selection: $fecha1, displayedComponents: [.date])
                    .padding(.top, 50)
                Button{
                    showSheetFecha = false
                    showListOptions = false
                    Task{
                        self.listRecord.removeAll()
                        self.listRecord = await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .fechaDiario, fecha1: self.fecha1)
                        
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
                    showSheetFecha = false
                    showListOptions = false
                    Task{
                        self.listRecord.removeAll()
                        self.listRecord = await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .rangoFechaDiario, fecha1: self.fecha1, fecha2: self.fecha2)
                        
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
        .sheet(isPresented: $showSheetEmocion){
            VStack{
                
                ScrollView{
                    ForEach (Emoticono2.allCases, id: \.self) {item in
                        Button{
                            self.listRecord.removeAll()
                            self.showSheetEmocion = false
                            self.showListOptions = false
                            Task{
                                self.listRecord = await iCloudKitModel(of: .BDPrivada).filterByCriterio(tableName: .CD_Diario, criterio: .emocionDiario, textoABuscar: item.txt)
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
        .sheet(isPresented: $showSheetAntiguedad){
            VStack {
                Text("Filtrar por antiguedad")
                Divider()
                ScrollView{
                    Button("Tres días atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .tresDias)
                        }
                    }
                    Button("Semana pasada"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .semana)
                        }
                    }
                    Button("Quicena pasada"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .quincena)
                        }
                    }
                    Button("Mes anterior"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .mes)
                        }
                    }
                    Button("Dos meses atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .dosMeses)
                        }
                    }
                    Button("Tres meses atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .tresMeses)

                        }
                    }
                    Button("Seis meses atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .seisMeses)
                        }
                    }
                    Button("Un año atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .unAno)
                        }
                    }
                    Button("Dos año atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .dosAnos)
                        }
                    }
                    Button("Tres año atrás"){
                        Task{
                            self.listRecord.removeAll()
                            self.showSheetAntiguedad    = false
                            self.showListOptions        = false
                            self.listRecord = await getListForAntiquity(antiguedad: .tresAnos)
                        }
                    }
                }
            }
        }
        
    }
    
    enum Emoticono2:String, CaseIterable{
        case feliz = "😃", neutral = "🙂", enfadado = "😤", sorpresa = "😲", distraido = "🙄",desanimado = "😔"
        var txt : String{
            switch self{
            case .desanimado : "desanimado"
            case .distraido : "distraido"
            case .enfadado : "enfadado"
            case .feliz : "feliz"
            case .neutral : "neutral"
            case .sorpresa : "sorpresa"
            }
        }
    }
    
    enum Antiguedad : String{
        case tresDias, semana, quincena, mes, dosMeses, tresMeses, seisMeses, unAno, dosAnos, tresAnos
    }
    
    //Para filtro de Antiguedad: Funcion que devuelve la lista de elementos para filtro de antiguedad
    func getListForAntiquity(antiguedad : Antiguedad)async -> [CKRecord]{
        var result = [CKRecord]()
        
        let allRecords = await iCloudKitModel(of: .BDPrivada).getRecords(tableName: .CD_Diario)
        var rango : ClosedRange<Date>
        switch antiguedad {
        case .tresDias:
            rango = Calendar.current.date(byAdding: .day, value: -3, to: Date())!...Date.now
        case .semana:
            rango = Calendar.current.date(byAdding: .day, value: -7, to: Date())!...Date.now
        case .quincena:
            rango = Calendar.current.date(byAdding: .day, value: -15, to: Date())!...Date.now
        case .mes:
            rango = Calendar.current.date(byAdding: .month, value: -1, to: Date())!...Date.now
        case .dosMeses:
            rango = Calendar.current.date(byAdding: .month, value: -2, to: Date())!...Date.now
        case .tresMeses:
            rango = Calendar.current.date(byAdding: .month, value: -3, to: Date())!...Date.now
        case .seisMeses:
            rango = Calendar.current.date(byAdding: .month, value: -6, to: Date())!...Date.now
        case .unAno:
            rango = Calendar.current.date(byAdding: .year, value: -1, to: Date())!...Date.now
        case .dosAnos:
            rango = Calendar.current.date(byAdding: .year, value: -2, to: Date())!...Date.now
        case .tresAnos:
            rango = Calendar.current.date(byAdding: .year, value: -3, to: Date())!...Date.now
        }

            for i in allRecords{
                let fecha = i.value(forKey: TDiario.CD_fecha.txt) as? Date ?? Date.now
                if rango.contains(fecha){
                    result.append(i)
                }
            }
        return result
    }
}

#Preview {
    FilterByDiarioView(listRecord: .constant([CKRecord]()), showListOptions: .constant(false))
}

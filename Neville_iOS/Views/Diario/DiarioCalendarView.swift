//
//  CalendarView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/25.
//
//Construye un calendario donde serán seleccionado los días en que hay entradas de cierto tipo en Core Data (Entradas del Diario)

import UIKit
import SwiftUI
import CoreData

struct DiarioCalendarView: View {
    
    @StateObject private var modeloDiario = DiarioModel.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Diario.fecha, ascending: true)],
        animation: .default
    ) private var entradas: FetchedResults<Diario>
    
    @State private var currentMonth: Date = Date()
    
    @State private var hideCalendar: Bool = false //Oculta el calendario pero deja la cabezera
    
    // Closure que se ejecutará cuando se seleccione una fecha con entrada
    var onDateSelected: (Date) -> Void
    
    // Extraer solo los días con entradas en formato de fecha sin horas
    private var fechasDeEntradas: Set<Date> {
        Set(entradas.compactMap { $0.fecha?.startOfDay() })
    }
    
    var body: some View {
        VStack {
            // Controles de Navegación de Mes
            HStack {
                //Para ocultar o mostrar el calendario
                Button{
                    withAnimation {
                        self.hideCalendar.toggle()
                    }
                    
                }label:{
                    Image(systemName:  self.hideCalendar ?  "eye" : "eye.slash")
                        .tint(.black)
                }
                
                Spacer()
                
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .padding()
                
                // Reemplazar el texto por un selector de fecha
                DatePicker("", selection: $currentMonth, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(width: 120) // Ajustar el ancho según sea necesario
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .padding()
                
                Spacer()
                
                //Para fijar la fecha actual
                Button{
                    self.currentMonth = Date()
                    self.modeloDiario.getAllItem()
                }label: {
                    Image(systemName: "diamond.circle.fill")
                        .tint(.black)
                }
                
            }
            if !self.hideCalendar {
                CalendarGrid(
                    currentMonth: $currentMonth,
                    fechasResaltadas: fechasDeEntradas,
                    onDateSelected: onDateSelected
                )
                .onAppear{
                    //Al Aparecer carga las entradas para la fecha dada
                    modeloDiario.list = modeloDiario.getEntriesByMonth(forDate: self.currentMonth)
                }
            }
            
        }
        .padding()
        .onChange(of: self.currentMonth) { oldValue, newValue in
                //Carga las entradas para ese mes
                modeloDiario.list = modeloDiario.getEntriesByMonth(forDate: newValue)
            
        }
    }
    
    // Cambia el mes actual sumando o restando 1 mes
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

//Crea la estructura del calendario
struct CalendarGrid: View {
    @Binding var currentMonth: Date
    var fechasResaltadas: Set<Date>
    var onDateSelected: (Date) -> Void
    @StateObject private var modelDiario = DiarioModel.shared
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        let days = generateDaysInMonth(for: currentMonth)
        
        LazyVGrid(columns: columns) {
            ForEach(days, id: \.self) { day in
                if let date = day {
                    let isHighlighted = fechasResaltadas.contains(date)
                    
                    Text(date.formatted(.dateTime.day()))
                        .frame(width: 45, height: 45)
                        .background(isHighlighted ? Color.black.opacity(0.6) : Color.clear)
                        .clipShape(Circle())
                        .foregroundColor(isHighlighted ? .white : .primary)
                        .overlay{
                            //Poner una etiqueta con el número de entradas
                            if isHighlighted {
                                ZStack{
                                    Text("\(modelDiario.searchPorFecha(for: date, typeFecha: .FechaCreacion).count)")
                                        .font(.footnote)
                                        .foregroundStyle(Color.orange)
                                        .bold()
                                        .offset(x: 0 , y: +15 )
                                }
                            }
                        }
                        .onTapGesture {
                            if isHighlighted {
                                onDateSelected(date)
                            }
                        }
                } else {
                    Text("")
                        .frame(width: 40, height: 40)
                }
            }
        }
    }
    
    // Genera los días en un mes, incluyendo los espacios vacíos del primer día
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1) // Espacios vacíos para el inicio del mes
        days += range.map { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        
        return days
    }
    

}

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

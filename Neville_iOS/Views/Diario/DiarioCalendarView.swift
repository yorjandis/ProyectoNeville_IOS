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
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Diario.fecha, ascending: true)],
        animation: .default
    ) private var entradas: FetchedResults<Diario>
    
    @State private var currentMonth: Date = Date()
    
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
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                }
                .padding()
                
                Text(currentMonth.formatted(.dateTime.year().month()))
                    .font(.title)
                    .bold()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                }
                .padding()
            }
            
            CalendarGrid(
                currentMonth: $currentMonth,
                fechasResaltadas: fechasDeEntradas,
                onDateSelected: onDateSelected
            )
        }
        .padding()
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
    
    /*
     //NO utilizado
    //Sencillamente resta un dia a una fecha y devuelve el resultado
    private func SumaUnDia(date: Date) -> Date {
        let tempDate = Calendar.current.date(byAdding: .day, value: +1, to: date)!
        return tempDate
    }
    */
}

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

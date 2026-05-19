//
//  CalendarView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/25.
//
//Construye un calendario donde serán seleccionado los días en que hay entradas de cierto tipo en Core Data (Entradas del Diario)
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

import SwiftUI
import CoreData



//Vista del calendario

struct DiarioCalendarView: View {
    

    @StateObject var modeloDiario : DiarioModel = DiarioModel.shared
    
    @State private var currentMonth: Date = Date()
    
    @State private var hideCalendar: Bool = false //Oculta el calendario pero deja la cabezera
    @State private var fechasDeEntradas: Set<Date> = []
    @State private var conteoEntradasPorDia: [Date: Int] = [:]
    @State private var shouldSelectDayFromDatePicker: Bool = false
    @State private var selectedDay: Date? = nil
    
    var refreshTrigger: Int
    var onMonthEntriesLoaded: (Date) -> Void = { _ in }
    var onRequestCreateEntry: (Date) -> Void = { _ in }
    // Closure que se ejecutará cuando se seleccione una fecha
    var onDateSelected: (Date) -> Void
    
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
                DatePicker("", selection: datePickerSelection, displayedComponents: [.date])
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
                    fechasResaltadas: $fechasDeEntradas,
                    entryCountsByDay: $conteoEntradasPorDia,
                    selectedDay: $selectedDay,
                    onRequestCreateEntry: onRequestCreateEntry,
                    onDateSelected: onDateSelected
                )
                .onAppear{
                    reloadMonthData(for: self.currentMonth)
                }
            }
            
        }
        .padding()
        .onChange(of: self.currentMonth) { oldValue, newValue in
            reloadMonthData(for: newValue)
            if shouldSelectDayFromDatePicker {
                selectEntriesForDatePickerSelection(newValue)
                shouldSelectDayFromDatePicker = false
            } else {
                selectedDay = nil
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            reloadMonthData(for: currentMonth, preserveSelectedDay: true)
        }
    }

    private var datePickerSelection: Binding<Date> {
        Binding(
            get: { currentMonth },
            set: { newValue in
                currentMonth = newValue
                shouldSelectDayFromDatePicker = true
            }
        )
    }
    
    // Cambia el mes actual sumando o restando 1 mes
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func reloadMonthData(for date: Date, preserveSelectedDay: Bool = false) {
        let entries = modeloDiario.getEntriesByMonth(forDate: date)
        let calendar = Calendar.current
        let normalizedDays = entries.compactMap { $0.fecha }.map { calendar.startOfDay(for: $0) }
        fechasDeEntradas = Set(normalizedDays)
        conteoEntradasPorDia = Dictionary(grouping: normalizedDays, by: { $0 }).mapValues(\.count)

        if preserveSelectedDay, let selectedDay {
            let normalizedSelectedDay = calendar.startOfDay(for: selectedDay)
            if calendar.isDate(normalizedSelectedDay, equalTo: date, toGranularity: .month) {
                onDateSelected(normalizedSelectedDay)
                return
            } else {
                self.selectedDay = nil
            }
        }

        modeloDiario.list = entries
        onMonthEntriesLoaded(date)
    }

    private func selectEntriesForDatePickerSelection(_ date: Date) {
        let selectedDay = Calendar.current.startOfDay(for: date)
        self.selectedDay = selectedDay
        onDateSelected(selectedDay)
    }
}

//Crea la estructura del calendario
struct CalendarGrid: View {
    @Binding var currentMonth: Date
    @Binding var fechasResaltadas: Set<Date>
    @Binding var entryCountsByDay: [Date: Int]
    @Binding var selectedDay: Date?
    var onRequestCreateEntry: (Date) -> Void
    var onDateSelected: (Date) -> Void

    @State private var showFutureDateAlert: Bool = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        let days = generateDaysInMonth(for: currentMonth)
        
        // ⚙️ Aquí defines el color compatible con ambas plataformas
                #if os(macOS)
                let highlightColor = Color(NSColor(calibratedWhite: 0, alpha: 0.6))
                #else
                let highlightColor = Color(UIColor(white: 0, alpha: 0.6))
                #endif
        
        LazyVGrid(columns: columns) {
            ForEach(days.indices, id: \.self) { index in
                if let date = days[index] {
                    let calendar = Calendar.current
                    let isHighlighted = fechasResaltadas.contains(date)
                    let entryCount = entryCountsByDay[date] ?? 0
                    let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let today = calendar.startOfDay(for: Date.now)
                    let isFutureDay = calendar.startOfDay(for: date) > today

                    Text(date.formatted(.dateTime.day()))
                        .frame(width: 45, height: 45)
                        .background(
                            Circle()
                                .fill(isHighlighted ? highlightColor : Color.clear)
                        )
                        .foregroundColor(isHighlighted ? .white : (isFutureDay ? .secondary : .primary))
                        .opacity(isFutureDay ? 0.45 : 1)
                        .overlay {
                            Circle()
                                .stroke(
                                    isSelected ? Color.black : Color.clear,
                                    style: StrokeStyle(
                                        lineWidth: 3,
                                        dash: [2, 4] // patrón de puntos
                                    )
                                )
                                .frame(width: 50, height: 50)
                        }
                        .overlay {
                            if isHighlighted {
                                Text("\(entryCount)")
                                    .font(.footnote)
                                    .foregroundStyle(Color.orange)
                                    .bold()
                                    .offset(y: +15)
                            }
                        }
                        .onTapGesture(count: 2) {
                            let calendar = Calendar.current
                            let normalizedSelectedDay = calendar.startOfDay(for: date)
                            let today = calendar.startOfDay(for: Date.now)

                            guard normalizedSelectedDay <= today else {
                                showFutureDateAlert = true
                                return
                            }

                            selectedDay = normalizedSelectedDay
                            onRequestCreateEntry(normalizedSelectedDay)
                        }
                        .onTapGesture {
                            let normalizedSelectedDay = Calendar.current.startOfDay(for: date)
                            selectedDay = normalizedSelectedDay
                            onDateSelected(normalizedSelectedDay)
                        }
                } else {
                    Text("")
                        .frame(width: 40, height: 40)
                }
            }
        }
        .alert("Fecha no válida", isPresented: $showFutureDateAlert) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("No se puede crear una entrada en una fecha futura.")
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

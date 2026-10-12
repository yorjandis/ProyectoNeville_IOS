//
//  CalendarView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 18/2/25.
//
//Construye un calendario donde serán seleccionado los días en que hay entradas de cierto tipo en Core Data (Entradas del Diario)
import SwiftUI
import CoreData



//Vista del calendario

struct DiarioCalendarView: View {
    

    @StateObject var modeloDiario : DiarioModel = DiarioModel.shared
    
    @State private var currentMonth: Date = Date()
    
    @State private var hideCalendar: Bool = false //Oculta el calendario pero deja la cabezera
    @State private var fechasDeEntradas: Set<Date> = []
    @State private var shouldSelectDayFromDatePicker: Bool = false
    @State private var selectedDay: Date? = nil
    
    var refreshTrigger: Int
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
                }label: {
                    Image(systemName: "diamond.circle.fill")
                        .tint(.black)
                }
                
            }
            if !self.hideCalendar {
                CalendarGrid(
                    currentMonth: $currentMonth,
                    fechasResaltadas: $fechasDeEntradas,
                    selectedDay: $selectedDay,
                    onRequestCreateEntry: onRequestCreateEntry,
                    onDateSelected: onDateSelected
                )
                .onAppear{
                    reloadMonthData(
                        for: self.currentMonth,
                        preserveSelectedDay: selectedDay != nil
                    )
                }
            }
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.94, blue: 0.80),
                            Color(red: 0.99, green: 0.88, blue: 0.70)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(red: 0.61, green: 0.39, blue: 0.25).opacity(0.18), lineWidth: 1)
                }
        }
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

        if preserveSelectedDay, let selectedDay {
            let normalizedSelectedDay = calendar.startOfDay(for: selectedDay)
            if calendar.isDate(normalizedSelectedDay, equalTo: date, toGranularity: .month) {
                onDateSelected(normalizedSelectedDay)
                return
            } else {
                self.selectedDay = nil
            }
        }

        // Cargar los indicadores del calendario nunca debe modificar el filtro
        // ni el listado de entradas activo. Solo la selección explícita de un
        // día, mediante `onDateSelected`, puede cambiar ese listado.
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
    @Binding var selectedDay: Date?
    var onRequestCreateEntry: (Date) -> Void
    var onDateSelected: (Date) -> Void

    @State private var showFutureDateAlert: Bool = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        let days = generateDaysInMonth(for: currentMonth)
        
        let highlightColor = Color(red: 0.58, green: 0.70, blue: 0.46).opacity(0.78)
        
        VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.16))
                        .frame(width: 38, height: 20)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days.indices, id: \.self) { index in
                    if let date = days[index] {
                        let calendar = Calendar.current
                        let isHighlighted = fechasResaltadas.contains(date)
                        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        let isToday = calendar.isDateInToday(date)
                        let today = calendar.startOfDay(for: Date.now)
                        let isFutureDay = calendar.startOfDay(for: date) > today
                        let todayTextColor = Color(red: 0.45, green: 0.22, blue: 0.08)
                        let selectedBackgroundColor = Color(red: 0.80, green: 0.62, blue: 0.48)
                        let dayTextColor = isToday
                            ? todayTextColor
                            : Color(red: 0.18, green: 0.14, blue: 0.10)

                        Text(date.formatted(.dateTime.day()))
                            .font(.body.weight(.bold))
                            .frame(width: 38, height: 38)
                            .background(
                                Circle()
                                    .fill(
                                        isSelected
                                            ? selectedBackgroundColor
                                            : (isHighlighted && !isToday ? highlightColor : Color.clear)
                                    )
                            )
                            .foregroundStyle(dayTextColor)
                            .fontWeight(isToday ? .heavy : .bold)
                            .opacity(isFutureDay ? 0.45 : 1)
                            .overlay {
                                Circle()
                                    .stroke(
                                        isSelected
                                            ? Color(red: 0.52, green: 0.30, blue: 0.20)
                                            : Color.clear,
                                        style: StrokeStyle(
                                            lineWidth: 2
                                        )
                                    )
                                    .frame(width: 42, height: 42)
                            }
                            .contentShape(Rectangle())
                            .gesture(dayTapGesture(for: date))
                    } else {
                        Text("")
                            .frame(width: 38, height: 38)
                    }
                }
            }
        }
        .alert("Fecha no válida", isPresented: $showFutureDateAlert) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("No se puede crear una entrada en una fecha futura.")
        }
    }

    private func dayTapGesture(for date: Date) -> some Gesture {
        TapGesture(count: 2)
            .exclusively(before: TapGesture(count: 1))
            .onEnded { gesture in
                switch gesture {
                case .first:
                    requestEntryCreation(for: date)
                case .second:
                    selectEntries(for: date)
                }
            }
    }

    private func selectEntries(for date: Date) {
        let normalizedSelectedDay = Calendar.current.startOfDay(for: date)
        selectedDay = normalizedSelectedDay
        onDateSelected(normalizedSelectedDay)
    }

    private func requestEntryCreation(for date: Date) {
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

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekdayIndex = calendar.firstWeekday - 1

        return Array(symbols[firstWeekdayIndex...]) + Array(symbols[..<firstWeekdayIndex])
    }
    
    // Genera los días en un mes, incluyendo los espacios vacíos del primer día
    private func generateDaysInMonth(for date: Date) -> [Date?] {
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays) // Espacios vacíos para el inicio del mes
        days += range.map { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        
        return days
    }
    

}

extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview("Diario Calendar") {
    DiarioCalendarView(refreshTrigger: 0) { _ in }
}

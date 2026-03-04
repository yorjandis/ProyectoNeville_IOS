//
//  ReminderEditorView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/12/25.
//




import SwiftUI

// UI Mode Enum
enum ReminderEditorMode: String, CaseIterable, Identifiable {
    case interval   = "Intervalo"
    case daily      = "Diario"
    case date       = "Fecha"
    case monthly    = "Mensual"
    case yearly     = "Anual"

    var id: String { rawValue }
}

struct ReminderEditorView: View {

    let reminderAEditar: StoredReminder?   // Si es dado: edita un recordatorio
    let titleAImportar: String?     //Título del elemento importado (frase, nota)
    let textoAImportar: String?     //Texto del elemento importado (frase, nota)
    let onSave: () -> Void          // Closure al guardar

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var theme

    @State private var title = ""
    @State private var message = ""

    // Modo de edición
    @State private var mode: ReminderEditorMode = .interval

    // Intervalo
    @State private var selectedTime = Time(hour: 0, minute: 5)

    // Diario
    @State private var dailyTime = Date()

    // Fecha definida
    @State private var selectedDate = Date()
    
    //Mensual:
    @State private var monthlyDate = Date()
    
    //Anual:
    @State private var yearlyDate = Date()
    

    // Alertas
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    //Tonos:
    @State private var selectedSound: NotificationSound = .selected

    var body: some View {
        NavigationStack{
            if (self.purchaseStatus || self.yorjPremium) {
                VStack{
                    #if os(macOS)
                    
                    VStack(alignment: .leading){
                        // Contenido
                        Section("Recordatorio") {
                            TextField("Título", text: $title, axis: .vertical)
                                .font(.system(size: 22))
                                .foregroundStyle(.orange)
                                .bold()
                                .padding()

                            TextEditor(text: $message)
                                .font(.system(size: 22))
                                .foregroundStyle(self.theme == .dark ? Color.white : Color.black)
                                .padding(7)
                                .frame(minHeight: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                                
                        }

                        // Frecuencia
                        Section("Frecuencia") {
                            Picker("Tipo", selection: $mode) {
                                ForEach(ReminderEditorMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Selector según modo
                        VStack{
                            switch mode {

                            case .interval:
                                intervalSection
                                    .contentShape(Rectangle())
                                #if os(iOS)
                                    .onTapGesture { hideKeyboard() }
                                #endif

                            case .daily:
                                dailySection
                                    .contentShape(Rectangle())
                                    #if os(iOS)
                                    .onTapGesture { hideKeyboard() }
                                    #endif

                            case .date:
                                dateSection
                                    .contentShape(Rectangle())
                                    #if os(iOS)
                                    .onTapGesture { hideKeyboard() }
                                    #endif
                                
                            case .monthly:
                                monthlySection
                                    .contentShape(Rectangle())
                                    #if os(iOS)
                                    .onTapGesture { hideKeyboard() }
                                    #endif
                                
                            case .yearly:
                                yearlySection
                                    .contentShape(Rectangle())
                                    #if os(iOS)
                                    .onTapGesture { hideKeyboard() }
                                    #endif
                            }
                            Spacer()
                        }
                        
                        .frame(height: 200)
                       
                    

                        // Guardar
                        HStack {
                            #if os(macOS)
                            Button("Cerrar"){
                                dismiss()
                            }
                            .tint(.red)
                            .buttonStyle(.borderedProminent)
                            #endif
                            Spacer()
                            Button(mode == .date ? "Programar" : "Guardar") {
                                save()
                            }
                            .tint(.orange)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    //.foregroundStyle(.black)
                    .padding()
                    .frame(width: 500, height: 550, alignment: .leading)
                    .background{
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.55, blue: 0.55).opacity(0.4),
                                        Color.gray.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .cornerRadius(20)
                    
                    #else
                    Form {
                        // Contenido
                        Section("Recordatorio") {
                            TextField("Título", text: $title, axis: .vertical)
                                .font(.system(size: 22))
                                .foregroundStyle(.orange)
                                .bold()
                                .padding()

                            TextField("Contenido", text: $message, axis: .vertical)
                                .font(.system(size: 22))
                                .foregroundStyle(self.theme == .dark ? Color.white : Color.black)
                                .padding()
                                .frame(minHeight: 100)
                        }

                        // Frecuencia
                        Section("Frecuencia") {
                            Picker("Tipo", selection: $mode) {
                                ForEach(ReminderEditorMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Selector según modo
                        switch mode {

                        case .interval:
                            intervalSection
                                .contentShape(Rectangle())
                            #if os(iOS)
                                .onTapGesture { hideKeyboard() }
                            #endif

                        case .daily:
                            dailySection
                                .contentShape(Rectangle())
                                #if os(iOS)
                                .onTapGesture { hideKeyboard() }
                                #endif

                        case .date:
                            dateSection
                                .contentShape(Rectangle())
                                #if os(iOS)
                                .onTapGesture { hideKeyboard() }
                                #endif
                            
                        case .monthly:
                            monthlySection
                                .contentShape(Rectangle())
                                #if os(iOS)
                                .onTapGesture { hideKeyboard() }
                                #endif
                            
                        case .yearly:
                            yearlySection
                                .contentShape(Rectangle())
                                #if os(iOS)
                                .onTapGesture { hideKeyboard() }
                                #endif
                        }
                    
                        //Guardar
                        HStack {
                            Spacer()
                            Button(mode == .date ? "Programar" : "Guardar") {
                                save()
                            }
                            .tint(.orange)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    #endif
                    
                }
               
                .padding()
                .navigationTitle(reminderAEditar == nil ? "Nuevo recordatorio" : "Editar")
                .onAppear {
                    loadExisting()
                    if let title = self.titleAImportar {
                        self.title = title
                    }
                    if let texto = self.textoAImportar{
                        self.message = texto
                    }
                    
                }
                .onChange(of: selectedSound) { _,_ in
                    //Para detener la reproducción del tono si se cambia a otro tono
                        NotificationSoundPreview.shared.stop()
                    }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("La ley"),
                        message: Text(alertMessage)
                    )
                }
                
                
            }else{
                PurchaseView()
            }
        }
        
    }

    // Secciones

    private var intervalSection: some View {
        VStack(spacing: 5){
            Text("Repetir cada")
                .padding(.bottom, 10)

            TimePickerWheel(time: $selectedTime)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    private var dailySection: some View {
        VStack{
            DatePicker(
                "Cada día, a esta hora:",
                selection: $dailyTime,
                displayedComponents: .hourAndMinute
            )
            .font(.system(size: 18))
        }
        .padding()
        
    }

    private var dateSection: some View {
        VStack{
            DatePicker(
                "En una fecha dada:",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.system(size: 18))
        }
        .padding()
        
    }
    
    private var monthlySection: some View {
        VStack(spacing: 5) {
            DatePicker(
                "Cada mes en esta fecha:",
                selection: $monthlyDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.system(size: 18))

            Text("Tenga en cuenta que este recordatorio será omitido los meses que no tengan el día seleccionado. Por ejemplo, si selecciona día 30, en febrero no se activará el recordatorio.")
            #if os(macOS)
                .font(.system(size: 18))
            #else
                .font(.footnote)
            
            #endif
                .foregroundStyle(.secondary)
                .padding()
        }
        .padding()
    }
    
    private var yearlySection: some View {
        VStack(spacing: 5) {
            DatePicker(
                "Cada año en esta fecha:",
                selection: $yearlyDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(.system(size: 18))

            Text("Se repetirá automáticamente todos los años")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .padding()
        }
        .padding()
    }
    
    //Guardar:
    private func save(){
        //Validaciones de campo
        if  self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            self.alertMessage = "Debes introducir un título para el recordatorio"
            self.showAlert = true
            return
        }
        
        //Validaciones de campo
        if  self.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty{
            self.alertMessage = "Debes introducir un mensaje para el recordatorio"
            self.showAlert = true
            return
        }
        

        

        let frequency: ReminderFrequency?
        
        //Aplicando la frecuencia.
        switch mode {

        case .interval:
            if selectedTime.hour == 0 && selectedTime.minute == 0 {
                frequency = nil
            } else {
                frequency = .interval(
                    hours: selectedTime.hour,
                    minutes: selectedTime.minute
                )
            }

        case .daily:
            let components = Calendar.current.dateComponents(
                [.hour, .minute],
                from: dailyTime
            )

            if let h = components.hour, let m = components.minute {
                frequency = .daily(hour: h, minute: m)
            } else {
                frequency = nil
            }

        case .date:
            if selectedDate <= Date() {
                frequency = nil
            } else {
                frequency = .date(selectedDate)
            }
            
        case .monthly:
            let components = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: monthlyDate
            )

            if
                let day = components.day,
                let hour = components.hour,
                let minute = components.minute
            {
                frequency = .monthly(
                    day: day,
                    hour: hour,
                    minute: minute
                )
            } else {
                frequency = nil
            }
            
        case .yearly:
            let components = Calendar.current.dateComponents(
                [.month, .day, .hour, .minute],
                from: yearlyDate
            )

            if
                let month = components.month,
                let day = components.day,
                let hour = components.hour,
                let minute = components.minute
            {
                frequency = .yearly(
                    month: month,
                    day: day,
                    hour: hour,
                    minute: minute
                )
            } else {
                frequency = nil
            }
        }

        //Manejo de errores:
        guard let frequency else {
            alertMessage = "Debes elegir un tiempo válido para el recordatorio"
            showAlert = true
            return
        }

        
        //Guardando el tono, si se ha selecionado uno:
        NotificationSound.selected = selectedSound
        
        
        // Si estamos editando un recordatorio, verificamos si se ha modificado la frecuencia, o solo el titulo y mensaje.
        if let reminderAEditar {
            //Borramos el reminder solo si se ha realizado cambios en su frecuencia. No lo borramos si solo actualizamos el título o el contenido
            if self.reminderAEditar?.frequency != frequency{
                
                
                //Si el reminder estaba en la lista de widget de reminder, activa un flag para luego adicionarlo
                var flag : Bool = false
                if SelectedReminderModel.shared.existingRemindersId(reminderAEditar) {
                    flag = true //El reminder estaba en la lista de widget.
                }
                
                ReminderNotificationManager.shared.cancel(id: reminderAEditar.id) //Eliminando el reminder actual, porque hemos. esto también lo borra de la lista de widgets
                
                //Recreando el un nuevo reminder:
                let newReminder = ReminderNotificationManager.shared.scheduleAndStore(
                    title: title,
                    message: message,
                    frequency: frequency
                )
                
                //Por ultimo, si el reminder original estaba en la lista de widgets, se vuelve a adicionar
                if flag {
                    SelectedReminderModel.shared.select(newReminder)
                }
               

            }else{
                //Si NO se ha cambiado la frecuencia del reminder solo actualizamos su título y mensaje, no lo reiniciamos.
                let reminder = StoredReminder(
                    id: reminderAEditar.id,
                    title: self.title,
                    message: self.message,
                    frequency: reminderAEditar.frequency,
                    isStarted: reminderAEditar.isStarted,
                    startedAt: reminderAEditar.startedAt,
                )
                //Salvando sol los datos sin recrear el recordatorio
                ReminderStore.shared.update(reminder)
            }
            
        }else{
            //Si es un nuevo recordatorio entonces lo creamos desde cero:
           _ =  ReminderNotificationManager.shared.scheduleAndStore(
                title: title,
                message: message,
                frequency: frequency
            )
        }

        onSave()
        dismiss()

    }

    // Cargar edición
    private func loadExisting() {
        guard let reminderAEditar else { return }

        title = reminderAEditar.title
        message = reminderAEditar.message

        switch reminderAEditar.frequency {

        case .interval(let h, let m):
            mode = .interval
            selectedTime = Time(hour: h, minute: m)

        case .daily(let h, let m):
            mode = .daily
            dailyTime = Calendar.current.date(
                bySettingHour: h,
                minute: m,
                second: 0,
                of: Date()
            ) ?? Date()

        case .date(let date):
            mode = .date
            selectedDate = date
            
        case .monthly(let day, let hour, let minute):
            mode = .monthly

            var components = DateComponents()
            components.day = day
            components.hour = hour
            components.minute = minute

            monthlyDate = Calendar.current.date(from: components) ?? Date()
            
        case .yearly(let month, let day, let hour, let minute):
            mode = .yearly

            var components = DateComponents()
            components.month = month
            components.day = day
            components.hour = hour
            components.minute = minute

            yearlyDate = Calendar.current.date(from: components) ?? Date()
        }
    }
}

#if os(iOS)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
#endif

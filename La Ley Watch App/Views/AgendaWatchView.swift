import SwiftUI

struct AgendaWatchView: View {
    @StateObject private var modelWatch = watchModel.shared
    @State private var filtro: watchModel.AgendaFiltroTemporal = .hoy
    @State private var showAddSheet = false
    @State private var showFilterDialog = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)

            VStack {
                Text("Agenda")
                    .fontDesign(.serif)
                    .foregroundStyle(.black)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 5)

                Divider()

                HStack {
                    Button {
                        modelWatch.getAgendaEntradas(filtro: filtro)
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showFilterDialog = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.black)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Divider()

                List(modelWatch.listAgenda, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.titulo)
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                        Text("\(item.fechaActividad.formatted(date: .abbreviated, time: .omitted)) · \(item.hora.formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .foregroundStyle(.black)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            if modelWatch.deleteAgendaEntry(id: item.id) {
                                alertMessage = "Entrada eliminada"
                            } else {
                                alertMessage = "Error al eliminar entrada"
                            }
                            showAlert = true
                        } label: {
                            Label("Borrar", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .alert("Agenda", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .confirmationDialog("Filtrar Agenda", isPresented: $showFilterDialog, titleVisibility: .visible) {
            Button("Hoy") {
                filtro = .hoy
                modelWatch.getAgendaEntradas(filtro: .hoy)
            }
            Button("Semana actual") {
                filtro = .semanaActual
                modelWatch.getAgendaEntradas(filtro: .semanaActual)
            }
            Button("Mes actual") {
                filtro = .mesActual
                modelWatch.getAgendaEntradas(filtro: .mesActual)
            }
            Button("Cancelar", role: .cancel) {}
        }
        .sheet(isPresented: $showAddSheet) {
            AddAgendaEntryWatchView(
                onSave: { title, contenido, lugar, fecha, hora in
                    _ = modelWatch.addAgendaEntry(
                        title: title,
                        contenido: contenido,
                        lugar: lugar,
                        fechaActividad: fecha,
                        hora: hora
                    )
                    modelWatch.getAgendaEntradas(filtro: filtro)
                }
            )
        }
        .task {
            modelWatch.getAgendaEntradas(filtro: filtro)
        }
    }
}

private struct AddAgendaEntryWatchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var contenido = ""
    @State private var lugar = ""
    @State private var fecha = Date()
    @State private var hora = Date()
    @StateObject private var locationCapture = WatchLocationCapture()
    @State private var isResolvingLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    let onSave: (String, String, String, Date, Date) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 8) {
                        Text("Nueva entrada")
                            .fontDesign(.serif)
                            .foregroundStyle(.black)
                            .bold()

                        TextFieldLink("Título: \(title)", prompt: Text("Título")) { value in
                            title = value
                        }
                        .frame(height: 36)

                        TextFieldLink("Detalle: \(contenido)", prompt: Text("Detalle")) { value in
                            contenido = value
                        }
                        .frame(height: 36)

                        locationButton

                        if !lugar.isEmpty {
                            Text(lugar)
                                .font(.system(size: 11))
                                .lineLimit(2)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 6)
                        }

                        NavigationLink {
                            AgendaDateSelectionWatchView(fecha: $fecha)
                        } label: {
                            Label(fecha.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        NavigationLink {
                            AgendaTimeSelectionWatchView(hora: $hora)
                        } label: {
                            Label(hora.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button("Guardar") {
                            onSave(title, contenido, lugar, fecha, hora)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                }
            }
            .alert("Agenda", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    private var locationButton: some View {
        Button {
            attachCurrentLocation()
        } label: {
            HStack(spacing: 6) {
                if isResolvingLocation {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.black)
                }

                Text(lugar.isEmpty ? "Lugar" : "Actualizar lugar")
                    .foregroundStyle(.black)

                if !lugar.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isResolvingLocation)
    }

    private func attachCurrentLocation() {
        guard !isResolvingLocation else { return }

        isResolvingLocation = true
        locationCapture.captureCurrentAddress { result in
            isResolvingLocation = false
            switch result {
            case .success(let coordinates):
                lugar = coordinates
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

private struct AgendaDateSelectionWatchView: View {
    @Binding var fecha: Date

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Fecha")
                    .fontDesign(.serif)
                    .foregroundStyle(.black)
                    .bold()

                DatePicker("Fecha", selection: $fecha, displayedComponents: [.date])
                    .labelsHidden()
                    .frame(minHeight: 80)
            }
            .padding(.horizontal, 10)
        }
    }
}

private struct AgendaTimeSelectionWatchView: View {
    @Binding var hora: Date

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Hora")
                    .fontDesign(.serif)
                    .foregroundStyle(.black)
                    .bold()

                DatePicker("Hora", selection: $hora, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(minHeight: 80)
            }
            .padding(.horizontal, 10)
        }
    }
}

#Preview {
    AgendaWatchView()
}

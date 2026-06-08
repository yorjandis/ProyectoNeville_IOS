import SwiftUI

struct AgendaWatchView: View {
    @StateObject private var modelWatch = watchModel.shared
    @State private var filtro: watchModel.AgendaFiltroTemporal = .hoy
    @State private var showAddSheet = false
    @State private var showFilterDialog = false

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
                }
            }
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

    let onSave: (String, String, String, Date, Date) -> Void

    var body: some View {
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

                    TextFieldLink("Lugar: \(lugar)", prompt: Text("Lugar")) { value in
                        lugar = value
                    }
                    .frame(height: 36)

                    DatePicker("Fecha", selection: $fecha, displayedComponents: [.date])
                        .labelsHidden()
                        .frame(minHeight: 58)

                    DatePicker("Hora", selection: $hora, displayedComponents: [.hourAndMinute])
                        .labelsHidden()

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
    }
}

#Preview {
    AgendaWatchView()
}

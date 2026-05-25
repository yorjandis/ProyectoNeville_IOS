import SwiftUI
import CoreLocation

struct QuickAddNotaByLocationView: View {
    @StateObject private var modelWatch = watchModel.shared
    @StateObject private var locationCapture = WatchLocationCapture()

    @State private var title: String = ""
    @State private var nota: String = ""
    @State private var isResolvingLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Nueva Nota")
                    .fontDesign(.serif)
                    .bold()
                    .foregroundStyle(.black)

                TextFieldLink("Título: \(title)", prompt: Text("Título")) { value in
                    title = value
                }
                .frame(height: 38)

                TextFieldLink("Nota: \(nota)", prompt: Text("Contenido de la nota")) { value in
                    nota = value
                }
                .frame(height: 38)

                Button {
                    createNoteWithCurrentLocation()
                } label: {
                    if isResolvingLocation {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        Label("Guardar ubicación", systemImage: "location.fill")
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                }
                .background(.white.opacity(0.65))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .buttonStyle(.plain)
                .disabled(isResolvingLocation)
            }
            .padding(.horizontal, 10)
        }
        .alert("Notas", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func createNoteWithCurrentLocation() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMessage = "Debes indicar un título."
            showAlert = true
            return
        }

        isResolvingLocation = true
        locationCapture.captureCurrentAddress { result in
            isResolvingLocation = false
            switch result {
            case .success(let address):
                let didSave = modelWatch.addNota(title: trimmedTitle, nota: nota, direccionMapa: address)
                if didSave {
                    title = ""
                    nota = ""
                    alertMessage = "Nota guardada correctamente."
                    showAlert = true
                } else {
                    alertMessage = "No se pudo guardar la nota."
                    showAlert = true
                }
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

@MainActor
final class WatchLocationCapture: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<String, Error>) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func captureCurrentAddress(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.failure(NSError(domain: "WatchLocationCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Activa permisos de ubicación en Ajustes."])))
        @unknown default:
            finish(.failure(NSError(domain: "WatchLocationCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: "Estado de ubicación no soportado."])))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.manager.requestLocation()
            } else if status == .denied || status == .restricted {
                self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: "Permiso de ubicación denegado."])))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.first else {
                self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 4, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la ubicación actual."])))
                return
            }

            CLGeocoder().reverseGeocodeLocation(location) { [weak self] placemarks, error in
                Task { @MainActor in
                    guard let self else { return }
                    if let error {
                        self.finish(.failure(error))
                        return
                    }

                    guard let place = placemarks?.first else {
                        self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 5, userInfo: [NSLocalizedDescriptionKey: "No se encontró una dirección para esta ubicación."])))
                        return
                    }

                    let parts = [
                        place.name,
                        place.locality,
                        place.administrativeArea,
                        place.country
                    ].compactMap { $0 }.filter { !$0.isEmpty }

                    let address = parts.joined(separator: ", ")
                    if address.isEmpty {
                        self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 6, userInfo: [NSLocalizedDescriptionKey: "La dirección obtenida está vacía."])))
                    } else {
                        self.finish(.success(address))
                    }
                }
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.finish(.failure(error))
        }
    }

    private func finish(_ result: Result<String, Error>) {
        completion?(result)
        completion = nil
    }
}

#Preview {
    QuickAddNotaByLocationView()
}

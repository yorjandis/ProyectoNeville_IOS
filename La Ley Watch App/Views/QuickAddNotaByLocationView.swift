import SwiftUI
import CoreLocation

struct QuickAddNotaByLocationView: View {
    @StateObject private var modelWatch = watchModel.shared
    @StateObject private var locationCapture = WatchLocationCapture()

    @State private var title: String = ""
    @State private var nota: String = ""
    @State private var isResolvingLocation = false
    @State private var resolvedAddress: String = ""
    @State private var hasResolvedLocation = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.red, .orange], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()

            
            ScrollView{
                VStack(spacing: 12) {
                    
                    Text("Nueva Nota")
                        .fontDesign(.serif)
                        .bold()
                        .foregroundStyle(.black)
                        

                    TextField("Título", text: $title)
                    .frame(height: 38)
                    .padding(5)

                    TextField("Contenido de la nota", text: $nota)
                    .frame(height: 38)

                    VStack(spacing: 8) {
                        
                        Button {
                            requestCurrentLocation()
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

                                Text("Coordenadas")
                                    .foregroundStyle(.black)

                                if hasResolvedLocation {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .background(.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                        .disabled(isResolvingLocation)
                        
                        Button {
                            saveNote()
                        } label: {
                            Label("Guardar", systemImage: "tray.and.arrow.down.fill")
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .background(.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .buttonStyle(.plain)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                       
                    }

                    Text("Debe aceptar primero, en Ajustes, los permisos de ubicación en iPhone.")
                        .font(.caption)
                }
                .padding(.top, 40)
                .padding(.horizontal, 10)
            }
            
        }
        .alert("Notas", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func requestCurrentLocation() {
        guard !isResolvingLocation else { return }

        isResolvingLocation = true
        hasResolvedLocation = false

        locationCapture.captureCurrentAddress { result in
            isResolvingLocation = false
            switch result {
            case .success(let address):
                resolvedAddress = address
                hasResolvedLocation = true
            case .failure(let error):
                resolvedAddress = ""
                hasResolvedLocation = false
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func saveNote() {
        if isResolvingLocation {
            locationCapture.cancelCapture()
            isResolvingLocation = false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            alertMessage = "Debes indicar un título."
            showAlert = true
            return
        }

        let didSave = modelWatch.addNota(title: trimmedTitle, nota: nota, direccionMapa: resolvedAddress)
        if didSave {
            title = ""
            nota = ""
            resolvedAddress = ""
            hasResolvedLocation = false
            alertMessage = "Nota guardada correctamente."
            showAlert = true
        } else {
            alertMessage = "No se pudo guardar la nota."
            showAlert = true
        }
    }
}

@MainActor
final class WatchLocationCapture: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((Result<String, Error>) -> Void)?
    private var bestLocation: CLLocation?
    private var timeoutTask: Task<Void, Never>?
    private let targetHorizontalAccuracy: CLLocationAccuracy = 25
    private let maximumCaptureSeconds: UInt64 = 6

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
    }

    func captureCurrentAddress(completion: @escaping (Result<String, Error>) -> Void) {
        cancelCapture()
        bestLocation = nil
        self.completion = completion
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startPrecisionCapture()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.failure(NSError(domain: "WatchLocationCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: WatchL10n.exact("Activa permisos de ubicación en Ajustes.")])))
        @unknown default:
            finish(.failure(NSError(domain: "WatchLocationCapture", code: 2, userInfo: [NSLocalizedDescriptionKey: WatchL10n.exact("Estado de ubicación no soportado.")])))
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                self.startPrecisionCapture()
            } else if status == .denied || status == .restricted {
                self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 3, userInfo: [NSLocalizedDescriptionKey: WatchL10n.exact("Permiso de ubicación denegado.")])))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            let freshLocations = locations.filter { location in
                location.horizontalAccuracy >= 0 && abs(location.timestamp.timeIntervalSinceNow) <= 15
            }

            guard let location = freshLocations.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) else {
                return
            }

            if self.bestLocation == nil || location.horizontalAccuracy < (self.bestLocation?.horizontalAccuracy ?? .greatestFiniteMagnitude) {
                self.bestLocation = location
            }

            if location.horizontalAccuracy <= self.targetHorizontalAccuracy {
                self.finish(.success(Self.coordinateString(from: location.coordinate)))
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.finish(.failure(error))
        }
    }

    func cancelCapture() {
        timeoutTask?.cancel()
        timeoutTask = nil
        completion = nil
        manager.stopUpdatingLocation()
    }

    private func finish(_ result: Result<String, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        manager.stopUpdatingLocation()
        completion?(result)
        completion = nil
    }

    private func startPrecisionCapture() {
        manager.startUpdatingLocation()
        timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: (self?.maximumCaptureSeconds ?? 6) * 1_000_000_000)
            await MainActor.run {
                guard let self, self.completion != nil else { return }
                if let bestLocation = self.bestLocation {
                    self.finish(.success(Self.coordinateString(from: bestLocation.coordinate)))
                } else {
                    self.finish(.failure(NSError(domain: "WatchLocationCapture", code: 4, userInfo: [NSLocalizedDescriptionKey: WatchL10n.exact("No se pudo obtener la ubicación actual.")])))
                }
            }
        }
    }

    private static func coordinateString(from coordinate: CLLocationCoordinate2D) -> String {
        String(
            format: "%.6f,%.6f",
            locale: Locale(identifier: "en_US_POSIX"),
            coordinate.latitude,
            coordinate.longitude
        )
    }
}

#Preview {
    QuickAddNotaByLocationView()
}

import SwiftUI

struct HealingEmergencyResourcesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("healing_center.emergency_region") private var storedRegionCode = ""

    private let provider = HealingEmergencyResourceProvider()

    private var selectedRegionCode: String {
        storedRegionCode.isEmpty ? provider.detectedRegionCode : storedRegionCode
    }

    private var resources: HealingEmergencyResources {
        provider.resources(for: selectedRegionCode)
    }

    var body: some View {
        List {
            Section {
                Label {
                    Text("Si existe peligro inmediato, no continúes con un ejercicio de autorregulación. Llama a emergencias o pide a otra persona que lo haga.")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Section("Comprueba estas señales") {
                ForEach(HealingSafetyPolicy.urgentSignals, id: \.self) { signal in
                    Label(signal, systemImage: "exclamationmark.circle")
                        .font(.subheadline)
                }
            }

            Section("País o región") {
                Picker("Recursos para", selection: regionBinding) {
                    ForEach(provider.availableRegionCodes, id: \.self) { code in
                        Text(provider.countryName(for: code)).tag(code)
                    }
                }
                Text(resources.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if resources.contacts.isEmpty {
                Section("Ayuda") {
                    Text("Consulta el número local de emergencias o utiliza el directorio internacional para encontrar ayuda verificada en tu país.")
                    Link(destination: HealingEmergencyResourceProvider.internationalDirectoryURL) {
                        Label("Abrir directorio internacional", systemImage: "globe")
                    }
                }
            } else {
                Section("Contactos para \(resources.countryName)") {
                    ForEach(resources.contacts) { contact in
                        emergencyContact(contact)
                    }
                }
            }

            Section("Más países") {
                Link(destination: HealingEmergencyResourceProvider.internationalDirectoryURL) {
                    Label("Directorio internacional de líneas de ayuda", systemImage: "globe")
                }
                Text("Los servicios pueden cambiar. Comprueba siempre el país, el propósito y la fuente antes de llamar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Ayuda urgente")
        .healingInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Cerrar") { dismiss() }
            }
        }
        .onAppear {
            if storedRegionCode.isEmpty {
                storedRegionCode = provider.detectedRegionCode
            }
        }
    }

    private var regionBinding: Binding<String> {
        Binding(
            get: { selectedRegionCode },
            set: { storedRegionCode = $0 }
        )
    }

    private func emergencyContact(_ contact: HealingEmergencyContact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: contact.kind == .emergency ? "phone.fill" : "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(contact.kind == .emergency ? .red : .blue)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(contact.title)
                        .font(.headline)
                    Text(contact.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let telephoneURL = contact.telephoneURL {
                Link(destination: telephoneURL) {
                    Label("Llamar al \(contact.number)", systemImage: "phone.arrow.up.right.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                }
                .buttonStyle(.borderedProminent)
                .tint(contact.kind == .emergency ? .red : .blue)
            }

            if let sourceURL = contact.sourceURL {
                Link("Consultar fuente oficial", destination: sourceURL)
                    .font(.caption)
            }
        }
        .padding(.vertical, 5)
    }
}

//
//  OpenRouterSettingsView.swift
//  Neville_iOS
//
//  Configuración BYOK y consentimiento explícito para OpenRouter.
//

import SwiftUI

@available(iOS 26.0, macOS 26.0, *)
struct OpenRouterSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let onCredentialsChanged: () -> Void

    @State private var apiKey = ""
    @State private var hasStoredKey = false
    @State private var isValidating = false
    @State private var models = OpenRouterConfiguration.fallbackModels
    @State private var selectedModel = OpenRouterConfiguration.selectedModelIdentifier
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var isKeyTutorialExpanded = false

    private let credentialStore = OpenRouterCredentialStore.shared
    private let provider = OpenRouterChatProvider.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Cómo crear una clave") {
                    DisclosureGroup(
                        "Guía rápida paso a paso",
                        isExpanded: $isKeyTutorialExpanded
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            tutorialStep(
                                number: 1,
                                title: "Abre OpenRouter",
                                detail: "Pulsa el enlace inferior e inicia sesión o crea una cuenta."
                            )
                            tutorialStep(
                                number: 2,
                                title: "Crea una clave",
                                detail: "En la página «API Keys», pulsa «Create API Key»."
                            )
                            tutorialStep(
                                number: 3,
                                title: "Ponle un nombre",
                                detail: "Usa un nombre reconocible, por ejemplo «Neville», para identificar y revocar esta clave fácilmente."
                            )
                            tutorialStep(
                                number: 4,
                                title: "Copia la clave",
                                detail: "Guarda la clave completa cuando aparezca. OpenRouter solo muestra el valor secreto al crearla."
                            )
                            tutorialStep(
                                number: 5,
                                title: "Vuelve a Neville",
                                detail: "Pégala en «Tu clave personal» y pulsa «Comprobar y guardar»."
                            )
                        }
                        .padding(.vertical, 8)

                        Link(
                            "Abrir la página de claves de OpenRouter",
                            destination: URL(string: "https://openrouter.ai/settings/keys")!
                        )

                        Label(
                            "Crea una clave exclusiva para Neville, no la compartas y revócala desde OpenRouter si sospechas que ha quedado expuesta.",
                            systemImage: "lock.shield"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 6)
                    }
                }

                Section("Tu clave personal") {
                    SecureField(
                        hasStoredKey
                            ? "Introduce una clave para reemplazar la guardada"
                            : "Clave de API de OpenRouter",
                        text: $apiKey
                    )
                    .textContentType(.password)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    #endif

                    if hasStoredKey {
                        Label("Clave guardada en este dispositivo", systemImage: "checkmark.shield")
                            .foregroundStyle(.green)
                    }

                    Button {
                        validateAndSave()
                    } label: {
                        if isValidating {
                            HStack {
                                ProgressView()
                                Text("Comprobando…")
                            }
                        } else {
                            Label(
                                apiKey.isEmpty && hasStoredKey
                                    ? "Comprobar clave guardada"
                                    : "Comprobar y guardar",
                                systemImage: "checkmark.circle"
                            )
                        }
                    }
                    .disabled(isValidating || (apiKey.isEmpty && !hasStoredKey))

                    if let statusMessage {
                        Text(statusMessage)
                            .foregroundStyle(.green)
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Modelo para nuevas conversaciones") {
                    Picker("Modelo", selection: $selectedModel) {
                        ForEach(models) { model in
                            Text(model.displayName).tag(model.id)
                        }
                    }
                    .onChange(of: selectedModel) { _, newValue in
                        OpenRouterConfiguration.selectedModelIdentifier = newValue
                    }
                    Text("Solo se muestran modelos gratuitos, ordenados por capacidad según OpenRouter. El modelo queda fijado al crear cada conversación para mantener un comportamiento coherente.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    OpenRouterFreeLimitNotice(
                        modelIdentifier: selectedModel
                    )

                    if let selected = models.first(where: {
                        $0.id == selectedModel
                    }) {
                        Text(selected.id)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        if let contextLength = selected.contextLength {
                            Text("Contexto máximo publicado: \(contextLength.formatted()) tokens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let description = selected.description,
                           !description.isEmpty {
                            Text(description)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(5)
                        }
                    }
                }

                Section("Privacidad y uso") {
                    Text("La clave pertenece al usuario. Neville no incluye una clave propia ni la envía a servidores intermedios.")
                    Text("Al usar OpenRouter, las preguntas y el contexto necesario se envían a OpenRouter y al proveedor que ejecuta el modelo gratuito seleccionado. Sus políticas de tratamiento de datos pueden variar.")
                    Text("Los modelos gratuitos están sujetos a límites de uso y disponibilidad. Neville nunca cambiará silenciosamente a un modelo de pago.")
                    Link(
                        "Crear o consultar una clave en OpenRouter",
                        destination: URL(string: "https://openrouter.ai/settings/keys")!
                    )
                    Link(
                        "Consultar la privacidad de los proveedores",
                        destination: URL(string: "https://openrouter.ai/docs/guides/privacy/provider-logging")!
                    )
                    Link(
                        "Consultar los límites de modelos gratuitos",
                        destination: URL(string: "https://openrouter.ai/docs/faq")!
                    )
                    if OpenRouterConfiguration.hasPrivacyConsent {
                        Button(
                            "Revocar permiso para compartir conversaciones",
                            role: .destructive
                        ) {
                            OpenRouterConfiguration.revokePrivacyConsent()
                            statusMessage = "El permiso se revocó. OpenRouter pedirá autorización antes del próximo uso."
                            onCredentialsChanged()
                        }
                    }
                }

                if hasStoredKey {
                    Section {
                        Button("Eliminar clave de este dispositivo", role: .destructive) {
                            deleteKey()
                        }
                    }
                }
            }
            .navigationTitle("OpenRouter")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            hasStoredKey = (try? credentialStore.readAPIKey()) != nil
            isKeyTutorialExpanded = !hasStoredKey
            if !models.contains(where: { $0.id == selectedModel }) {
                models.insert(
                    OpenRouterModel(
                        id: selectedModel,
                        name: selectedModel,
                        contextLength: nil,
                        description: nil
                    ),
                    at: 0
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 570)
        #endif
    }

    @ViewBuilder
    private func tutorialStep(
        number: Int,
        title: String,
        detail: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number.formatted())
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.blue, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func validateAndSave() {
        statusMessage = nil
        errorMessage = nil
        isValidating = true
        let candidate = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let key: String
                if !candidate.isEmpty {
                    key = candidate
                } else if let stored = try credentialStore.readAPIKey() {
                    key = stored
                } else {
                    throw OpenRouterChatError.missingAPIKey
                }

                let catalog = try await provider.availableModels(apiKey: key)
                if !candidate.isEmpty {
                    try credentialStore.saveAPIKey(candidate)
                }
                await MainActor.run {
                    models = catalog.models
                    OpenRouterConfiguration.updateDailyFreeRequestLimit(
                        catalog.dailyFreeRequestLimit
                    )
                    if !OpenRouterConfiguration.hasSelectedModelIdentifier
                        || !catalog.models.contains(where: {
                            $0.id == selectedModel
                        }) {
                        selectedModel = catalog.models.first(where: {
                            $0.isAutomaticFreeSelection
                        })?.id
                            ?? catalog.models.first?.id
                            ?? OpenRouterConfiguration.defaultModelIdentifier
                    }
                    OpenRouterConfiguration.selectedModelIdentifier = selectedModel
                    apiKey = ""
                    hasStoredKey = true
                    statusMessage = "La clave es válida y está lista para usar."
                    errorMessage = nil
                    isValidating = false
                    onCredentialsChanged()
                }
            } catch {
                await MainActor.run {
                    statusMessage = nil
                    errorMessage = error.localizedDescription
                    isValidating = false
                }
            }
        }
    }

    private func deleteKey() {
        do {
            try credentialStore.deleteAPIKey()
            OpenRouterConfiguration.resetDailyFreeRequestLimit()
            apiKey = ""
            hasStoredKey = false
            statusMessage = "La clave se eliminó de este dispositivo."
            errorMessage = nil
            onCredentialsChanged()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@available(iOS 26.0, macOS 26.0, *)
struct OpenRouterFreeLimitNotice: View {
    let modelIdentifier: String
    var compact = false

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(
                    "Límite gratuito de esta cuenta: hasta \(OpenRouterConfiguration.dailyFreeRequestLimit) solicitudes al día."
                )
                .font(compact ? .caption2 : .footnote)

                if !compact {
                    Text(
                        "Una respuesta puede utilizar más de una solicitud cuando debe resumir un documento largo, compactar el historial o continuar una generación."
                    )
                    .font(.caption)

                    if modelIdentifier
                        == OpenRouterConfiguration
                            .automaticFreeModelIdentifier {
                        Text(
                            "La selección automática gratuita puede evitar modelos temporalmente saturados, pero no evita el límite diario de la cuenta."
                        )
                        .font(.caption)
                    } else {
                        Text(
                            "Este modelo puede tener además límites temporales propios. Si aparece un límite repetidamente, prueba «Selección automática gratuita»."
                        )
                        .font(.caption)
                    }
                }
            }
        } icon: {
            Image(systemName: "gauge.with.dots.needle.50percent")
        }
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}

@available(iOS 26.0, macOS 26.0, *)
struct OpenRouterPrivacyConsentView: View {
    @Environment(\.dismiss) private var dismiss

    let onAccept: () -> Void

    @State private var confirmsSharing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Label("OpenRouter funciona online", systemImage: "network")
                        .font(.title2.bold())

                    Text("Apple Intelligence seguirá siendo el modelo predeterminado y procesa las funciones de IA de forma local. OpenRouter es opcional y solo se activa cuando tú lo eliges.")

                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            disclosure(
                                "Qué se comparte",
                                "La pregunta o texto que quieras procesar, la operación seleccionada, el autor cuando corresponda y el contexto necesario para generar la respuesta."
                            )
                            disclosure(
                                "Con quién",
                                "Los datos se envían a OpenRouter y al proveedor que ejecute el modelo gratuito seleccionado, usando tu propia clave."
                            )
                            disclosure(
                                "Qué no ocurre",
                                "No hay cambio automático de Apple a OpenRouter, nunca se seleccionan modelos de pago y tu clave no se guarda en los contenidos ni se envía a servidores de Neville."
                            )
                        }
                    }

                    Toggle(
                        "Comprendo y autorizo el envío de este contenido a OpenRouter y al proveedor del modelo cuando utilice esta opción.",
                        isOn: $confirmsSharing
                    )

                    Link(
                        "Consultar los términos de OpenRouter",
                        destination: URL(string: "https://openrouter.ai/terms")!
                    )

                    Link(
                        "Consultar la política de privacidad de OpenRouter",
                        destination: URL(string: "https://openrouter.ai/privacy")!
                    )

                    Button {
                        OpenRouterConfiguration.acceptPrivacyConsent()
                        onAccept()
                        dismiss()
                    } label: {
                        Text("Aceptar y continuar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!confirmsSharing)
                }
                .padding()
            }
            .navigationTitle("Privacidad de OpenRouter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 540)
        #endif
    }

    @ViewBuilder
    private func disclosure(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

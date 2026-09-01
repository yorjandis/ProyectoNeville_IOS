import SwiftUI

struct CentroSanadorView: View {
    private let loadResult: Result<HealingCatalog, Error>
    private let embeddedInNavigationStack: Bool

    @State private var searchText = ""
    @State private var showEmergencyResources = false
    @State private var showPremium = false
    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false
    @AppStorage(HealingCenterFavorites.storageKey) private var storedFavorites = "[]"

    init(
        embeddedInNavigationStack: Bool = false,
        repository: HealingCatalogProviding = BundledHealingCatalogRepository()
    ) {
        self.embeddedInNavigationStack = embeddedInNavigationStack
        self.loadResult = Result { try repository.load() }
    }

    var body: some View {
        Group {
            if embeddedInNavigationStack {
                NavigationStack { content }
            } else {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadResult {
        case .success(let catalog):
            catalogContent(catalog)
        case .failure(let error):
            loadError(error)
        }
    }

    private func catalogContent(_ catalog: HealingCatalog) -> some View {
        ZStack {
            HealingCenterVisualStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 16) {
                    welcomeHeader
                    emergencyAccess

                    if hasPremiumAccess {
                        HealingGlassCard {
                            Label(
                                L10n.format(
                                    "healing.guide.disclaimer",
                                    fallback: "- Una guía, no un diagnóstico - \n\n{0}",
                                    catalog.disclaimer
                                ),
                                systemImage: "info.circle.fill"
                            )
                                .font(.headline)
                                .foregroundStyle(.cyan)
                        }

                        Text(L10n.exact(searchText.isEmpty ? "¿Qué está ocurriendo?" : "Resultados"))
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .padding(.top, 4)

                        let situations = filteredSituations(in: catalog)
                        if situations.isEmpty {
                            ContentUnavailableView(
                                "Sin coincidencias",
                                systemImage: "magnifyingglass",
                                description: Text("Prueba con palabras como miedo, trabajo, dudas, enfado o ansiedad.")
                            )
                            .foregroundStyle(.white)
                        } else {
                            ForEach(situations) { situation in
                                NavigationLink {
                                    HealingSituationDetailView(
                                        situation: situation,
                                        catalogVersion: catalog.contentVersion,
                                        reviewedAt: catalog.reviewedAt
                                    )
                                } label: {
                                    HealingSituationCard(
                                        situation: situation,
                                        isFavorite: favorites.contains(situation.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        premiumLockedContent
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Centro Sanador")
        .healingInlineNavigationTitle()
        .searchable(text: $searchText, prompt: "¿Qué sientes ahora?")
        .sheet(isPresented: $showEmergencyResources) {
            NavigationStack {
                HealingEmergencyResourcesView()
            }
        }
        .sheet(isPresented: $showPremium) {
            PremiumFeaturePreviewView(feature: .healingCenter)
        }
    }

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.mint)
                    .frame(width: 48, height: 48)
                    .background(.mint.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apoyo para este momento")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                    Text("No necesitas describirlo perfectamente.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.70))
                }
            }

            Text("Elige la experiencia que más se parece a lo que estás viviendo. Primero comprobaremos la seguridad y después te guiaremos paso a paso.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
    }

    private var emergencyAccess: some View {
        Button {
            showEmergencyResources = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sos.circle.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("¿Podría ser una emergencia?")
                        .font(.title3)
                    Text("Comprueba señales de alarma y recursos de tu país")
                        .font(.body)
                        .opacity(0.82)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(15)
            .background(.red.opacity(0.72), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .stroke(.white.opacity(0.24), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre los números de emergencia y apoyo emocional según la región seleccionada")
    }

    private var premiumLockedContent: some View {
        HealingGlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .frame(width: 42, height: 42)
                        .background(.yellow.opacity(0.16), in: Circle())

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Guías prácticas premium")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("La ayuda de emergencia queda siempre abierta. Las situaciones guiadas, técnicas y explicaciones del Centro Sanador forman parte del contenido premium.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    showPremium = true
                } label: {
                    Label("Desbloquear Centro Sanador", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.indigo, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func filteredSituations(in catalog: HealingCatalog) -> [HealingSituation] {
        let filtered = catalog.situations.filter { $0.matches(searchText) }
        return filtered.sorted { lhs, rhs in
            let lhsFavorite = favorites.contains(lhs.id)
            let rhsFavorite = favorites.contains(rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return (catalog.situations.firstIndex(of: lhs) ?? 0)
                < (catalog.situations.firstIndex(of: rhs) ?? 0)
        }
    }

    private var favorites: Set<String> {
        HealingCenterFavorites.decode(storedFavorites)
    }

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    private func loadError(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Centro no disponible", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        }
        .navigationTitle("Centro Sanador")
    }
}

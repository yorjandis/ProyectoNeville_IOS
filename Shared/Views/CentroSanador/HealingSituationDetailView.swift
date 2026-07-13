import SwiftUI

struct HealingSituationDetailView: View {
    let situation: HealingSituation
    let catalogVersion: String
    let reviewedAt: String

    @AppStorage(HealingCenterFavorites.storageKey) private var storedFavorites = "[]"
    @State private var showEmergencyResources = false

    private var colors: [Color] {
        HealingCenterVisualStyle.colors(for: situation.palette)
    }

    private var isFavorite: Bool {
        HealingCenterFavorites.decode(storedFavorites).contains(situation.id)
    }

    var body: some View {
        ZStack {
            HealingCenterVisualStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    titleCard
                    immediateExplanation
                    protocolSection
                    biologicalSection
                    seekHelpSection
                    sourcesSection
                    disclaimer
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(situation.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
            }
        }
        .sheet(isPresented: $showEmergencyResources) {
            NavigationStack { HealingEmergencyResourcesView() }
        }
    }

    private var titleCard: some View {
        HStack(spacing: 14) {
            Image(systemName: situation.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(
                    LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 5) {
                Text(situation.title)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text(situation.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var immediateExplanation: some View {
        HealingGlassCard {
            Label("Lo esencial ahora", systemImage: "bolt.heart.fill")
                .font(.headline)
                .foregroundStyle(colors.first ?? .cyan)
            Text(situation.immediateExplanation)
                .font(.body)
                .foregroundStyle(.white)
                .padding(.top, 5)
            Text(situation.reassurance)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.76))
                .padding(.top, 5)
        }
    }

    private var protocolSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Elige una ayuda práctica")
                .font(.title3.bold())
                .foregroundStyle(.white)

            ForEach(situation.protocols) { healingProtocol in
                NavigationLink {
                    HealingSafetyGateView(
                        situation: situation,
                        healingProtocol: healingProtocol
                    )
                } label: {
                    protocolCard(healingProtocol)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func protocolCard(_ healingProtocol: HealingProtocol) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: healingProtocol.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(colors.first ?? .cyan)
                    .frame(width: 42, height: 42)
                    .background((colors.first ?? .cyan).opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(healingProtocol.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(healingProtocol.summary)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                        .lineLimit(3)
                }

                Spacer(minLength: 2)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack {
                HealingEvidenceBadge(level: healingProtocol.evidence)
                Spacer()
                Label(healingProtocol.durationLabel, systemImage: "timer")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke((colors.first ?? .cyan).opacity(0.25), lineWidth: 1)
        }
    }

    private var biologicalSection: some View {
        HealingGlassCard {
            Label("Qué puede estar ocurriendo", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundStyle(.mint)
            Text(situation.biologicalExplanation)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var seekHelpSection: some View {
        HealingGlassCard {
            Label("Cuándo pedir ayuda", systemImage: "person.crop.circle.badge.questionmark")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(situation.whenToSeekHelp, id: \.self) { item in
                Label(item, systemImage: "circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.80))
                    .symbolRenderingMode(.hierarchical)
                    .padding(.top, 5)
            }

            Button {
                showEmergencyResources = true
            } label: {
                Label("Ver ayuda urgente de mi país", systemImage: "sos.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, 8)
        }
    }

    private var sourcesSection: some View {
        HealingGlassCard {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 13) {
                    ForEach(situation.sources) { source in
                        VStack(alignment: .leading, spacing: 3) {
                            Link(source.title, destination: source.url)
                                .font(.subheadline.weight(.semibold))
                            Text(source.organization)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.62))
                            Text(source.note)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.74))
                        }
                    }
                }
                .padding(.top, 10)
            } label: {
                Label("Fuentes y evidencia", systemImage: "books.vertical.fill")
                    .font(.headline)
                    .foregroundStyle(.cyan)
            }
            .tint(.cyan)
        }
    }

    private var disclaimer: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(HealingSafetyCopy.informationalDisclaimer)
            Text("Contenido \(catalogVersion) · revisado \(reviewedAt)")
        }
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 4)
    }

    private func toggleFavorite() {
        var ids = HealingCenterFavorites.decode(storedFavorites)
        if ids.contains(situation.id) {
            ids.remove(situation.id)
        } else {
            ids.insert(situation.id)
        }
        storedFavorites = HealingCenterFavorites.encode(ids)
    }
}


import SwiftUI

struct HealingSituationDetailView: View {
    let situation: HealingSituation
    let catalogVersion: String
    let reviewedAt: String

    @AppStorage(HealingCenterFavorites.storageKey) private var storedFavorites = "[]"
    @State private var showEmergencyResources = false
    @State private var isBiologicalSectionExpanded = false
    @State private var isPracticalTipsSectionExpanded = false
    @State private var isSeekHelpSectionExpanded = false

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
                    practicalTipsSection
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
                    .font(.body)
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
                .font(.body)
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
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [
                                colors.first?.opacity(0.82) ?? .cyan.opacity(0.82),
                                colors.last?.opacity(0.62) ?? .blue.opacity(0.62)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
                    .shadow(color: colors.first?.opacity(0.24) ?? .cyan.opacity(0.24), radius: 8, y: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(healingProtocol.title)
                        .font(.body)
                        .foregroundStyle(.white)
                    Text(healingProtocol.summary)
                        .font(.body)
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
        .background(
            LinearGradient(
                colors: [
                    colors.first?.opacity(0.16) ?? .cyan.opacity(0.16),
                    .white.opacity(0.09),
                    colors.last?.opacity(0.10) ?? .blue.opacity(0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 19, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .stroke((colors.first ?? .cyan).opacity(0.38), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 6)
    }

    private var practicalTipsSection: some View {
        HealingGlassCard {
            DisclosureGroup(isExpanded: $isPracticalTipsSectionExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Son recursos complementarios y de bajo riesgo que algunas personas encuentran útiles. Su efecto es personal y algunos tienen evidencia limitada: conserva solo los que te resulten útiles y no aumenten el malestar.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.64))
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(situation.practicalTips) { tip in
                        HStack(alignment: .top, spacing: 11) {
                            Image(systemName: "sparkle")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.yellow)
                                .padding(.top, 4)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(tip.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text(tip.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.72))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Text("No pruebes nada que cause dolor, mareo, adormecimiento o mayor malestar. No realices ajustes ni giros bruscos del cuello o la columna.")
                        .font(.caption)
                        .foregroundStyle(.orange.opacity(0.88))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Pequeños recursos que puedes probar", systemImage: "lightbulb.max.fill")
                        .font(.body)
                        .foregroundStyle(.yellow)

                    Text(isPracticalTipsSectionExpanded ? "Ocultar consejos" : "Toca para ver ideas sencillas y complementarias")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .tint(.yellow)
            .accessibilityHint(isPracticalTipsSectionExpanded ? "Contrae los consejos prácticos" : "Despliega los consejos prácticos")
        }
    }

    private var biologicalSection: some View {
        HealingGlassCard {
            DisclosureGroup(isExpanded: $isBiologicalSectionExpanded) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(situation.biologicalExplanation)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .overlay(.white.opacity(0.14))

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Tu organismo también aprende", systemImage: "arrow.triangle.2.circlepath")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.mint)

                        Text("Mente, cuerpo y entorno se influyen mutuamente. La práctica repetida puede enseñarle a tu sistema nervioso respuestas nuevas mediante el aprendizaje y la neuroplasticidad. Esto no significa que un pensamiento aislado controle tus genes, garantice una curación o te haga responsable de sentirte así.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.70))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Qué puede estar ocurriendo", systemImage: "brain.head.profile")
                        .font(.body)
                        .foregroundStyle(.mint)

                    Text(isBiologicalSectionExpanded ? "Ocultar explicación" : "Toca para entender qué sucede en tu cuerpo y tu mente")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .tint(.mint)
            .accessibilityHint(isBiologicalSectionExpanded ? "Contrae la explicación" : "Despliega una explicación biológica más detallada")
        }
    }

    private var seekHelpSection: some View {
        HealingGlassCard {
            DisclosureGroup(isExpanded: $isSeekHelpSectionExpanded) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(situation.whenToSeekHelp, id: \.self) { item in
                        Label(item, systemImage: "circle.fill")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.80))
                            .symbolRenderingMode(.hierarchical)
                    }

                    Button {
                        showEmergencyResources = true
                    } label: {
                        Label("Ver ayuda urgente de mi país", systemImage: "sos.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .padding(.top, 2)
                }
                .padding(.top, 12)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Cuándo pedir ayuda", systemImage: "person.crop.circle.badge.questionmark")
                        .font(.body)
                        .foregroundStyle(.orange)

                    Text(isSeekHelpSectionExpanded ? "Ocultar señales de alerta" : "Toca para ver señales de alerta y recursos urgentes")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.58))
                }
            }
            .tint(.orange)
            .accessibilityHint(isSeekHelpSectionExpanded ? "Contrae las señales de alerta" : "Despliega señales de alerta y recursos de emergencia")
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
                    .font(.body)
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

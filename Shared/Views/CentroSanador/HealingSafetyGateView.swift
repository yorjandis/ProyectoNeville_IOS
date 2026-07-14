import SwiftUI

struct HealingSafetyGateView: View {
    let situation: HealingSituation
    let healingProtocol: HealingProtocol

    @State private var hasCheckedSignals = false
    @State private var showEmergencyResources = false

    private var signals: [String] {
        HealingSafetyPolicy.combinedSignals(for: situation)
    }

    var body: some View {
        ZStack {
            HealingCenterVisualStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                        Text("Antes de comenzar")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Esta comprobación evita tratar automáticamente como emocional algo que podría necesitar ayuda urgente.")
                            .foregroundStyle(.white.opacity(0.74))
                    }

                    HealingGlassCard {
                        Label("Busca ayuda inmediata si…", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)

                        ForEach(signals, id: \.self) { signal in
                            HStack(alignment: .top, spacing: 9) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .padding(.top, 6)
                                Text(signal)
                                    .font(.body)
                            }
                            .foregroundStyle(.white.opacity(0.84))
                            .padding(.top, 5)
                        }

                        Button {
                            showEmergencyResources = true
                        } label: {
                            Label("Sí, no estoy seguro o necesito ayuda", systemImage: "phone.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .padding(.top, 9)
                    }

                    HealingGlassCard {
                        Label(healingProtocol.title, systemImage: healingProtocol.symbol)
                            .font(.body)
                            .foregroundStyle(.cyan)
                        Text(healingProtocol.summary)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.top, 4)

                        if let caution = healingProtocol.caution {
                            Label(caution, systemImage: "info.circle")
                                .font(.body)
                                .foregroundStyle(.orange)
                                .padding(.top, 7)
                        }
                    }

                    Toggle(isOn: $hasCheckedSignals) {
                        Text("He leído las señales y ninguna está presente. Puedo detenerme en cualquier momento.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    .tint(.mint)
                    .padding(15)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    NavigationLink {
                        HealingGuidedSessionView(
                            situation: situation,
                            healingProtocol: healingProtocol
                        )
                    } label: {
                        Label("Comenzar guía", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.mint)
                    .disabled(!hasCheckedSignals)
                    .opacity(hasCheckedSignals ? 1 : 0.48)

                    Text(HealingSafetyCopy.stopInstruction)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.60))
                }
                .padding(18)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Comprobación")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showEmergencyResources) {
            NavigationStack { HealingEmergencyResourcesView() }
        }
    }
}

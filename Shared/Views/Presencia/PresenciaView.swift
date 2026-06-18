#if os(iOS)
import SwiftUI

struct PresenciaView: View {
    @State private var todayPresentCount = 0
    @State private var showSavedFeedback = false
    @State private var feedbackText = ""

    @AppStorage("purchaseStatus") private var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) private var yorjPremium: Bool = false

    private let repository = PresenciaRepository()

    private var hasPremiumAccess: Bool {
        purchaseStatus || yorjPremium
    }

    var body: some View {
        NavigationStack {
            if hasPremiumAccess {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        mainAction
                        moodList
                    }
                    .padding()
                }
                .background(
                    LinearGradient(colors: [.indigo.opacity(0.95), .teal.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                )
                .navigationTitle("Presencia")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            PresenciaStatsView(embeddedInNavigation: true)
                        } label: {
                            Image(systemName: "chart.bar.xaxis")
                        }
                        .accessibilityLabel("Estadísticas")
                    }
                }
                .alert("Presencia", isPresented: $showSavedFeedback) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(feedbackText)
                }
                .onAppear(perform: reload)
                .onReceive(NotificationCenter.default.publisher(for: .presenciaEventsDidChange)) { _ in
                    reload()
                }
            } else {
                PurchaseView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vuelve al Presente")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text("Hoy has vuelto al presente \(todayPresentCount) veces.")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
        }
    }

    private var mainAction: some View {
        Button {
            registerPresent(mood: nil)
        } label: {
            Label("Vuelvo al Presente", systemImage: "sparkles")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(.borderedProminent)
        .tint(.mint)
        .foregroundStyle(.black)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var moodList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Estado de ánimo")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVStack(spacing: 10) {
                ForEach(PresenciaMood.common) { mood in
                    Button {
                        registerPresent(mood: mood)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mood.symbolName)
                                .frame(width: 24)
                            Text(mood.title)
                                .font(.body.weight(.medium))
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func registerPresent(mood: PresenciaMood?) {
        let saved: Bool
        if let mood {
            saved = repository.recordPresent(mood: mood, source: "iOS")
        } else {
            saved = repository.recordPresent(source: "iOS")
        }

        reload()
        feedbackText = saved ? "Registrado" : "No se pudo guardar"
        showSavedFeedback = true
    }

    private func reload() {
        todayPresentCount = repository.todayPresentCount()
    }
}
#endif


#Preview{
    PresenciaView()
}

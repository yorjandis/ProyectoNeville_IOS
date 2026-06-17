import SwiftUI

struct PresenceWatchView: View {
    @StateObject private var modelWatch = watchModel.shared
    @State private var showMoodList = false
    @State private var showSavedFeedback = false
    @State private var feedbackText = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .teal], startPoint: .top, endPoint: .bottom)

            VStack(spacing: 10) {
                Text("Presencia")
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                    .bold()
                    .padding(.top, 6)

                Spacer(minLength: 0)

                Button {
                    registerPresenceReturn()
                } label: {
                    Label("Vuelvo al Presente", systemImage: "sparkles")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .foregroundStyle(.black)

                Button {
                    showMoodList = true
                } label: {
                    Label("Estado de Ánimo", systemImage: "heart.text.square.fill")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.82))
                .foregroundStyle(.black)

                Spacer(minLength: 0)

                Text("Hoy: \(modelWatch.todayPresenceReturnCount) regresos")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $showMoodList) {
            PresenceMoodListView { mood in
                registerMood(mood)
                showMoodList = false
            }
        }
        .alert("Presencia", isPresented: $showSavedFeedback) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(feedbackText)
        }
        .onAppear {
            modelWatch.refreshTodayPresenceReturnCount()
        }
    }

    private func registerPresenceReturn() {
        if modelWatch.recordPresenceReturn() {
            feedbackText = "Registrado"
        } else {
            feedbackText = "No se pudo guardar"
        }
        showSavedFeedback = true
    }

    private func registerMood(_ mood: WatchPresenceMood) {
        if modelWatch.recordPresenceMood(mood) {
            feedbackText = mood.countsAsInconsciente ? "Observado con amabilidad" : "Estado guardado"
        } else {
            feedbackText = "No se pudo guardar"
        }
        showSavedFeedback = true
    }
}

private struct PresenceMoodListView: View {
    let onSelect: (WatchPresenceMood) -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .teal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            List(WatchPresenceMood.common) { mood in
                Button {
                    onSelect(mood)
                } label: {
                    Label(mood.title, systemImage: mood.symbolName)
                        .foregroundStyle(.black)
                }
            }
            .navigationTitle("Estado")
        }
    }
}

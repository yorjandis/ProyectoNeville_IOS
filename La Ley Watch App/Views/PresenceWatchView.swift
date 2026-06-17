import SwiftUI

struct PresenceWatchView: View {
    @StateObject private var modelWatch = watchModel.shared
    @State private var showPresenceDetail = false
    @State private var showSavedFeedback = false
    @State private var feedbackText = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .teal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 10) {
                Text("Presencia")
                    .fontDesign(.serif)
                    .foregroundStyle(.white)
                    .bold()
                    .padding(.top, 6)

                Spacer(minLength: 0)

                Button {
                    showPresenceDetail = true
                } label: {
                    Label("Vuelvo al Presente", systemImage: "sparkles")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 60)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .foregroundStyle(.black)

                Spacer(minLength: 0)

                Text("Hoy: \(modelWatch.todayPresenceReturnCount) regresos")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 10)
        }
        .sheet(isPresented: $showPresenceDetail) {
            PresenceMoodSelectionView(
                onClose: {
                    registerPresenceReturn()
                    showPresenceDetail = false
                },
                onSelectMood: { mood in
                    registerPresenceReturn(mood: mood)
                    showPresenceDetail = false
                }
            )
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
        registerPresenceReturn(mood: nil)
    }

    private func registerPresenceReturn(mood: WatchPresenceMood?) {
        if modelWatch.recordPresenceReturn(mood: mood) {
            feedbackText = mood == nil ? "Registrado" : "Registrado con estado"
        } else {
            feedbackText = "No se pudo guardar"
        }
        showSavedFeedback = true
    }
}

private struct PresenceMoodSelectionView: View {
    let onClose: () -> Void
    let onSelectMood: (WatchPresenceMood) -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo, .teal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Button {
                    onClose()
                } label: {
                    Label("Cerrar", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 34)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.85))
                .foregroundStyle(.black)
                .padding(.horizontal, 8)
                .padding(.top, 4)

                List(WatchPresenceMood.common) { mood in
                    Button {
                        onSelectMood(mood)
                    } label: {
                        Label(mood.title, systemImage: mood.symbolName)
                            .foregroundStyle(.black)
                    }
                }
                .listStyle(.carousel)
            }
        }
    }
}


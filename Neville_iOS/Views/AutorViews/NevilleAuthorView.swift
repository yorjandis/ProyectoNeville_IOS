import SwiftUI

struct NevilleAuthorView: View {
    private enum Route: String, Identifiable {
        case biografia
        case resumenEnsenanza
        case conferencias
        case citas
        case preguntas
        case game

        var id: String { rawValue }
    }

    @State private var route: Route?

    var body: some View {
        NavigationStack {
            ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.35), Color.blue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 12) {
                        Image("nev-min")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.35), lineWidth: 1)
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Neville Goddard")
                                .font(.title)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(.white)

                            Button("Bibliografía") {
                                route = .biografia
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Resumen de enseñanza") {
                                route = .resumenEnsenanza
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .foregroundStyle(.white)
                        }
                    }

                    

                    
                    Text("Frases y Citas")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    FrasesHomeView(authorFilter: "nev")
                        .frame(height: 270)
                        .background(LinearGradient.JadeProfundo())
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Análisis de Libros")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                card(title: "Conferencias", title2: "Lista de Conferencias", resumenAction: { route = .conferencias })
                                card(title: "Citas", title2: "Citas", resumenAction: { route = .citas })
                                card(title: "Preguntas", title2: "Preguntas", resumenAction: { route = .preguntas })
                                card(title: "Evaluación", title2: "Evaluación", resumenAction: { route = .game })
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(16)
            }
        }
        }
        .sheet(item: $route) { item in
            VStack {
                switch item {
                case .biografia:
                    ContentTxtShowView(title: "Biografía de Neville Goddard", nombreTxt: AppCons.FileBiografiaNeville, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "nev-min", size: 150)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaNeville)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Neville Goddard", nombreTxt: AppCons.FileResumenEnseñanzaNeville, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaNeville)))
                    ])
                case .conferencias:
                    TxtListView(typeOfContent: .conf, title: "Conferencias")
                case .citas:
                    TxtListView(typeOfContent: .citas, title: "Citas")
                case .preguntas:
                    TxtListView(typeOfContent: .preg, title: "Preguntas")
                case .game:
                    GamePLay()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private func card(
        title: String,
        title2: String,
        title3: String = "" ,
        resumenAction: @escaping () -> Void,
        practicaAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 10) {
                Button(title2) {
                    resumenAction()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .foregroundStyle(.white)

                if let practicaAction {
                    Button(title3) {
                        practicaAction()
                    }
                    .buttonStyle(.bordered)
                    .tint(.black)
                    .foregroundStyle(.white)
                }
                
            }
            
        }
        .padding(12)
        .frame(height: 90, alignment: .topLeading)
        .background(Color.blue.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
    }
}

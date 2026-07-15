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
                colors: GradientesPreselect.G_natural_8.getColors,
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
                                .foregroundStyle(.black)

                            Button("Biografía") {
                                route = .biografia
                            }
                            .buttonStyle(.bordered)
                            .tint(.black)
                            .foregroundStyle(.white)
                            
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
                        .foregroundStyle(.black)
                    FrasesHomeView(authorFilter: "nev", colorTextAutor: .black, showAutorLabel: false, showFraseFilterControl: true)
                        .frame(height: 270)
                        .background(LinearGradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enseñanzas")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                card(title: "", buttonTitle1: "Conferencias", buttonTitle2: "", buttonAction1: { route = .conferencias })
                                card(title: "", buttonTitle1: "Citas",buttonTitle2: "", buttonAction1: { route = .citas })
                                card(title: "", buttonTitle1: "Preguntas",buttonTitle2: "", buttonAction1: { route = .preguntas })
                                card(title: "", buttonTitle1: "Evaluación",buttonTitle2: "", buttonAction1: { route = .game })
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
                    ContentTxtShowView(title: authorBiographyTitle("Neville Goddard"), nombreTxt: AppCons.FileBiografiaNeville, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "nev-min", size: 150)),
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileBiografiaNeville)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: authorTeachingSummaryTitle("Neville Goddard"), nombreTxt: AppCons.FileResumenEnseñanzaNeville, type: .NA, blocks: [
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileResumenEnseñanzaNeville)))
                    ])
                case .conferencias:
                    TxtListView(typeOfContent: .conf, title: L10n.exact("Conferencias"))
                case .citas:
                    TxtListView(typeOfContent: .citas, title: L10n.exact("Citas"))
                case .preguntas:
                    TxtListView(typeOfContent: .preg, title: L10n.exact("Preguntas"))
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
        buttonTitle1: String,
        buttonTitle2: String = "",
        buttonAction1: @escaping () -> Void,
        buttonAction2: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.black)
            }

            HStack(spacing: 10) {
                Button(L10n.exact(buttonTitle1)) {
                    buttonAction1()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .foregroundStyle(.white)

                if !buttonTitle2.isEmpty {
                    Button(L10n.exact(buttonTitle2)) {
                        buttonAction2?()
                    }
                    .buttonStyle(.bordered)
                    .tint(.black)
                    .foregroundStyle(.white)
                }
            }
        }
        .padding(12)
        .frame(height: 90, alignment: .topLeading)
        .background(Color.blue.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.22), lineWidth: 1)
        }
    }
}

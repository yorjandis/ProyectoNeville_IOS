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

}

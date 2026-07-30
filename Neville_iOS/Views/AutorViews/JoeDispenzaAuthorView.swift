import SwiftUI

struct JoeDispenzaAuthorView: View {
    private enum Route: String, Identifiable {
        case biografia
        case resumenEnsenanza
        case resumenDesarrollaTuCerebro
        case planDesarrollaTuCerebro
        case resumenDejaDeSerTu
        case planDejaDeSerTu
        case resumenElPlaceboEresTu
        case planElPlaceboEresTu
        case resumenSuperNatural
        case planSuperNatural
        case serieLaFormulaMenu
        case serieLaFormula1
        case serieLaFormula2
        case serieLaFormula3
        case serieLaFormula4
        case serieLaFormula5
        case serieLaFormula6
        case serieLaFormula7
        case serieLaFormula8
        case serieLaFormula9
        case serieLaFormula10
        case serieLaFormula11
        case serieLaFormula12
#if os(iOS)
        case protocoloTransformacion
#endif

        var id: String { rawValue }
    }

    @State private var route: Route?

    private var serieLaFormulaCapitulos: [(title: String, route: Route)] {
        [
            (authorChapterTitle(1), .serieLaFormula1),
            (authorChapterTitle(2), .serieLaFormula2),
            (authorChapterTitle(3), .serieLaFormula3),
            (authorChapterTitle(4), .serieLaFormula4),
            (authorChapterTitle(5), .serieLaFormula5),
            (authorChapterTitle(6), .serieLaFormula6),
            (authorChapterTitle(7), .serieLaFormula7),
            (authorChapterTitle(8), .serieLaFormula8),
            (authorChapterTitle(9), .serieLaFormula9),
            (authorChapterTitle(10), .serieLaFormula10),
            (authorChapterTitle(11), .serieLaFormula11),
            (authorChapterTitle(12), .serieLaFormula12)
        ]
    }
    
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
                        Image("jd")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.35), lineWidth: 1)
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Joe Dispenza")
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

#if os(iOS)
                    Button {
                        route = .protocoloTransformacion
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(.white.opacity(0.22))
                                Image(systemName: "point.3.connected.trianglepath.dotted")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.exact("Transformación personal · 21 días"))
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text(L10n.exact("Práctica guiada, P.A.R.A., diario y seguimiento"))
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.82))
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 6)

                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TransformationProtocolTheme.accessGradient())
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.14), radius: 12, y: 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(L10n.exact("Abre el protocolo integral de transformación"))
#endif

                    
                    Text("Frases y Citas")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                    
                    FrasesHomeView(authorFilter: "jd", colorTextAutor: .black, showAutorLabel: false, showFraseFilterControl: true)
                        .frame(height: 270)
                        .background(LinearGradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resumen de Libros")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                card(title: "Desarrolla Tu Cerebro",buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenDesarrollaTuCerebro }, buttonAction2: { route = .planDesarrollaTuCerebro })
                                card(title: "Deja De Ser Tu", buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenDejaDeSerTu }, buttonAction2: { route = .planDejaDeSerTu })
                                card(title: "El Placebo Eres Tu",buttonTitle1: "Resumen", buttonTitle2: "Práctica",  buttonAction1: { route = .resumenElPlaceboEresTu }, buttonAction2: { route = .planElPlaceboEresTu })
                                card(title: "SobreNatural",buttonTitle1: "Resumen", buttonTitle2: "Práctica",  buttonAction1: { route = .resumenSuperNatural }, buttonAction2: { route = .planSuperNatural })
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Enseñanzas")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)

                        ScrollView(.horizontal, showsIndicators: false) {
                            
                            HStack(spacing: 12) {
                                card(title: authorSeriesTitle("La Fórmula"), buttonTitle1: "Capítulos", buttonAction1: { route = .serieLaFormulaMenu })
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
                    ContentTxtShowView(title: authorBiographyTitle("Joe Dispenza"), nombreTxt: AppCons.FileBiografiaJD, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "jd", size: 100)),
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileBiografiaJD)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: authorTeachingSummaryTitle("Joe Dispenza"), nombreTxt: AppCons.FileResumenEnseñanzaJD, type: .NA, blocks: [
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileResumenEnseñanzaJD)))
                    ], checkPremium: false)
                case .resumenDesarrollaTuCerebro:
                    ContentTxtShowView(title: authorBookSummaryTitle("Desarrolla Tu Cerebro"), nombreTxt: AppCons.FileResumenDesarrollaTuCerebro, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDesarrollaTuCerebro)))
                    ], checkPremium: false)
                case .planDesarrollaTuCerebro:
                    ContentTxtShowView(title: authorBookPlanTitle("Desarrolla Tu Cerebro"), nombreTxt: AppCons.FilePlanDesarrollaTuCerebro, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDesarrollaTuCerebro)))
                    ], checkPremium: false)
                case .resumenDejaDeSerTu:
                    ContentTxtShowView(title: authorBookSummaryTitle("Deja De Ser Tu"), nombreTxt: AppCons.FileResumenDejaDeSerTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDejaDeSerTu)))
                    ], checkPremium: false)
                case .planDejaDeSerTu:
                    ContentTxtShowView(title: authorBookPlanTitle("Deja De Ser Tu"), nombreTxt: AppCons.FilePlanDejaDeSerTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDejaDeSerTu)))
                    ], checkPremium: false)
                case .resumenElPlaceboEresTu:
                    ContentTxtShowView(title: authorBookSummaryTitle("El Placebo Eres Tu"), nombreTxt: AppCons.FileResumenElPLaceboEresTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenElPLaceboEresTu)))
                    ], checkPremium: false)
                case .planElPlaceboEresTu:
                    ContentTxtShowView(title: authorBookPlanTitle("El Placebo Eres Tu"), nombreTxt: AppCons.FilePlanElPlaceboEresTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanElPlaceboEresTu)))
                    ], checkPremium: false)
                case .resumenSuperNatural:
                    ContentTxtShowView(title: authorBookSummaryTitle("SobreNatural"), nombreTxt: AppCons.FileResumenSuperNatural, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenSuperNatural)))
                    ], checkPremium: false)
                case .planSuperNatural:
                    ContentTxtShowView(title: authorBookPlanTitle("SobreNatural"), nombreTxt: AppCons.FilePlanSupernarural, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanSupernarural)))
                    ], checkPremium: false)
                case .serieLaFormulaMenu:
                    NavigationStack {
                        List(serieLaFormulaCapitulos, id: \.title) { capitulo in
                            Button(capitulo.title) {
                                route = capitulo.route
                            }
                        }
                        .navigationTitle(authorSeriesTitle("La Fórmula"))
#if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                    }
                case .serieLaFormula1:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 1), nombreTxt: AppCons.FileSerieLaFormula_1, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_1)))
                    ], checkPremium: false)
                case .serieLaFormula2:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 2), nombreTxt: AppCons.FileSerieLaFormula_2, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_2)))
                    ], checkPremium: false)
                case .serieLaFormula3:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 3), nombreTxt: AppCons.FileSerieLaFormula_3, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_3)))
                    ], checkPremium: false)
                case .serieLaFormula4:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 4), nombreTxt: AppCons.FileSerieLaFormula_4, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_4)))
                    ], checkPremium: false)
                case .serieLaFormula5:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 5), nombreTxt: AppCons.FileSerieLaFormula_5, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_5)))
                    ], checkPremium: false)
                case .serieLaFormula6:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 6), nombreTxt: AppCons.FileSerieLaFormula_6, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_6)))
                    ], checkPremium: false)
                case .serieLaFormula7:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 7), nombreTxt: AppCons.FileSerieLaFormula_7, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_7)))
                    ], checkPremium: false)
                case .serieLaFormula8:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 8), nombreTxt: AppCons.FileSerieLaFormula_8, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_8)))
                    ], checkPremium: false)
                case .serieLaFormula9:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 9), nombreTxt: AppCons.FileSerieLaFormula_9, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_9)))
                    ], checkPremium: false)
                case .serieLaFormula10:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 10), nombreTxt: AppCons.FileSerieLaFormula_10, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_10)))
                    ], checkPremium: false)
                case .serieLaFormula11:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 11), nombreTxt: AppCons.FileSerieLaFormula_11, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_11)))
                    ], checkPremium: false)
                case .serieLaFormula12:
                    ContentTxtShowView(title: authorSeriesChapterTitle("La Fórmula", number: 12), nombreTxt: AppCons.FileSerieLaFormula_12, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_12)))
                    ], checkPremium: false)
#if os(iOS)
                case .protocoloTransformacion:
                    TransformationProtocolView()
#endif
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
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.black)

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

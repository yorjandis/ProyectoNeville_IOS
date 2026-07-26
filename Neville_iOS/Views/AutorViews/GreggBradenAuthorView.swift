import SwiftUI

struct GreggBradenAuthorView: View {
    private enum Route: String, Identifiable {
        case biografia
        case resumenEnsenanza
        case resumenLaMatrizDivina
        case planLaMatrizDivina
        case resumenResilienciaDesdeCorazon
        case planResilienciaDesdeCorazon
        case resumenPuramenteHumanos
        case planPuramenteHumanos

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
                        Image("gregg")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.35), lineWidth: 1)
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Gregg Braden")
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
                    
                    FrasesHomeView(authorFilter: "gregg", colorTextAutor: .black, showAutorLabel: false, showFraseFilterControl: true)
                        .frame(height: 320)
                        .background(LinearGradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Resumen de Libros")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.black)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                card(title: "La Matriz Divina",buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenLaMatrizDivina }, buttonAction2: { route = .planLaMatrizDivina })
                                card(title: "Resiliencia Desde El Corazón",buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenResilienciaDesdeCorazon }, buttonAction2: { route = .planResilienciaDesdeCorazon })
                                card(title: "Puramente Humanos",buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenPuramenteHumanos }, buttonAction2: { route = .planPuramenteHumanos })
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
                    ContentTxtShowView(title: authorBiographyTitle("Gregg Braden"), nombreTxt: AppCons.FileBiografiaGregg, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "gregg", size: 100)),
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileBiografiaGregg)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: authorTeachingSummaryTitle("Gregg Braden"), nombreTxt: AppCons.FileResumenEnseñanzaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(L10n.textResource(named: AppCons.FileResumenEnseñanzaGregg)))
                    ], checkPremium: false)
                case .resumenLaMatrizDivina:
                    ContentTxtShowView(title: authorBookSummaryTitle("La Matriz Divina"), nombreTxt: AppCons.FileResumenLaMatrizDivinaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenLaMatrizDivinaGregg)))
                    ], checkPremium: false)
                case .planLaMatrizDivina:
                    ContentTxtShowView(title: authorBookPlanTitle("La Matriz Divina"), nombreTxt: AppCons.FilePlanLaMatrizDivinaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanLaMatrizDivinaGregg)))
                    ], checkPremium: false)
                case .resumenResilienciaDesdeCorazon:
                    ContentTxtShowView(title: authorBookSummaryTitle("Resiliencia Desde El Corazón"), nombreTxt: AppCons.FileResumenResilenciaCorazonGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenResilenciaCorazonGregg)))
                    ], checkPremium: false)
                case .planResilienciaDesdeCorazon:
                    ContentTxtShowView(title: authorBookPlanTitle("Resiliencia Desde El Corazón"), nombreTxt: AppCons.FilePlanResilenciaCorazonGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanResilenciaCorazonGregg)))
                    ], checkPremium: false)
                case .resumenPuramenteHumanos:
                    ContentTxtShowView(title: authorBookSummaryTitle("Puramente Humanos"), nombreTxt: AppCons.FileResumenPuramenteHumanosGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenPuramenteHumanosGregg)))
                    ], checkPremium: false)
                case .planPuramenteHumanos:
                    ContentTxtShowView(title: authorBookPlanTitle("Puramente Humanos"), nombreTxt: AppCons.FilePlanPuramenteHumanosGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanPuramenteHumanosGregg)))
                    ], checkPremium: false)
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

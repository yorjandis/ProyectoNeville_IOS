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

        var id: String { rawValue }
    }

    @State private var route: Route?

    private var serieLaFormulaCapitulos: [(title: String, route: Route)] {
        [
            ("Capítulo 1", .serieLaFormula1),
            ("Capítulo 2", .serieLaFormula2),
            ("Capítulo 3", .serieLaFormula3),
            ("Capítulo 4", .serieLaFormula4),
            ("Capítulo 5", .serieLaFormula5),
            ("Capítulo 6", .serieLaFormula6),
            ("Capítulo 7", .serieLaFormula7),
            ("Capítulo 8", .serieLaFormula8),
            ("Capítulo 9", .serieLaFormula9),
            ("Capítulo 10", .serieLaFormula10),
            ("Capítulo 11", .serieLaFormula11),
            ("Capítulo 12", .serieLaFormula12)
        ]
    }
    
    //Funciones premium
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @State private var showSheetPremiun : Bool = false

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

                            Button("Bibliografía") {
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
                    
                    if purchaseStatus || self.yorjPremium{
                        FrasesHomeView(authorFilter: "jd", colorTextAutor: .black, showAutorLabel: false, showFraseFilterControl: true)
                            .frame(height: 270)
                            .background(LinearGradient(colors: [Color.black.opacity(0.1), Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }else{
                        
                        VStack{
                            Spacer()
                            Button("Las Frases y enseñanzas del Dr. Joe Dispenza están disponibles en la Versión Extendida"){
                                self.showSheetPremiun = true
                            }
                            .font(.system(size: 22))
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .padding(12)
                        .frame(height: 270, alignment: .topLeading)
                        .background(LinearGradient.JadeProfundo())
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.22), lineWidth: 1)
                        }
                        
                        
                    }
                    

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
                                card(title: "Serie La Fórmula", buttonTitle1: "Capítulos", buttonAction1: { route = .serieLaFormulaMenu })
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
                    ContentTxtShowView(title: "Biografía Joe Dispenza", nombreTxt: AppCons.FileBiografiaJD, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "jd", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaJD)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Joe Dispenza", nombreTxt: AppCons.FileResumenEnseñanzaJD, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaJD)))
                    ], checkPremium: true)
                case .resumenDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Resumen del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FileResumenDesarrollaTuCerebro, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDesarrollaTuCerebro)))
                    ], checkPremium: true)
                case .planDesarrollaTuCerebro:
                    ContentTxtShowView(title: "Plan del Libro: Desarrolla Tu Cerebro", nombreTxt: AppCons.FilePlanDesarrollaTuCerebro, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDesarrollaTuCerebro)))
                    ], checkPremium: true)
                case .resumenDejaDeSerTu:
                    ContentTxtShowView(title: "Resumen del Libro: Deja De Ser Tu", nombreTxt: AppCons.FileResumenDejaDeSerTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenDejaDeSerTu)))
                    ], checkPremium: true)
                case .planDejaDeSerTu:
                    ContentTxtShowView(title: "Plan del Libro: Deja De Ser Tu", nombreTxt: AppCons.FilePlanDejaDeSerTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanDejaDeSerTu)))
                    ], checkPremium: true)
                case .resumenElPlaceboEresTu:
                    ContentTxtShowView(title: "Resumen del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FileResumenElPLaceboEresTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenElPLaceboEresTu)))
                    ], checkPremium: true)
                case .planElPlaceboEresTu:
                    ContentTxtShowView(title: "Plan del Libro: El Placebo Eres Tu", nombreTxt: AppCons.FilePlanElPlaceboEresTu, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanElPlaceboEresTu)))
                    ], checkPremium: true)
                case .resumenSuperNatural:
                    ContentTxtShowView(title: "Resumen del Libro: SobreNatural", nombreTxt: AppCons.FileResumenSuperNatural, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenSuperNatural)))
                    ], checkPremium: true)
                case .planSuperNatural:
                    ContentTxtShowView(title: "Plan del Libro: SobreNatural", nombreTxt: AppCons.FilePlanSupernarural, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanSupernarural)))
                    ], checkPremium: true)
                case .serieLaFormulaMenu:
                    NavigationStack {
                        List(serieLaFormulaCapitulos, id: \.title) { capitulo in
                            Button(capitulo.title) {
                                route = capitulo.route
                            }
                        }
                        .navigationTitle("Serie La Fórmula")
#if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                    }
                case .serieLaFormula1:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 1", nombreTxt: AppCons.FileSerieLaFormula_1, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_1)))
                    ], checkPremium: true)
                case .serieLaFormula2:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 2", nombreTxt: AppCons.FileSerieLaFormula_2, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_2)))
                    ], checkPremium: true)
                case .serieLaFormula3:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 3", nombreTxt: AppCons.FileSerieLaFormula_3, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_3)))
                    ], checkPremium: true)
                case .serieLaFormula4:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 4", nombreTxt: AppCons.FileSerieLaFormula_4, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_4)))
                    ], checkPremium: true)
                case .serieLaFormula5:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 5", nombreTxt: AppCons.FileSerieLaFormula_5, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_5)))
                    ], checkPremium: true)
                case .serieLaFormula6:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 6", nombreTxt: AppCons.FileSerieLaFormula_6, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_6)))
                    ], checkPremium: true)
                case .serieLaFormula7:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 7", nombreTxt: AppCons.FileSerieLaFormula_7, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_7)))
                    ], checkPremium: true)
                case .serieLaFormula8:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 8", nombreTxt: AppCons.FileSerieLaFormula_8, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_8)))
                    ], checkPremium: true)
                case .serieLaFormula9:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 9", nombreTxt: AppCons.FileSerieLaFormula_9, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_9)))
                    ], checkPremium: true)
                case .serieLaFormula10:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 10", nombreTxt: AppCons.FileSerieLaFormula_10, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_10)))
                    ], checkPremium: true)
                case .serieLaFormula11:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 11", nombreTxt: AppCons.FileSerieLaFormula_11, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_11)))
                    ], checkPremium: true)
                case .serieLaFormula12:
                    ContentTxtShowView(title: "Serie La Fórmula: Capítulo 12", nombreTxt: AppCons.FileSerieLaFormula_12, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieLaFormula_12)))
                    ], checkPremium: true)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: self.$showSheetPremiun) {
            PurchaseView()
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
                Button(buttonTitle1) {
                    buttonAction1()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .foregroundStyle(.white)

                if !buttonTitle2.isEmpty {
                    Button(buttonTitle2) {
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

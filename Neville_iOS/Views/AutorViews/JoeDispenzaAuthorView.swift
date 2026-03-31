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

        var id: String { rawValue }
    }

    @State private var route: Route?
    
    //Funciones premium
    @AppStorage("purchaseStatus" ) var purchaseStatus: Bool = false
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: AppCons.AppGroupName))var yorjPremium: Bool = false
    
    @State private var showSheetPremiun : Bool = false

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
                    
                    if purchaseStatus || self.yorjPremium{
                        FrasesHomeView(authorFilter: "jd")
                            .frame(height: 270)
                            .background(LinearGradient.JadeProfundo())
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
                        Text("Análisis de Libros")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)

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
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: self.$showSheetPremiun) {
            PurchaseView()
        }
    }

   
}

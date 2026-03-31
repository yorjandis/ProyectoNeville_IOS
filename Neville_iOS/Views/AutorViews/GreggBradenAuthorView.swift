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
                    
                    if self.purchaseStatus || self.yorjPremium{
                        FrasesHomeView(authorFilter: "gregg")
                            .frame(height: 320)
                            .background(LinearGradient.JadeProfundo())
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }else{
                        
                        VStack{
                            Spacer()
                            Button("Las Frases y enseñanzas de Gregg Braden están disponibles en la Versión Extendida"){
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
                                card(title: "La Matriz Divina",title2: "Resumen", title3: "Práctica", resumenAction: { route = .resumenLaMatrizDivina }, practicaAction: { route = .planLaMatrizDivina })
                                card(title: "Resiliencia Desde El Corazón",title2: "Resumen", title3: "Práctica", resumenAction: { route = .resumenResilienciaDesdeCorazon }, practicaAction: { route = .planResilienciaDesdeCorazon })
                                card(title: "Puramente Humanos",title2: "Resumen", title3: "Práctica", resumenAction: { route = .resumenPuramenteHumanos }, practicaAction: { route = .planPuramenteHumanos })
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
                    ContentTxtShowView(title: "Biografía Gregg Braden", nombreTxt: AppCons.FileBiografiaGregg, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "gregg", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaGregg)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaGregg)))
                    ], checkPremium: true)
                case .resumenLaMatrizDivina:
                    ContentTxtShowView(title: "Resumen del Libro: La Matriz Divina", nombreTxt: AppCons.FileResumenLaMatrizDivinaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenLaMatrizDivinaGregg)))
                    ], checkPremium: true)
                case .planLaMatrizDivina:
                    ContentTxtShowView(title: "Plan del Libro: La Matriz Divina", nombreTxt: AppCons.FilePlanLaMatrizDivinaGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanLaMatrizDivinaGregg)))
                    ], checkPremium: true)
                case .resumenResilienciaDesdeCorazon:
                    ContentTxtShowView(title: "Resumen del Libro: Resilencia desde el Corazón", nombreTxt: AppCons.FileResumenResilenciaCorazonGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenResilenciaCorazonGregg)))
                    ], checkPremium: true)
                case .planResilienciaDesdeCorazon:
                    ContentTxtShowView(title: "Plan del Libro: Resilencia desde el Corazón", nombreTxt: AppCons.FilePlanResilenciaCorazonGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanResilenciaCorazonGregg)))
                    ], checkPremium: true)
                case .resumenPuramenteHumanos:
                    ContentTxtShowView(title: "Resumen del Libro: Puramente Humanos", nombreTxt: AppCons.FileResumenPuramenteHumanosGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenPuramenteHumanosGregg)))
                    ], checkPremium: true)
                case .planPuramenteHumanos:
                    ContentTxtShowView(title: "Plan del Libro: Puramente Humanos", nombreTxt: AppCons.FilePlanPuramenteHumanosGregg, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanPuramenteHumanosGregg)))
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
        title2: String,
        title3: String = "",
        resumenAction: @escaping () -> Void,
        practicaAction: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.black)
            
            HStack(spacing: 10) {
                Button("Resumen") {
                    resumenAction()
                }
                .buttonStyle(.bordered)
                .tint(.black)
                .foregroundStyle(.white)

                if !title3.isEmpty {
                    Button("Práctica") {
                        if let practicaAction {
                            practicaAction()
                        }
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

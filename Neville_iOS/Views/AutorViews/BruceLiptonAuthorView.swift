import SwiftUI

struct BruceLiptonAuthorView: View {
    private enum Route: String, Identifiable {
        case biografia
        case resumenEnsenanza
        case resumenLibroBiologiaCreencia
        case planLibroBiologiaCreencia
        case resumenLibroBiologiaTransformacion
        case planLibroBiologiaTransformacion
        case serieEvolucionInteriorMenu
        case serieEvolucionInterior1
        case serieEvolucionInterior2
        case serieEvolucionInterior3
        case serieEvolucionInterior4
        case serieEvolucionInterior5
        case serieEvolucionInterior6
        case serieEvolucionInterior7
        case serieEvolucionInterior8
        case serieEvolucionInterior9
        case serieEvolucionInterior10
        case serieEvolucionInterior11
        case serieEvolucionInterior12
        case serieEvolucionInterior13

        var id: String { rawValue }
    }

    @State private var route: Route?

    private var serieCapitulos: [(title: String, route: Route)] {
        [
            ("Capítulo 1", .serieEvolucionInterior1),
            ("Capítulo 2", .serieEvolucionInterior2),
            ("Capítulo 3", .serieEvolucionInterior3),
            ("Capítulo 4", .serieEvolucionInterior4),
            ("Capítulo 5", .serieEvolucionInterior5),
            ("Capítulo 6", .serieEvolucionInterior6),
            ("Capítulo 7", .serieEvolucionInterior7),
            ("Capítulo 8", .serieEvolucionInterior8),
            ("Capítulo 9", .serieEvolucionInterior9),
            ("Capítulo 10", .serieEvolucionInterior10),
            ("Capítulo 11", .serieEvolucionInterior11),
            ("Capítulo 12", .serieEvolucionInterior12),
            ("Capítulo 13", .serieEvolucionInterior13)
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
                        Image("bruce")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay {
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.35), lineWidth: 1)
                            }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bruce Lipton")
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
                    
                    if (self.purchaseStatus || self.yorjPremium){
                        FrasesHomeView(authorFilter: "bruceL", colorTextAutor: .black, showAutorLabel: false)
                            .frame(height: 320)
                            .background(LinearGradient(colors: [Color.black.opacity(0.08), Color.black.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }else{
                        
                        VStack{
                            Spacer()
                            Button("Las Frases y enseñanzas de Dr. Bruce Lipton están disponibles en la Versión Extendida"){
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
                                card(title: "La Biología De La Creencia", buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenLibroBiologiaCreencia }, buttonAction2: { route = .planLibroBiologiaCreencia })
                                card(title: "La Biología de la Transformación", buttonTitle1: "Resumen", buttonTitle2: "Práctica", buttonAction1: { route = .resumenLibroBiologiaTransformacion }, buttonAction2: { route = .planLibroBiologiaTransformacion })
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
                                card(title: "Serie Evolución Interior",buttonTitle1: "Capítulos", buttonAction1: { route = .serieEvolucionInteriorMenu })
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
                    ContentTxtShowView(title: "Biografía Dr. Bruce H. Lipton", nombreTxt: AppCons.FileBiografiaBruce, type: .NA, blocks: [
                        ContentBlock(content: .imageLocal(name: "bruce", size: 100)),
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileBiografiaBruce)))
                    ])
                case .resumenEnsenanza:
                    ContentTxtShowView(title: "Resumen de la enseñanza: Gregg Braden", nombreTxt: AppCons.FileResumenEnseñanzaBruce, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenEnseñanzaBruce)))
                    ], checkPremium: true)
                case .resumenLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Resumen del Libro: La Biología De La Creencia", nombreTxt: AppCons.FileResumenBiologiaCreencia, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenBiologiaCreencia)))
                    ], checkPremium: true)
                case .planLibroBiologiaCreencia:
                    ContentTxtShowView(title: "Plan del Libro: La Biología De La Creencia", nombreTxt: AppCons.FilePlanBiologiaCrrencia, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanBiologiaCrrencia)))
                    ], checkPremium: true)
                case .resumenLibroBiologiaTransformacion:
                    ContentTxtShowView(title: "Resumen del Libro: La Biología de la Transformación", nombreTxt: AppCons.FileResumenBiologiaTransformacion, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileResumenBiologiaTransformacion)))
                    ], checkPremium: true)
                case .planLibroBiologiaTransformacion:
                    ContentTxtShowView(title: "Plan del Libro: La Biología de la Transformación", nombreTxt: AppCons.FilePlanBiologiaTransformacion, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FilePlanBiologiaTransformacion)))
                    ], checkPremium: true)
                case .serieEvolucionInteriorMenu:
                    NavigationStack {
                        List(serieCapitulos, id: \.title) { capitulo in
                            Button(capitulo.title) {
                                route = capitulo.route
                            }
                        }
                        .navigationTitle("Serie Evolución Interior")
#if !os(macOS)
                        .navigationBarTitleDisplayMode(.inline)
#endif
                    }
                case .serieEvolucionInterior1:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 1", nombreTxt: AppCons.FileSerieEvolucionInterior_1, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_1)))
                    ], checkPremium: true)
                case .serieEvolucionInterior2:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 2", nombreTxt: AppCons.FileSerieEvolucionInterior_2, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_2)))
                    ], checkPremium: true)
                case .serieEvolucionInterior3:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 3", nombreTxt: AppCons.FileSerieEvolucionInterior_3, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_3)))
                    ], checkPremium: true)
                case .serieEvolucionInterior4:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 4", nombreTxt: AppCons.FileSerieEvolucionInterior_4, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_4)))
                    ], checkPremium: true)
                case .serieEvolucionInterior5:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 5", nombreTxt: AppCons.FileSerieEvolucionInterior_5, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_5)))
                    ], checkPremium: true)
                case .serieEvolucionInterior6:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 6", nombreTxt: AppCons.FileSerieEvolucionInterior_6, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_6)))
                    ], checkPremium: true)
                case .serieEvolucionInterior7:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 7", nombreTxt: AppCons.FileSerieEvolucionInterior_7, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_7)))
                    ], checkPremium: true)
                case .serieEvolucionInterior8:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 8", nombreTxt: AppCons.FileSerieEvolucionInterior_8, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_8)))
                    ], checkPremium: true)
                case .serieEvolucionInterior9:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 9", nombreTxt: AppCons.FileSerieEvolucionInterior_9, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_9)))
                    ], checkPremium: true)
                case .serieEvolucionInterior10:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 10", nombreTxt: AppCons.FileSerieEvolucionInterior_10, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_10)))
                    ], checkPremium: true)
                case .serieEvolucionInterior11:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 11", nombreTxt: AppCons.FileSerieEvolucionInterior_11, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_11)))
                    ], checkPremium: true)
                case .serieEvolucionInterior12:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 12", nombreTxt: AppCons.FileSerieEvolucionInterior_12, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_12)))
                    ], checkPremium: true)
                case .serieEvolucionInterior13:
                    ContentTxtShowView(title: "Serie Evolución Interior: Capítulo 13", nombreTxt: AppCons.FileSerieEvolucionInterior_13, type: .NA, blocks: [
                        ContentBlock(content: .text(UtilFuncs.FileRead(AppCons.FileSerieEvolucionInterior_13)))
                    ])
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

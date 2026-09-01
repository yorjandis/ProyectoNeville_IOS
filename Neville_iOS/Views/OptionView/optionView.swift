//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

enum TipeViewOptionTab: String, Identifiable, CaseIterable {
    case lecturas
    case notas
    case diario
    case lienzo
    case metas
    case frases
    case codeScanner
    case codeGenerate
    case game
    case ayudas
    case reflex
    case setting
    case reminder
    case premium
    case evidenciaCientifica
    case enciclopedia
    case espacioCalma
    case ritualMatutino
    case lectorEtiquetas
    case cardioCoherencia
    case agenda
    case presencia
    case revisionSemanal
    case centroSanador
    case chatIA

    case autorNeville
    case autorJoeDispenza
    case autorGreggBraden
    case autorBruceLipton

    case videosTutoriales

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lecturas: "Lecturas"
        case .notas: "Notas"
        case .diario: "Diario"
        case .lienzo: "Lienzo"
        case .metas: "Metas"
        case .frases: "Frases"
        case .codeScanner: "Lector QR"
        case .codeGenerate: "Generador QR"
        case .game: "Juego"
        case .ayudas: "Ayudas"
        case .reflex: "Reflexiones"
        case .setting: "Ajustes"
        case .reminder: "Recordatorios"
        case .premium: "Versión Extendida"
        case .evidenciaCientifica: "Evidencia Científica"
        case .enciclopedia: "Enciclopedia"
        case .espacioCalma: "Espacio de calma"
        case .ritualMatutino: "Ritual Matutino"
        case .lectorEtiquetas: "Lector de Etiquetas"
        case .cardioCoherencia: "Coherencia Cardio-Cerebral"
        case .agenda: "Agenda"
        case .presencia: "Presencia"
        case .revisionSemanal: "Resumen semanal"
        case .centroSanador: "Centro Sanador"
        case .chatIA: "Chat IA"
        case .autorNeville: "Neville Goddard"
        case .autorJoeDispenza: "Joe Dispenza"
        case .autorGreggBraden: "Gregg Braden"
        case .autorBruceLipton: "Bruce Lipton"
        case .videosTutoriales: "Videos Tutoriales"
        }
    }

    var systemImage: String {
        switch self {
        case .lecturas: "book.pages.fill"
        case .notas: "note.text"
        case .diario: "book"
        case .lienzo: "paintbrush.pointed.fill"
        case .metas: "target"
        case .frases: "quote.bubble.fill"
        case .codeScanner: "qrcode.viewfinder"
        case .codeGenerate: "qrcode"
        case .game: "gamecontroller.fill"
        case .ayudas: "questionmark.circle.fill"
        case .reflex: "brain.head.profile.fill"
        case .setting: "gearshape.fill"
        case .reminder: "bell.fill"
        case .premium: "sparkles"
        case .evidenciaCientifica: "atom"
        case .enciclopedia: "books.vertical.fill"
        case .espacioCalma: "leaf.fill"
        case .ritualMatutino: "sunrise.fill"
        case .lectorEtiquetas: "barcode.viewfinder"
        case .cardioCoherencia: "heart.circle.fill"
        case .agenda: "calendar"
        case .presencia: "figure.mind.and.body"
        case .revisionSemanal: "calendar.badge.checkmark"
        case .centroSanador: "cross.case.fill"
        case .chatIA: "ellipsis.message"
        case .autorNeville, .autorJoeDispenza, .autorGreggBraden, .autorBruceLipton:
            "person.crop.circle.fill"
        case .videosTutoriales: "play.rectangle.fill"
        }
    }

    var requiresPremium: Bool {
        premiumFeature != nil
    }

    var premiumFeature: PremiumFeatureID? {
        switch self {
        case .agenda: .agenda
        case .presencia: .consciousPresence
        case .revisionSemanal: .weeklyReview
        case .lectorEtiquetas: .labelScanner
        case .espacioCalma: .calmSpace
        case .ritualMatutino: .consciousDailyCycle
        case .cardioCoherencia: .cardioCoherence
        case .videosTutoriales: .tutorials
        case .centroSanador: .healingCenter
        case .metas: .goals
        case .lienzo: .creativeCanvas
        case .reminder: .smartReminders
        case .codeGenerate: .shareQR
        case .chatIA: .integratedAI
        default: nil
        }
    }
}

@MainActor
enum BottomBarShortcutConfiguration {
    static let defaultShortcuts: [TipeViewOptionTab] = [.lecturas, .notas, .diario, .chatIA]
    static let defaultStorageValue = defaultShortcuts.map(\.rawValue).joined(separator: ",")

    static func shortcuts(from storageValue: String) -> [TipeViewOptionTab] {
        let decoded = storageValue
            .split(separator: ",")
            .compactMap { TipeViewOptionTab(rawValue: String($0)) }

        var result: [TipeViewOptionTab] = []
        for shortcut in decoded + defaultShortcuts + TipeViewOptionTab.allCases where !result.contains(shortcut) {
            result.append(shortcut)
            if result.count == 4 { break }
        }
        return result
    }

    static func load() -> [TipeViewOptionTab] {
        let stored = UserDefaults.standard.string(forKey: AppCons.UD_setting_BottomBarShortcuts)
            ?? defaultStorageValue
        return shortcuts(from: stored)
    }

    static func save(_ shortcuts: [TipeViewOptionTab]) {
        let normalized = Array(shortcuts.prefix(4))
        UserDefaults.standard.set(
            normalized.map(\.rawValue).joined(separator: ","),
            forKey: AppCons.UD_setting_BottomBarShortcuts
        )
    }
}

struct OptionAccessDestinationView: View {
    let option: TipeViewOptionTab

    @ObservedObject var settingModel: SettingModel
    @StateObject private var clipboardModel = ClipboardObserver()

    private struct QRText: Identifiable {
        let id = UUID()
        let text: String
    }

    @State private var scannedQRText: QRText?

    var body: some View {
        Group {
            switch option {
            case .lecturas:
                TxtListView(typeOfContent: .conf, title: "Lecturas")
            case .autorNeville:
                NevilleAuthorView()
            case .autorJoeDispenza:
                JoeDispenzaAuthorView()
            case .autorGreggBraden:
                GreggBradenAuthorView()
            case .autorBruceLipton:
                BruceLiptonAuthorView()
            case .setting:
                Ajustes()
            case .notas:
                ListNotasViews()
            case .diario:
                DiarioListView()
            case .lienzo:
                LienzoMain(texto: "", imagenPrimariaACargar: nil)
            case .premium:
                PurchaseView()
            case .codeScanner:
                CodeScannerView(codeTypes: [.qr]) { result in
                    if case let .success(code) = result {
                        scannedQRText = QRText(text: code.string)
                    }
                }
            case .codeGenerate:
                GenerateQRView(footer: "")
            case .reminder:
                ReminderListView()
            case .metas:
                GoalsListView()
            case .agenda:
                AgendaMainView()
            case .presencia:
                PresenciaView()
            case .revisionSemanal:
                WeeklyReviewView()
            case .centroSanador:
                CentroSanadorView(embeddedInNavigationStack: true)
            case .enciclopedia:
                EnciclopediaListView()
            case .espacioCalma:
                EspacioCalmaView()
                    .ignoresSafeArea()
            case .ritualMatutino:
                MorningRitualMainView()
            case .lectorEtiquetas:
                LectorEtiquetasView()
            case .cardioCoherencia:
                CardioCoherenceWelcomeFlowView()
                    .ignoresSafeArea()
            case .evidenciaCientifica:
                EvidenciaCientificaView()
            case .frases:
                FrasesListView()
            case .ayudas:
                TxtListView(typeOfContent: .ayud, title: "Ayudas")
            case .reflex:
                ReflexListView()
            case .game:
                GamePLay()
            case .videosTutoriales:
                TutorialVideosListView()
            case .chatIA:
                chatDestination
            }
        }
        .sheet(item: $scannedQRText) { result in
            GenerateQRView(footer: result.text, showImage: true)
        }
        .environment(\.managedObjectContext, CoreDataController.shared.context)
        .environmentObject(settingModel)
        .environmentObject(FrasesModel.shared)
        .environmentObject(TxtContentModel.shared)
        .environmentObject(SecurityModel.shared)
        .environmentObject(ReflexModel.shared)
        .environmentObject(clipboardModel)
    }

    @ViewBuilder
    private var chatDestination: some View {
        if #available(iOS 26.0, *) {
            if IAModelAppleIntelligence.isAvailable() {
                ChatView(textoACargar: nil)
            } else {
                unavailableChatView
            }
        } else {
            unavailableChatView
        }
    }

    private var unavailableChatView: some View {
        VStack(spacing: 14) {
            Image(systemName: "ellipsis.message")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("Chat IA no disponible")
                .font(.title3.bold())
            Text("Apple Intelligence no está disponible en este dispositivo o idioma.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .navigationTitle("Chat IA")
    }
}

struct optionView: View {
    @ObservedObject var settingModel: SettingModel

    let isShowingAlternativeHome: Bool
    let toggleHomeScreen: () -> Void

    @State private var showView: TipeViewOptionTab? = nil
    @State private var selectedPremiumFeature: PremiumFeatureID?
    @State private var showEspacioCalmaFullScreen: Bool = false
    @State private var showCardioCoherenciaFullScreen: Bool = false

    @AppStorage("purchaseStatus") var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) var yorjPremium: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button {
                        self.showView = .autorNeville
                    } label: {
                        Text("Neville Goddard")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer()

                    Menu {
                        Button("Lecturas") { self.showView = .lecturas }
                        Button("Ayudas") { self.showView = .ayudas }
                        Button("Reflexiones") { self.showView = .reflex }
                        Button("Evidencia Científica") { self.showView = .evidenciaCientifica }
                        Button("Enciclopedia") { self.showView = .enciclopedia }
                        Button("Frases") { self.showView = .frases }
                        Button("Chat IA") { self.showView = .chatIA }
                    } label: {
                        Text("Recursos Didácticos")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(5)
                .padding(.top, 10)

                HStack {
                    Button {
                        self.showView = .autorJoeDispenza
                    } label: {
                        Text("Joe Dispenza")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer()

                    Menu {
                        productivityButton("Centro Sanador", option: .centroSanador)
                        productivityButton("Coherencia Cardio-Cerebral", option: .cardioCoherencia)
                        productivityButton("Lienzo", option: .lienzo)
                        productivityButton("Recordatorios", option: .reminder)
                        productivityButton("Metas", option: .metas)
                        productivityButton("Agenda", option: .agenda)
                        productivityButton("Presencia", option: .presencia)
                        productivityButton("Resumen semanal", option: .revisionSemanal)
                        productivityButton("Lector de Etiquetas", option: .lectorEtiquetas)
                        Button("Notas") { self.showView = .notas }
                        productivityButton("Espacio de calma", option: .espacioCalma)
                        productivityButton("Ritual Matutino", option: .ritualMatutino)
                        
                        Button("Lector QR") { self.showView = .codeScanner }
                        productivityButton("Generador QR", option: .codeGenerate)
                    } label: {
                        Text("Productividad")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(5)

                HStack {
                    Button {
                        self.showView = .autorGreggBraden
                    } label: {
                        Text("Gregg Braden")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer()

                    Button {
                        self.showView = .setting
                    } label: {
                        Text("Ajustes")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(5)

                HStack {
                    Button {
                        self.showView = .autorBruceLipton
                    } label: {
                        Text("Bruce Lipton")
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer()
                    
                        Button {
                            self.showView = .videosTutoriales
                        } label: {
                            Text("Videos Tutoriales")
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                    
                }
                .padding(5)
            }
            .overlay(alignment: .center) {
                Button {
                    toggleHomeScreen()
                } label: {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .offset(y: 6)
                .accessibilityLabel(isShowingAlternativeHome ? "Mostrar frases en home" : "Mostrar home alternativo")
            }
            .padding(10)
            .buttonStyle(.bordered)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .background(LinearGradient.AzulTecnologico())
        .fullScreenCover(isPresented: self.$showEspacioCalmaFullScreen) {
            EspacioCalmaView()
                .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: self.$showCardioCoherenciaFullScreen) {
            CardioCoherenceWelcomeFlowView()
                .ignoresSafeArea()
        }
        .sheet(item: self.$selectedPremiumFeature) { feature in
            PremiumFeaturePreviewView(feature: feature)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: self.$showView) { item in
            OptionAccessDestinationView(option: item, settingModel: settingModel)
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }

    @ViewBuilder
    private func productivityButton(_ title: LocalizedStringKey, option: TipeViewOptionTab) -> some View {
        Button(title) {
            openProductivityTool(option)
        }
    }

    private func openProductivityTool(_ option: TipeViewOptionTab) {
        if !(purchaseStatus || yorjPremium), let feature = option.premiumFeature {
            selectedPremiumFeature = feature
            return
        }

        switch option {
        case .espacioCalma:
            showEspacioCalmaFullScreen = true
        case .cardioCoherencia:
            showCardioCoherenciaFullScreen = true
        default:
            showView = option
        }
    }
}

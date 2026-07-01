//
//  optionView.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 20/10/23.
//

import SwiftUI

fileprivate enum TipeViewOptionTab: String, Identifiable {
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

    case autorNeville
    case autorJoeDispenza
    case autorGreggBraden
    case autorBruceLipton

    case videosTutoriales

    var id: String { rawValue }
}

struct optionView: View {
    @EnvironmentObject var settingModel: SettingModel

    let isShowingAlternativeHome: Bool
    let toggleHomeScreen: () -> Void

    @State private var showView: TipeViewOptionTab? = nil
    @State private var showEspacioCalmaFullScreen: Bool = false
    @State private var showCardioCoherenciaFullScreen: Bool = false

    @AppStorage("purchaseStatus") var purchaseStatus: Bool = false
    @AppStorage("yorjPremium", store: UserDefaults(suiteName: AppCons.AppGroupName)) var yorjPremium: Bool = false

    struct QRText: Identifiable {
        let id = UUID()
        let text: String
    }

    @State private var footerToQRCode: QRText?

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
                        Button("Ayudas") { self.showView = .ayudas }
                        Button("Reflexiones") { self.showView = .reflex }
                        Button("Evidencia Científica") { self.showView = .evidenciaCientifica }
                        Button("Enciclopedia") { self.showView = .enciclopedia }
                        Button("Frases") { self.showView = .frases }
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
                        Button("Coherencia Cardio-Cerebral") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showCardioCoherenciaFullScreen = true
                            } else {
                                self.showView = .premium
                            }
                        }
                        Button("Lienzo") { self.showView = .lienzo }
                        Button("Recordatorios") { self.showView = .reminder }
                        Button("Metas") { self.showView = .metas }
                        Button("Agenda") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showView = .agenda
                            } else {
                                self.showView = .premium
                            }
                        }
                        Button("Presencia") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showView = .presencia
                            } else {
                                self.showView = .premium
                            }
                        }
                        Button("Lector de Etiquetas") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showView = .lectorEtiquetas
                            } else {
                                self.showView = .premium
                            }
                        }
                        Button("Notas") { self.showView = .notas }
                        Button("Espacio de calma") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showEspacioCalmaFullScreen = true
                            } else {
                                self.showView = .premium
                            }
                        }
                        Button("Ritual Matutino") {
                            if self.purchaseStatus || self.yorjPremium {
                                self.showView = .ritualMatutino
                            } else {
                                self.showView = .premium
                            }
                        }
                        
                        Button("Lector QR") { self.showView = .codeScanner }
                        Button("Generador QR") { self.showView = .codeGenerate }
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

                    if self.purchaseStatus || self.yorjPremium {
                        Button {
                            self.showView = .videosTutoriales
                        } label: {
                            Text("Videos Tutoriales")
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        Button {
                            self.showView = .premium
                        } label: {
                            Text("Versión Extendida")
                                .foregroundStyle(.purple)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                        }
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
        .sheet(item: self.$showView) { item in
            VStack {
                switch item {
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
                    CodeScannerView(codeTypes: [.qr]) { qrCodeString in
                        do {
                            let result = try qrCodeString.get().string
                            self.footerToQRCode = QRText(text: result)
                        } catch {
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
                case .enciclopedia:
                    EnciclopediaListView()
                case .espacioCalma:
                    EmptyView()
                case .ritualMatutino:
                    MorningRitualMainView()
                case .lectorEtiquetas:
                    LectorEtiquetasView()
                case .cardioCoherencia:
                    CardioCoherenceWelcomeFlowView()
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
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}

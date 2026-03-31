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

    case autorNeville
    case autorJoeDispenza
    case autorGreggBraden
    case autorBruceLipton

    case videosTutoriales

    var id: String { rawValue }
}

struct optionView: View {
    @EnvironmentObject var settingModel: SettingModel

    @State private var showView: TipeViewOptionTab? = nil

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
                        Button("Notas") { self.showView = .notas }
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
                        Button("Lienzo") { self.showView = .lienzo }
                        Button("Recordatorios") { self.showView = .reminder }
                        Button("Metas") { self.showView = .metas }
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
            .padding(10)
            .buttonStyle(.bordered)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .preferredColorScheme(.dark)
        .background(LinearGradient.AzulTecnologico())
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
                case .enciclopedia:
                    EnciclopediaListView()
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
                    VStack {
                        Text("Lista de Videos Tutoriales de la las funciones extendidas")
                    }
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}

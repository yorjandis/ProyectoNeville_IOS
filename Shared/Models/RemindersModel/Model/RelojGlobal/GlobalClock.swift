//
//  GlobalClock.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 28/12/25.
//

//Crea un Timer global para la barra de progreso en recordatorios, compartido entre todas las targetas de recordatorios
/*
 📌
 ✔ Un solo timer
 ✔ Corre solo en main
 ✔ Seguro para SwiftUI
 ✔ Vive toda la app
 */


import SwiftUI
import Combine

@MainActor
final class GlobalClock: ObservableObject {

    static let shared = GlobalClock()

    @Published var now: Date = Date()

    private var timer: AnyCancellable?

    private init() {
        timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }
}

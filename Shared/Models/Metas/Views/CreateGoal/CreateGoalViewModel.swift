//
//  CreateGoalViewModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

import SwiftUI
import Combine

@MainActor
final class CreateGoalViewModel: ObservableObject {

    @Published var title: String = ""
    @Published var description: String = ""
    @Published var note: String = ""
    @Published var amount: Int = 21
    @Published var unit: TimeUnit = .dias
    @Published var frequency: Int = 1

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && amount > 0
    }
}


//
//  PremiunService.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/12/25.
//

//Para determinar si somos premium dentro de App Intent

import StoreKit

actor PremiumService {

    static let shared = PremiumService()

    private let premiumProductID = "com.ypg.nev.premium.anual"

    func hasPremiumAccess() async -> Bool {
        guard let result = await Transaction.latest(for: premiumProductID) else {
            return false
        }

        guard case .verified(let transaction) = result else {
            return false
        }

        return transaction.revocationDate == nil
    }
}


enum PremiumError: Error, CustomLocalizedStringResourceConvertible {

    case noSubscription

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noSubscription:
            return "Esta función requiere una suscripción Premium activa."
        }
    }
}

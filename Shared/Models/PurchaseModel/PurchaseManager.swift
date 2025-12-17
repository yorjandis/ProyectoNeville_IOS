//
//  PurchaseManager.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 15/12/25.
//

import StoreKit
import SwiftUI
import Combine

@MainActor
final class PurchaseManager: ObservableObject {

    @Published var isPremium: Bool = false
    @Published var products: [Product] = []

    private let premiumProductID = "com.ypg.nev.premium.anual"
    
    static let shared = PurchaseManager() //Singleton Para tener acceso global

   private init() {
        Task {
            await loadProducts()
            await updatePremiumStatus()
            listenForTransactions()
        }
    }

    // Cargar productos desde App Store
    func loadProducts() async {
        do {
            products = try await Product.products(for: [premiumProductID])
        } catch {
            print("Error cargando productos:", error)
        }
    }
}

//Comprar La suscripción Anual
extension PurchaseManager {

    func purchasePremium() async {
        guard let product = products.first else { return }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePremiumStatus()

            case .userCancelled:
                print("Usuario canceló la compra")

            case .pending:
                print("Compra pendiente")

            @unknown default:
                break
            }
        } catch {
            print("Error en la compra:", error)
        }
    }
}



//Verificación Segura de la trasacción:
extension PurchaseManager {

    enum VerificationError: Error {
        case failedVerification
    }

    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let signed):
            return signed
        case .unverified:
            throw VerificationError.failedVerification
        }
    }
}

//Determinar si el usuario es Premium:
extension PurchaseManager {

    func updatePremiumStatus() async {
        isPremium = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                if transaction.productID == premiumProductID,
                   transaction.revocationDate == nil {
                    isPremium = true
                }
            } catch {
                print("Transacción no verificada")
            }
        }
    }
}

//Escuchar Renovaciones Automáticas:
//Las suscripciones se renuevan solas, debes escucharlas
extension PurchaseManager {

    func listenForTransactions() {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                    await self.updatePremiumStatus()
                } catch {
                    print("Transacción inválida")
                }
            }
        }
    }
}

//Restaurar Compras
extension PurchaseManager {
    func restorePurchases() async {
        for await result in Transaction.currentEntitlements {
            _ = try? checkVerified(result)
        }
        await updatePremiumStatus()
    }
}


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
    private var productLoadingTask: Task<Void, Never>?
    
    static let shared = PurchaseManager() //Singleton Para tener acceso global
    
    @AppStorage("yorjPremium",store: UserDefaults(suiteName: "group.com.ypg.nev.group"))var yorjPremium: Bool = false

   private init() {
        Task {
            await loadProducts()
            await updatePremiumStatus()
            listenForTransactions()
            syncPremiumFlags()
            
        }
    }

    // Cargar productos desde App Store
    @discardableResult
    func loadProducts() async -> Bool {
        do {
            products = try await Product.products(for: [premiumProductID])
            return !products.isEmpty
        } catch {
            print("Error cargando productos:", error.localizedDescription)
            return false
        }
    }

    func startProductLoadingRetriesWhileVisible() {
        productLoadingTask?.cancel()
        productLoadingTask = Task { [weak self] in
            guard let self else { return }
            await self.retryLoadProducts()
        }
    }

    func stopProductLoadingRetries() {
        productLoadingTask?.cancel()
        productLoadingTask = nil
    }

    private func retryLoadProducts(maxAttempts: Int = 6) async {
        let retryDelaysInSeconds: [Double] = [1, 2, 4, 8, 12]
        var attempt = 0

        while !Task.isCancelled && attempt < maxAttempts {
            let didLoadProducts = await loadProducts()
            if didLoadProducts {
                return
            }

            let delay = retryDelaysInSeconds[min(attempt, retryDelaysInSeconds.count - 1)]
            attempt += 1

            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
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
                //Estableciendo el valor en UserDefault que indica premium
                UserDefaults.standard.set(true, forKey: "purchaseStatus")
                
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

        syncPremiumFlags()
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

extension PurchaseManager {
    func syncPremiumFlags() {
        let hasPremiumAccess = yorjPremium || isPremium

        UserDefaults.standard.set(hasPremiumAccess, forKey: "purchaseStatus")

        if let sharedDefaults = UserDefaults(suiteName: "group.com.ypg.nev.group") {
            sharedDefaults.set(hasPremiumAccess, forKey: "purchaseStatus")
            sharedDefaults.set(yorjPremium, forKey: "yorjPremium")
        }

        syncPremiumToCloud()
    }

    private func syncPremiumToCloud() {
        let store = NSUbiquitousKeyValueStore.default
        store.set(yorjPremium || isPremium, forKey: "purchaseStatus")
        store.set(yorjPremium, forKey: "yorjPremium")
        store.synchronize()
    }
}

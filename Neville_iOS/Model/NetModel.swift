//
//  NetModel.swift
//  Neville_iOS
//
//  Created by Yorjandis Garcia on 31/10/23.
//

import Foundation
import Network



/// Se encarga de monitorizar la conección a internet
class NetworkMonitor: ObservableObject {
    private let networkMonitor = NWPathMonitor()
    private let workerQueue = DispatchQueue(label: "Monitor")
    var isConnected = false

    init() {
        networkMonitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            Task {
                await MainActor.run {
                    self.objectWillChange.send()
                }
            }
        }
        networkMonitor.start(queue: workerQueue)
    }
}

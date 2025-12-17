//
//  ShareIMageModel.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 10/12/25.
//

import SwiftUI

@MainActor
class ShareModel: ObservableObject {
    @Published var qrImage: UIImage? = nil
    @Published var showQRCode: Bool = false
}

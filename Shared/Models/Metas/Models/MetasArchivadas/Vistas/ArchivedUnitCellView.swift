//
//  ArchivedUnitCellView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 17/2/26.
//


import SwiftUI



struct ArchivedUnitCellView: View {

    @ObservedObject var unit: ArchivedUnitEntity



    
    var body: some View {
        VStack(spacing: 8) {

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 70)


            Text(texto)
                .font(.caption.bold())
        }
        .padding(3)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(alignment: .topTrailing) {
            if hasUserNote {
                Text("N")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
                    .padding(5)
                    .accessibilityLabel("Contiene una nota")
            }
        }


    }

    private var texto: String {
        let statusEmoji: String
        switch unit.status {
        case "completed":
            statusEmoji = "🟢"
        case "lost":
            statusEmoji = "🟠"
        default: statusEmoji = "🟢"
        }
        
        return "\(GoalsL10n.unitDisplayName(unit.name, index: Int(unit.index))) \(statusEmoji)"
        
    }

    private var imageName: String {
        switch unit.status {
        case "completed": return "p_normal"
        case "lost": return "p_diarioOff"
        default:  return "p_normal"
        }
        
        
       
        
    }

    private var hasUserNote: Bool {
        !(unit.note ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
    
}

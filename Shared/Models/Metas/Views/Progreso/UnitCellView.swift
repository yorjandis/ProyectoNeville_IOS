//
//  UnitCellView.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 7/1/26.
//

//CELDA DE UNIDAD (IMAGEN + FICHAJE)

import SwiftUI



struct UnitCellView: View {

    @ObservedObject var unit: UnitEntity
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var clock = GlobalClock.shared

    
    

    var body: some View {
        VStack(spacing: 8) {

            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .opacity(isLocked ? 0.3 : 1)
                .phaseAnimator(isCurrentUnlockTarget ? [false, true] : [false]) { content, phase in
                        content
                            .offset(y: phase ? -6 : 0)
                            .opacity(phase ? 0.3 : 1)
                    } animation: { _ in
                        .easeInOut(duration: 0.9)
                    }

            Text(texto)
                .font(.caption.bold())
        }
        .padding(3)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            guard !isLocked else { return } // bloqueada
                unit.markCompleted(context: context)
        }
        

    }

    //Determina si una celda esta bloqueada
    private var isLocked: Bool {
        unit.unitStatus == .pending && !unit.canBeCompleted(now: clock.now)
    }
    
    //Para aplicar la animación solo a la celda que esta actualmente habilitada para marcar:
    //Solo una unidad puede devolver true: la primera pendiente cuya ventana de tiempo ya comenzó.
    private var isCurrentUnlockTarget: Bool {
        unit.unitStatus == .pending && unit.canBeCompleted(now: clock.now)
    }

    private var imageName: String {
        switch unit.unitStatus {
        case .completed: return "p_normal"
        case .lost: return "p_diarioOff"
        case .pending:
            return unit.canBeCompleted(now: clock.now) ? "p_normal" : "p_diario2"
        }
    }
    
    
    private var texto: String {
        let statusEmoji: String
        switch unit.unitStatus {
        case .pending:
            if clock.now > (unit.endDate ?? Date()) {
                statusEmoji = "🟠" // Unidad perdida
                unit.status = UnitStatus.lost.rawValue
                try? context.save()
            } else {
                statusEmoji = "🟤"
            }
        case .completed:
            statusEmoji = "🟢"
        case .lost:
            statusEmoji = "🟠"
        }

        return "\(unit.name ?? "Unidad") \(statusEmoji)"
        
    }
    
    
}

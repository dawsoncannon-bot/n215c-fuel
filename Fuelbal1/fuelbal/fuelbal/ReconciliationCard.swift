//
//  ReconciliationCard.swift
//  fuelbal
//
//  Created on 1/2/26.
//

import SwiftUI

/// Displays fuel reconciliation for a single leg
/// Shows tracked vs actual fuel and variance analysis
struct ReconciliationCard: View {
    let reconciliation: LegReconciliation
    
    var varianceColor: Color {
        guard let variance = reconciliation.variance else { return .secondaryText }
        
        if abs(variance) < 0.5 {
            return .green.opacity(0.8)  // Within tolerance
        } else if abs(variance) < 2.0 {
            return .yellow.opacity(0.8)  // Minor variance
        } else {
            return .orange.opacity(0.8)  // Significant variance
        }
    }
    
    var varianceIcon: String {
        guard let variance = reconciliation.variance else { return "questionmark.circle" }
        
        if abs(variance) < 0.5 {
            return "checkmark.circle.fill"  // Accurate
        } else if variance > 0 {
            return "arrow.up.circle.fill"  // Optimistic (thought we had more)
        } else {
            return "arrow.down.circle.fill"  // Conservative (thought we had less)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("LEG #\(reconciliation.legNumber)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if let location = reconciliation.fuelStop.location {
                    Text(location)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.accentText)
                }
            }
            
            // Fuel comparison
            if let actualTotal = reconciliation.actualTotal {
                VStack(spacing: 6) {
                    HStack {
                        Text("Tracked:")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f gal", reconciliation.trackedTotal))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.primaryText)
                    }
                    
                    HStack {
                        Text("Actual:")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f gal", actualTotal))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentText)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack(spacing: 6) {
                        Image(systemName: varianceIcon)
                            .font(.system(size: 12))
                            .foregroundColor(varianceColor)
                        
                        Text(reconciliation.varianceDescription)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(varianceColor)
                        
                        Spacer()
                    }
                }
                .padding(10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
            } else {
                // No reconciliation data available
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                    Text("Insufficient data for reconciliation")
                        .font(.system(size: 10, design: .monospaced))
                }
                .foregroundColor(.secondaryText.opacity(0.7))
                .italic()
            }
            
            // Per-tank breakdown (optional, collapsible)
            if let inferredFuel = reconciliation.inferredActualFuel {
                DisclosureGroup {
                    VStack(spacing: 4) {
                        ForEach(reconciliation.trackedEndingFuel.keys.sorted(), id: \.self) { tank in
                            let tracked = reconciliation.trackedEndingFuel[tank] ?? 0
                            let actual = inferredFuel[tank] ?? 0
                            let diff = tracked - actual
                            
                            HStack {
                                Text(tankLabel(tank))
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(String(format: "%.1f", tracked))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                    .frame(width: 40, alignment: .trailing)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondaryText.opacity(0.5))
                                
                                Text(String(format: "%.1f", actual))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.accentText)
                                    .frame(width: 40, alignment: .trailing)
                                
                                Spacer()
                                
                                Text(diff >= 0 ? "+\(String(format: "%.1f", diff))" : String(format: "%.1f", diff))
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(abs(diff) < 0.5 ? .green.opacity(0.6) : .orange.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    Text("Per-tank breakdown")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondaryText)
                }
                .accentColor(.accentText)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(varianceColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    func tankLabel(_ key: String) -> String {
        ["lMain": "L MAIN", "rMain": "R MAIN", "lTip": "L TIP", "rTip": "R TIP", "center": "CENTER"][key] ?? key
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        
        VStack(spacing: 16) {
            // Accurate tracking
            ReconciliationCard(reconciliation: LegReconciliation(
                legNumber: 1,
                trackedEndingFuel: ["lMain": 12.7, "rMain": 13.2, "lTip": 6.5, "rTip": 6.4],
                inferredActualFuel: ["lMain": 12.5, "rMain": 13.0, "lTip": 6.6, "rTip": 6.5],
                variance: 0.3,
                fuelStop: FuelStop(
                    fuelAdded: ["lMain": 12.3, "rMain": 11.8, "lTip": 10.5, "rTip": 10.6],
                    pricePerGallon: 6.26,
                    totalCost: 283.00,
                    location: "KLAS",
                    postFuelLevels: ["lMain": 25, "rMain": 25, "lTip": 17, "rTip": 17]
                )
            ))
            
            // Optimistic tracking
            ReconciliationCard(reconciliation: LegReconciliation(
                legNumber: 2,
                trackedEndingFuel: ["lMain": 15.2, "rMain": 14.8, "lTip": 8.1, "rTip": 8.3],
                inferredActualFuel: ["lMain": 13.1, "rMain": 12.9, "lTip": 7.2, "rTip": 7.5],
                variance: 2.3,
                fuelStop: FuelStop(
                    fuelAdded: ["lMain": 11.9, "rMain": 12.1, "lTip": 9.8, "rTip": 9.5],
                    pricePerGallon: 6.45,
                    totalCost: 336.00,
                    location: "KVGT",
                    postFuelLevels: ["lMain": 25, "rMain": 25, "lTip": 17, "rTip": 17]
                )
            ))
            
            Spacer()
        }
        .padding()
    }
}

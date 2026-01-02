//
//  TripDetailView.swift
//  fuelbal
//
//  Created on 12/31/25.
//

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    
    var avgFuelEconomy: Double {
        guard trip.totalFuelConsumed > 0 else { return 0 }
        // This would need actual distance/time data for real MPG/GPH
        // For now, showing gal per leg
        return trip.totalFuelConsumed / Double(max(1, trip.legs.count))
    }
    
    var fuelStopsWithCost: Int {
        trip.fuelStops.filter { $0.pricePerGallon != nil || $0.totalCost != nil }.count
    }
    
    var fuelStopsWithoutCost: Int {
        trip.fuelStops.filter { $0.totalAdded > 0 && $0.pricePerGallon == nil && $0.totalCost == nil }.count
    }
    
    var hasCostData: Bool {
        trip.totalMoneySpent > 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trip Summary
                        VStack(spacing: 12) {
                            Text("TRIP SUMMARY")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(2)
                            
                            HStack(spacing: 20) {
                                StatBox(label: "LEGS", value: "\(trip.legs.count)")
                                StatBox(label: "FUEL STOPS", value: "\(trip.fuelStops.count)")
                                StatBox(label: "TOTAL FUEL", value: String(format: "%.1f", trip.totalFuelConsumed))
                            }
                            
                            // Cost information (conditional)
                            if hasCostData {
                                VStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        StatBox(label: "TOTAL COST", value: "$" + String(format: "%.2f", trip.totalFuelCost))
                                        
                                        // Show partial indicator if some stops lack data
                                        if fuelStopsWithoutCost > 0 {
                                            Text("(partial)")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(.orange.opacity(0.7))
                                                .italic()
                                                .offset(y: 12)
                                        }
                                    }
                                    
                                    if let avgPrice = trip.averageFuelPrice {
                                        HStack(spacing: 4) {
                                            StatBox(label: "AVG PRICE", value: "$" + String(format: "%.2f/gal", avgPrice))
                                            
                                            // Show calculation basis if partial
                                            if fuelStopsWithoutCost > 0 {
                                                Text("(\(fuelStopsWithCost) of \(trip.fuelStops.count))")
                                                    .font(.system(size: 9, design: .monospaced))
                                                    .foregroundColor(.secondaryText.opacity(0.7))
                                                    .italic()
                                                    .offset(y: 12)
                                            }
                                        }
                                    }
                                    
                                    // Show informational notice if some stops lack cost data
                                    if fuelStopsWithoutCost > 0 {
                                        HStack(spacing: 6) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 10))
                                            Text("\(fuelStopsWithoutCost) stop\(fuelStopsWithoutCost == 1 ? "" : "s") deferred cost entry")
                                                .font(.system(size: 10, design: .monospaced))
                                        }
                                        .foregroundColor(.secondaryText.opacity(0.8))
                                        .padding(.top, 4)
                                    }
                                }
                            } else if trip.fuelStops.contains(where: { $0.totalAdded > 0 }) {
                                // Has fuel stops but no cost data
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                    Text("Cost tracking not used")
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                .foregroundColor(.secondaryText.opacity(0.7))
                                .italic()
                                .padding(.top, 8)
                            }
                            
                            StatBox(label: "AVG FUEL/LEG", value: String(format: "%.1f gal", avgFuelEconomy))
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        // Legs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("FLIGHT LEGS")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(2)
                            
                            ForEach(trip.legs) { leg in
                                LegCard(leg: leg)
                            }
                        }
                        
                        // Fuel Stops
                        if !trip.fuelStops.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FUEL STOPS")
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                    .tracking(2)
                                
                                ForEach(trip.fuelStops) { stop in
                                    FuelStopCard(stop: stop)
                                }
                            }
                        }
                        
                        // Fuel Reconciliation (if available)
                        if trip.canReconcile {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("FUEL RECONCILIATION")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                        .tracking(2)
                                    
                                    Spacer()
                                    
                                    // Info button
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondaryText.opacity(0.7))
                                }
                                
                                Text("Compares tracked fuel vs actual fuel inferred from receipts")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondaryText.opacity(0.7))
                                    .italic()
                                
                                ForEach(trip.fuelReconciliation(), id: \.legNumber) { recon in
                                    ReconciliationCard(reconciliation: recon)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        exportTrip()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.fuelActive)
                    }
                }
            }
        }
    }
    
    func exportTrip() {
        let report = generateDetailedReport()
        
        let activityVC = UIActivityViewController(
            activityItems: [report],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func generateDetailedReport() -> String {
        var report = "FUELBAL DETAILED TRIP REPORT\n"
        report += "===================================\n\n"
        report += "Start: \(trip.startDate.formatted(date: .long, time: .shortened))\n"
        if let end = trip.endDate {
            report += "End: \(end.formatted(date: .long, time: .shortened))\n"
        }
        report += "\nSUMMARY:\n"
        report += "Legs: \(trip.legs.count)\n"
        report += "Fuel Stops: \(trip.fuelStops.count)\n"
        report += "Total Fuel Consumed: \(String(format: "%.1f", trip.totalFuelConsumed)) gal\n"
        report += "Total Cost: $\(String(format: "%.2f", trip.totalFuelCost))\n"
        report += "Avg Fuel per Leg: \(String(format: "%.1f", avgFuelEconomy)) gal\n\n"
        
        report += "FLIGHT LEGS:\n"
        report += "-----------------------------------\n"
        for leg in trip.legs {
            report += "\nLEG #\(leg.legNumber) (\(leg.preset.rawValue))\n"
            report += "  Start: \(leg.startTime.formatted(date: .omitted, time: .shortened))\n"
            if let end = leg.endTime {
                report += "  End: \(end.formatted(date: .omitted, time: .shortened))\n"
            }
            report += "  Swaps: \(leg.swapLog.count)\n"
            report += "  Fuel Burned: \(String(format: "%.1f", leg.totalBurned)) gal\n"
            
            if !leg.swapLog.isEmpty {
                report += "  Swap Log:\n"
                for swap in leg.swapLog {
                    report += "    #\(swap.swapNumber): \(swap.tank) - \(String(format: "%.1f", swap.burned)) gal @ \(String(format: "%.1f", swap.totalizer))\n"
                }
            }
        }
        
        if !trip.fuelStops.isEmpty {
            report += "\n\nFUEL STOPS:\n"
            report += "-----------------------------------\n"
            for (index, stop) in trip.fuelStops.enumerated() {
                report += "\nStop #\(index + 1)\n"
                report += "  Time: \(stop.timestamp.formatted(date: .omitted, time: .shortened))\n"
                if let location = stop.location {
                    report += "  Location: \(location)\n"
                }
                report += "  Fuel Added: \(String(format: "%.1f", stop.totalAdded)) gal\n"
                if let price = stop.pricePerGallon {
                    report += "  Price/Gal: $\(String(format: "%.2f", price))\n"
                } else if stop.totalAdded > 0 {
                    report += "  Price/Gal: (deferred)\n"
                }
                if let total = stop.totalCost {
                    report += "  Total Cost: $\(String(format: "%.2f", total))\n"
                } else if stop.totalAdded > 0 {
                    report += "  Total Cost: (deferred)\n"
                }
            }
        }
        
        // Fuel reconciliation (if available)
        if trip.canReconcile {
            report += "\n\nFUEL RECONCILIATION:\n"
            report += "-----------------------------------\n"
            report += "(Compares tracked fuel vs actual inferred from receipts)\n\n"
            
            for recon in trip.fuelReconciliation() {
                report += "Leg #\(recon.legNumber):\n"
                report += "  Tracked ending: \(String(format: "%.1f", recon.trackedTotal)) gal\n"
                if let actual = recon.actualTotal {
                    report += "  Actual ending:  \(String(format: "%.1f", actual)) gal\n"
                }
                if let variance = recon.variance {
                    report += "  Variance:       \(variance >= 0 ? "+" : "")\(String(format: "%.1f", variance)) gal\n"
                    report += "  Assessment:     \(recon.varianceDescription)\n"
                }
                report += "\n"
            }
        }
        
        report += "\n\n===================================\n"
        report += "Generated by FuelBal\n"
        report += Date().formatted(date: .long, time: .shortened)
        
        return report
    }
}

// MARK: - Stat Box

struct StatBox: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - Leg Card

struct LegCard: View {
    let leg: FlightLeg
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LEG #\(leg.legNumber)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text(leg.preset.rawValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText)
            }
            
            HStack(spacing: 16) {
                Label("\(leg.swapLog.count) swaps", systemImage: "arrow.triangle.swap")
                Label(String(format: "%.1f gal", leg.totalBurned), systemImage: "drop.fill")
                if let duration = leg.duration {
                    Label(String(format: "%.0f min", duration / 60), systemImage: "clock")
                }
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondaryText)
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

// MARK: - Fuel Stop Card

struct FuelStopCard: View {
    let stop: FuelStop
    
    var isZeroFuelStop: Bool {
        stop.totalAdded == 0
    }
    
    var hasCostData: Bool {
        stop.pricePerGallon != nil || stop.totalCost != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if isZeroFuelStop {
                    Text("ENGINE RESTART")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondaryText)
                } else if let location = stop.location {
                    Text(location)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                } else {
                    Text("FUEL STOP")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                Text(stop.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText)
            }
            
            if isZeroFuelStop {
                Text("No fuel added")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.7))
                    .italic()
            } else {
                HStack(spacing: 16) {
                    Label(String(format: "%.1f gal", stop.totalAdded), systemImage: "drop.fill")
                    
                    if hasCostData {
                        if let price = stop.pricePerGallon {
                            Label(String(format: "$%.2f/gal", price), systemImage: "dollarsign.circle")
                        }
                        if let total = stop.totalCost {
                            Label(String(format: "$%.2f", total), systemImage: "creditcard")
                        }
                    } else {
                        Label("Cost not tracked", systemImage: "minus.circle")
                            .foregroundColor(.secondaryText.opacity(0.6))
                    }
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.secondaryText)
                
                // Notes if available
                if let notes = stop.notes {
                    Text(notes)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondaryText.opacity(0.7))
                        .italic()
                        .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(isZeroFuelStop ? Color.black.opacity(0.2) : Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isZeroFuelStop ? Color.secondaryText.opacity(0.3) : Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    TripDetailView(trip: Trip(startDate: Date()))
}

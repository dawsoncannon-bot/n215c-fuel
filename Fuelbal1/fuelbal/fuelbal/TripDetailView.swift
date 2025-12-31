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
                            
                            if trip.totalFuelCost > 0 {
                                StatBox(label: "TOTAL COST", value: "$" + String(format: "%.2f", trip.totalFuelCost))
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
                }
                if let total = stop.totalCost {
                    report += "  Total Cost: $\(String(format: "%.2f", total))\n"
                }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let location = stop.location {
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
            
            HStack(spacing: 16) {
                Label(String(format: "%.1f gal", stop.totalAdded), systemImage: "drop.fill")
                if let price = stop.pricePerGallon {
                    Label(String(format: "$%.2f/gal", price), systemImage: "dollarsign.circle")
                }
                if let total = stop.totalCost {
                    Label(String(format: "$%.2f", total), systemImage: "creditcard")
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

#Preview {
    TripDetailView(trip: Trip(startDate: Date()))
}

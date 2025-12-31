//
//  TripsListView.swift
//  fuelbal
//
//  Created on 12/31/25.
//

import SwiftUI

struct TripsListView: View {
    @Environment(\.dismiss) var dismiss
    @State private var archivedTrips: [Trip] = []
    @State private var selectedTrips: Set<UUID> = []
    @State private var showTripDetail: Trip? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if archivedTrips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondaryText.opacity(0.5))
                        
                        Text("NO TRIPS YET")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        Text("Complete and end a trip to see it here")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondaryText.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(archivedTrips.reversed()) { trip in
                                TripCard(
                                    trip: trip,
                                    isSelected: selectedTrips.contains(trip.id),
                                    onTap: {
                                        showTripDetail = trip
                                    },
                                    onSelect: {
                                        if selectedTrips.contains(trip.id) {
                                            selectedTrips.remove(trip.id)
                                        } else {
                                            selectedTrips.insert(trip.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("TRIP HISTORY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedTrips.isEmpty {
                        Button("Export (\(selectedTrips.count))") {
                            exportSelectedTrips()
                        }
                        .foregroundColor(.fuelActive)
                    }
                }
            }
            .onAppear {
                loadTrips()
            }
            .sheet(item: $showTripDetail) { trip in
                TripDetailView(trip: trip)
            }
        }
    }
    
    func loadTrips() {
        if let data = UserDefaults.standard.data(forKey: "archivedTrips"),
           let trips = try? JSONDecoder().decode([Trip].self, from: data) {
            archivedTrips = trips
        }
    }
    
    func exportSelectedTrips() {
        let trips = archivedTrips.filter { selectedTrips.contains($0.id) }
        let report = generateTripReport(trips: trips)
        
        // Share sheet
        let activityVC = UIActivityViewController(
            activityItems: [report],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    func generateTripReport(trips: [Trip]) -> String {
        var report = "FUELBAL TRIP REPORT\n"
        report += "Generated: \(Date().formatted(date: .long, time: .shortened))\n"
        report += "===========================================\n\n"
        
        for trip in trips {
            report += "TRIP: \(trip.startDate.formatted(date: .abbreviated, time: .shortened))\n"
            report += "Legs: \(trip.legs.count) | Fuel Stops: \(trip.fuelStops.count)\n"
            report += "Total Fuel: \(String(format: "%.1f", trip.totalFuelConsumed)) gal\n"
            if trip.totalFuelCost > 0 {
                report += "Total Cost: $\(String(format: "%.2f", trip.totalFuelCost))\n"
            }
            report += "\n"
            
            for leg in trip.legs {
                report += "  LEG #\(leg.legNumber): \(leg.swapLog.count) swaps, \(String(format: "%.1f", leg.totalBurned)) gal burned\n"
            }
            
            report += "\n"
        }
        
        report += "===========================================\n"
        report += "END OF REPORT\n"
        
        return report
    }
}

// MARK: - Trip Card

struct TripCard: View {
    let trip: Trip
    let isSelected: Bool
    let onTap: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Selection checkbox
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .fuelActive : .secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(trip.startDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primaryText)
                        
                        if let name = trip.name {
                            Text("• \(name)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(trip.legs.count) Legs", systemImage: "airplane")
                        Label("\(String(format: "%.1f", trip.totalFuelConsumed)) gal", systemImage: "drop.fill")
                        if trip.totalFuelCost > 0 {
                            Label("$\(String(format: "%.0f", trip.totalFuelCost))", systemImage: "dollarsign.circle")
                        }
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondaryText)
            }
            .padding(16)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.fuelActive : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TripsListView()
}

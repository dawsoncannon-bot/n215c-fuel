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
    @State private var openLegs: [FlightLeg] = []
    @State private var selectedTrips: Set<UUID> = []
    @State private var selectedLegs: Set<UUID> = []
    @State private var showTripDetail: Trip? = nil
    @State private var showCreateTrip = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                if archivedTrips.isEmpty && openLegs.isEmpty {
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
                        VStack(spacing: 24) {
                            // Open Legs Section
                            if !openLegs.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("OPEN LEGS")
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundColor(.secondaryText)
                                            .tracking(2)
                                        
                                        Spacer()
                                        
                                        if !selectedLegs.isEmpty {
                                            Button("Create Trip (\(selectedLegs.count))") {
                                                showCreateTrip = true
                                            }
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.fuelActive)
                                            .cornerRadius(6)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    
                                    ForEach(openLegs.reversed()) { leg in
                                        OpenLegCard(
                                            leg: leg,
                                            isSelected: selectedLegs.contains(leg.id),
                                            onSelect: {
                                                if selectedLegs.contains(leg.id) {
                                                    selectedLegs.remove(leg.id)
                                                } else {
                                                    selectedLegs.insert(leg.id)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            
                            // Archived Trips Section
                            if !archivedTrips.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("COMPLETED TRIPS")
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                        .tracking(2)
                                        .padding(.horizontal, 16)
                                    
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
                loadOpenLegs()
            }
            .sheet(item: $showTripDetail) { trip in
                TripDetailView(trip: trip)
            }
            .sheet(isPresented: $showCreateTrip) {
                CreateTripView(
                    selectedLegs: Array(selectedLegs),
                    allLegs: openLegs,
                    onCreate: { trip in
                        // Save new trip
                        archiveNewTrip(trip)
                        // Remove used legs from open legs
                        removeLegsFromOpen(trip.legs.map { $0.id })
                        // Clear open fuel stops (they're now part of the trip)
                        clearOpenFuelStopsForLegs(trip.legs.map { $0.id })
                        // Clear selection
                        selectedLegs.removeAll()
                        showCreateTrip = false
                        // Reload data
                        loadTrips()
                        loadOpenLegs()
                    }
                )
            }
        }
    }
    
    func loadTrips() {
        if let data = UserDefaults.standard.data(forKey: "archivedTrips"),
           let trips = try? JSONDecoder().decode([Trip].self, from: data) {
            archivedTrips = trips
        }
    }
    
    func loadOpenLegs() {
        if let data = UserDefaults.standard.data(forKey: "openLegs"),
           let legs = try? JSONDecoder().decode([FlightLeg].self, from: data) {
            openLegs = legs
        }
    }
    
    func archiveNewTrip(_ trip: Trip) {
        archivedTrips.append(trip)
        if let encoded = try? JSONEncoder().encode(archivedTrips) {
            UserDefaults.standard.set(encoded, forKey: "archivedTrips")
        }
    }
    
    func removeLegsFromOpen(_ legIds: [UUID]) {
        openLegs.removeAll { legIds.contains($0.id) }
        if let encoded = try? JSONEncoder().encode(openLegs) {
            UserDefaults.standard.set(encoded, forKey: "openLegs")
        }
    }
    
    func loadOpenFuelStops() -> [FuelStop] {
        if let data = UserDefaults.standard.data(forKey: "openFuelStops"),
           let stops = try? JSONDecoder().decode([FuelStop].self, from: data) {
            return stops
        }
        return []
    }
    
    func clearOpenFuelStopsForLegs(_ legIds: [UUID]) {
        // For now, clear all open fuel stops when creating a trip
        // In a more sophisticated version, you'd track which stops belong to which legs
        if let _ = UserDefaults.standard.data(forKey: "openFuelStops") {
            UserDefaults.standard.removeObject(forKey: "openFuelStops")
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

// MARK: - Open Leg Card

struct OpenLegCard: View {
    let leg: FlightLeg
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
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
                    Text("LEG #\(leg.legNumber)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                    
                    Text("• \(leg.preset.rawValue)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text("OPEN")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.fuelActive)
                        .tracking(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.fuelActive.opacity(0.2))
                        .cornerRadius(3)
                }
                
                Text(leg.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.7))
                
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
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.fuelActive : Color.accentText.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Create Trip View

struct CreateTripView: View {
    let selectedLegs: [UUID]
    let allLegs: [FlightLeg]
    let onCreate: (Trip) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var tripName: String = ""
    
    var selectedLegObjects: [FlightLeg] {
        allLegs.filter { selectedLegs.contains($0.id) }.sorted { $0.startTime < $1.startTime }
    }
    
    var totalFuel: Double {
        selectedLegObjects.reduce(0) { $0 + $1.totalBurned }
    }
    
    var openFuelStops: [FuelStop] {
        // Load all open fuel stops
        if let data = UserDefaults.standard.data(forKey: "openFuelStops"),
           let stops = try? JSONDecoder().decode([FuelStop].self, from: data) {
            return stops
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Trip Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRIP NAME (OPTIONAL)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(1)
                            
                            TextField("Phoenix → Salt Lake → Denver", text: $tripName)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.primaryText)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.accentText.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Summary
                        VStack(spacing: 12) {
                            Text("TRIP SUMMARY")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(2)
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text("\(selectedLegObjects.count)")
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.accentText)
                                    Text("LEGS")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(String(format: "%.1f", totalFuel))
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.fuelActive)
                                    Text("GALLONS")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                }
                                
                                if !openFuelStops.isEmpty {
                                    VStack(spacing: 4) {
                                        Text("\(openFuelStops.count)")
                                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                                            .foregroundColor(.accentText)
                                        Text("FUEL STOPS")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.secondaryText)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        
                        // Selected Legs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LEGS IN TRIP")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(2)
                            
                            ForEach(selectedLegObjects) { leg in
                                HStack {
                                    Text("LEG #\(leg.legNumber)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.primaryText)
                                    
                                    Text("• \(leg.preset.rawValue)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f gal", leg.totalBurned))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.accentText)
                                }
                                .padding(12)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Create Button
                        Button(action: {
                            let trip = Trip(
                                name: tripName.isEmpty ? nil : tripName,
                                legs: selectedLegObjects,
                                fuelStops: openFuelStops,  // Include all open fuel stops
                                startDate: selectedLegObjects.first?.startTime ?? Date(),
                                endDate: selectedLegObjects.last?.endTime ?? Date()
                            )
                            onCreate(trip)
                            dismiss()
                        }) {
                            Text("CREATE TRIP")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.fuelActive)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
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

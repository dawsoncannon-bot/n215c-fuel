import SwiftUI
import SwiftUI
import Combine

struct AircraftSelectionView: View {
    @ObservedObject var fuel: FuelState
    @ObservedObject var aircraftManager = AircraftManager.shared
    @State private var selectedAircraft: Aircraft? = nil
    @State private var showTrips = false
    @State private var showAddAircraft = false
    
    var hasSavedState: Bool {
        return !fuel.swapLog.isEmpty || fuel.tankBurned.values.contains(where: { $0 > 0 })
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("FUEL TRACKER")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(4)
                
                HStack {
                    Spacer()
                    Text("SELECT AIRCRAFT")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                    Spacer()
                    
                    // Trips button
                    Button(action: {
                        showTrips = true
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14))
                            Text("TRIPS")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .tracking(1)
                        }
                        .foregroundColor(.accentText)
                        .frame(width: 50, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentText, lineWidth: 1)
                        )
                    }
                    .padding(.trailing, 20)
                }
                
                // N215C Preset
                Button(action: {
                    selectedAircraft = Aircraft.n215c
                }) {
                    AircraftCard(
                        aircraft: Aircraft.n215c,
                        hasSavedState: hasSavedState,
                        burnCycleNumber: fuel.burnCycleNumber,
                        fuel: fuel
                    )
                }
                .padding(.horizontal, 20)
                
                // Custom Aircraft Cards
                ForEach(aircraftManager.customAircraft) { aircraft in
                    CustomAircraftCardWithSwipe(
                        aircraft: aircraft,
                        onSelect: {
                            selectedAircraft = aircraft
                        },
                        onDelete: {
                            withAnimation {
                                aircraftManager.deleteAircraft(aircraft)
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                }
                
                // Add New Aircraft Card
                Button(action: {
                    showAddAircraft = true
                }) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.accentText)
                        
                        Text("ADD NEW AIRCRAFT")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primaryText)
                            .tracking(2)
                        
                        Text("Create a custom aircraft profile")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                Color.accentText.opacity(0.5),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .fullScreenCover(item: $selectedAircraft) { aircraft in
            FuelOptionsView(aircraft: aircraft, fuel: fuel)
        }
        .sheet(isPresented: $showTrips) {
            TripsListView()
        }
        .sheet(isPresented: $showAddAircraft) {
            AddAircraftView()
        }
    }
}

// MARK: - Aircraft Card

struct AircraftCard: View {
    let aircraft: Aircraft
    let hasSavedState: Bool
    let burnCycleNumber: Int?
    let fuel: FuelState?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(aircraft.tailNumber)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                if hasSavedState, let cycleNum = burnCycleNumber {
                    Text("CYCLE #\(cycleNum)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.fuelActive)
                        .tracking(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.fuelActive.opacity(0.2))
                        .cornerRadius(4)
                } else if aircraft.isPreset {
                    Text("PRESET")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentText)
                        .tracking(1)
                } else {
                    Text("CUSTOM")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondaryText)
                        .tracking(1)
                }
            }
            
            Text("\(aircraft.manufacturer) \(aircraft.model)")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.secondaryText)
            
            HStack(spacing: 16) {
                Label(aircraft.icao, systemImage: "airplane")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                Label(String(format: "%.0f GAL", aircraft.totalCapacity), systemImage: "drop.fill")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.accentText)
            }
            
            // Fuel gauges (only when saved state exists)
            if hasSavedState, let fuelState = fuel {
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 4)
                
                AircraftCardFuelDisplay(fuel: fuelState)
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Aircraft Card Fuel Display

struct AircraftCardFuelDisplay: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                // Display tanks dynamically based on current aircraft
                if let aircraft = fuel.currentAircraft {
                    ForEach(aircraft.tanks) { tank in
                        MiniGauge(
                            label: tank.position.rawValue,
                            remaining: fuel.remaining(tank.position.key),
                            maxFuel: tank.capacity
                        )
                    }
                } else {
                    // Fallback to N215C
                    MiniGauge(label: "L TIP", remaining: fuel.remaining("lTip"), maxFuel: 17)
                    MiniGauge(label: "L MAIN", remaining: fuel.remaining("lMain"), maxFuel: 25)
                    MiniGauge(label: "R MAIN", remaining: fuel.remaining("rMain"), maxFuel: 25)
                    MiniGauge(label: "R TIP", remaining: fuel.remaining("rTip"), maxFuel: 17)
                }
            }
            
            HStack {
                Text("TOTAL REMAINING")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text(String(format: "%.1f GAL", fuel.totalRemaining))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentText)
            }
        }
    }
}

struct MiniGauge: View {
    let label: String
    let remaining: Double
    let maxFuel: Double
    
    var fillPercent: Double {
        min(1, max(0, remaining / maxFuel))
    }
    
    var isLow: Bool {
        remaining <= 3.0 && remaining > 0
    }
    
    var fillColor: Color {
        if isLow { return .fuelLow }
        return .accentText
    }
    
    var gaugeHeight: CGFloat {
        maxFuel == 17 ? 35 : 50  // Proportional
    }
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 6, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(0.5)
            
            // Bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 30, height: gaugeHeight)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: 30, height: gaugeHeight * fillPercent)
            }
            
            Text(String(format: "%.1f", remaining))
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(isLow ? .fuelLow : .primaryText)
        }
    }
}

// MARK: - Custom Aircraft Card With Swipe

struct CustomAircraftCardWithSwipe: View {
    let aircraft: Aircraft
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Red delete background
            HStack {
                Spacer()
                Button(action: {
                    onDelete()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 24))
                        Text("Delete")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.white)
                    .frame(width: deleteButtonWidth)
                    .frame(maxHeight: .infinity)
                }
            }
            .background(Color.red)
            .cornerRadius(12)
            
            // Aircraft card
            Button(action: {
                if offset == 0 {
                    onSelect()
                } else {
                    // Close the swipe if it's open
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                    }
                }
            }) {
                AircraftCard(
                    aircraft: aircraft,
                    hasSavedState: false,
                    burnCycleNumber: nil,
                    fuel: nil
                )
            }
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isSwiping = true
                        // Only allow left swipe (negative values)
                        let newOffset = gesture.translation.width
                        if newOffset < 0 {
                            offset = max(newOffset, -deleteButtonWidth)
                        } else if offset < 0 {
                            // Allow swiping back to close
                            offset = min(0, offset + newOffset)
                        }
                    }
                    .onEnded { gesture in
                        isSwiping = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            // If swiped more than halfway, snap to open
                            if offset < -deleteButtonWidth / 2 {
                                offset = -deleteButtonWidth
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
        }
        .frame(height: 120)
    }
}

#Preview {
    AircraftSelectionView(fuel: FuelState())
}


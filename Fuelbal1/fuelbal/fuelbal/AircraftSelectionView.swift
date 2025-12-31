import SwiftUI
import Combine

struct AircraftSelectionView: View {
    @ObservedObject var fuel: FuelState
    @State private var selectedAircraft: Aircraft? = nil
    @State private var showOptions = false
    @State private var showTrips = false
    
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
                
                // N215C Card
                Button(action: {
                    selectedAircraft = Aircraft.n215c
                    showOptions = true
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("N215C")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            if hasSavedState {
                                Text("LEG #\(fuel.legNumber)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.fuelActive)
                                    .tracking(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.fuelActive.opacity(0.2))
                                    .cornerRadius(4)
                            } else {
                                Text("PRESET")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentText)
                                    .tracking(1)
                            }
                        }
                        
                        Text("Piper Cherokee 6")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: 16) {
                            Label("PA32", systemImage: "airplane")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryText)
                            
                            Label("84 GAL", systemImage: "drop.fill")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.accentText)
                        }
                        
                        // Fuel gauges (only when saved state exists)
                        if hasSavedState {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.vertical, 4)
                            
                            AircraftCardFuelDisplay(fuel: fuel)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .fullScreenCover(isPresented: $showOptions) {
            FuelOptionsView(aircraft: Aircraft.n215c, fuel: fuel)
        }
        .sheet(isPresented: $showTrips) {
            TripsListView()
        }
    }
}

// MARK: - Aircraft Card Fuel Display

struct AircraftCardFuelDisplay: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 10) {
                MiniGauge(label: "L TIP", remaining: fuel.remaining("lTip"), maxFuel: 17)
                MiniGauge(label: "L MAIN", remaining: fuel.remaining("lMain"), maxFuel: 25)
                MiniGauge(label: "R MAIN", remaining: fuel.remaining("rMain"), maxFuel: 25)
                MiniGauge(label: "R TIP", remaining: fuel.remaining("rTip"), maxFuel: 17)
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

#Preview {
    AircraftSelectionView(fuel: FuelState())
}


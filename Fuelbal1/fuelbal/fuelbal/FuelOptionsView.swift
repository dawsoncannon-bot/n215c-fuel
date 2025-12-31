import SwiftUI

struct FuelOptionsView: View {
    let aircraft: Aircraft
    @Environment(\.dismiss) var dismiss
    @State private var showCustomSplash = false
    @State private var customTanks: [TankPosition: Double] = [:]
    
    var hasSavedState: Bool {
        false  // TODO: Check actual saved state later
    }
    
    var customTotal: Double {
        customTanks.values.reduce(0, +)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 8) {
                        Text(aircraft.tailNumber)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.primaryText)
                        
                        Text("\(aircraft.manufacturer) \(aircraft.model)")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: 16) {
                            Label(aircraft.icao, systemImage: "airplane")
                            Label("\(Int(aircraft.totalCapacity)) GAL", systemImage: "drop.fill")
                        }
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.accentText)
                    }
                    .padding(.top, 60)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 40)
                    
                    Text("NEW FLIGHT")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                        .tracking(3)
                    
                    // Preset buttons
                    VStack(spacing: 16) {
                        FuelPresetButton(
                            title: "TOP OFF",
                            subtitle: "84 GAL",
                            detail: "17 / 25 / 25 / 17"
                        ) {
                            print("TOP OFF tapped")
                            dismiss()
                        }

                        FuelPresetButton(
                            title: "TABS",
                            subtitle: "70 GAL",
                            detail: "17 / 18 / 18 / 17"
                        ) {
                            print("TABS tapped")
                            dismiss()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Custom splash button
                    Button(action: {
                        showCustomSplash.toggle()
                        if showCustomSplash {
                            initializeCustomTanks()
                        }
                    }) {
                        Text("QUANTITY OVERRIDE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(2)
                            .foregroundColor(.secondaryText)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Custom splash panel
                    if showCustomSplash {
                        CustomSplashPanel(
                            aircraft: aircraft,
                            customTanks: $customTanks,
                            totalFuel: customTotal,
                            onStart: startCustomFlight
                        )
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .animation(.easeInOut, value: showCustomSplash)
    }
    
    // MARK: - Actions
    
    func initializeCustomTanks() {
        customTanks = [:]
        for tank in aircraft.tanks {
            customTanks[tank.position] = tank.capacity
        }
    }
    
    func startCustomFlight() {
        print("Starting custom flight with: \(customTanks)")
        dismiss()
    }
}

// MARK: - Fuel Preset Button

struct FuelPresetButton: View {    let title: String
    let subtitle: String
    let detail: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.accentText)
                    
                    Text(detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondaryText)
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Custom Splash Panel

struct CustomSplashPanel: View {
    let aircraft: Aircraft
    @Binding var customTanks: [TankPosition: Double]
    let totalFuel: Double
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MANUAL FUEL QUANTITY")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            // Tank inputs
            HStack(spacing: 12) {
                ForEach(aircraft.tanks) { tank in
                    FuelTankInput(
                        label: tank.position.rawValue,
                        value: Binding(
                            get: { customTanks[tank.position] ?? 0 },
                            set: { customTanks[tank.position] = min(tank.capacity, max(0, $0)) }
                        ),
                        max: tank.capacity
                    )
                }
            }
            
            // Total display
            HStack {
                Text("TOTAL")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                Spacer()
                
                Text(String(format: "%.1f GAL", totalFuel))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.fuelActive)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            
            // Start button
            Button(action: onStart) {
                Text("START FLIGHT")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentText)
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}


// MARK: - Fuel Tank Input

struct FuelTankInput: View {    let label: String
    @Binding var value: Double
    let max: Double
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(1)
            
            TextField("", value: $value, format: .number)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .frame(width: 55, height: 40)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentText, lineWidth: 1)
                )
        }
    }
}

#Preview {
    FuelOptionsView(aircraft: .n215c)
}

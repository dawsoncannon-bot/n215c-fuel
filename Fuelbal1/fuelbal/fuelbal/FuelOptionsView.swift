import SwiftUI

struct FuelOptionsView: View {
    let aircraft: Aircraft
    @ObservedObject var fuel: FuelState
    @Environment(\.dismiss) var dismiss
    @State private var showCustomSplash = false
    
    @State private var customTanks: [TankPosition: Double] = [:]
    @State private var showAddFuel = false  // NEW
    @State private var showResetWarning = false  // NEW
    
    var hasSavedState: Bool {
        // Check if there's any flight data saved
        return !fuel.swapLog.isEmpty || fuel.tankBurned.values.contains(where: { $0 > 0 })
    }
    
    var savedTotalRemaining: Double {
        return fuel.totalRemaining
    }

    var savedSwapInfo: String {
        return "Leg #\(fuel.legNumber) • Swap #\(fuel.swapLog.count + 1)"
    }

    var savedFuelLevels: [TankPosition: Double] {
        var levels: [TankPosition: Double] = [:]
        for tank in aircraft.tanks {
            levels[tank.position] = fuel.remaining(tank.position.key)
        }
        return levels
    }
    
    var customTotal: Double {
        customTanks.values.reduce(0, +)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header with back button
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .bold))
                                Text("BACK")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(.accentText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentText, lineWidth: 1)
                            )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
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
                        
                        // Fuel gauges (only when saved state exists)
                        if hasSavedState {
                            CompactTankDisplay(fuel: fuel)
                                .padding(.top, 16)
                        }
                    }
                    .padding(.top, 60)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.horizontal, 40)
                    
                    Text(hasSavedState ? "CONTINUE TRIP" : "NEW LEG")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                        .tracking(3)

                    // Buttons based on saved state
                    if hasSavedState {
                        // SAVED STATE EXISTS - Show Resume + Add Fuel
                        VStack(spacing: 16) {
                            // Resume button (red if low fuel)
                            FuelPresetButton(
                                title: "KEEP FLYING",
                                subtitle: "\(String(format: "%.1f", savedTotalRemaining)) GAL",
                                detail: savedSwapInfo,
                                isWarning: savedTotalRemaining < 15
                            ) {
                                resumeFlight()
                            }
                            
                            // Add Fuel button (primary)
                            FuelPresetButton(
                                title: "ADD FUEL",
                                subtitle: "Quick Refuel",
                                detail: "Add to saved levels"
                            ) {
                                showAddFuel = true
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Add fuel panel
                        if showAddFuel {
                            AddFuelOptionsPanel(
                                aircraft: aircraft,
                                savedLevels: savedFuelLevels,
                                onAdd: addFuelAndStart,
                                onCancel: { showAddFuel = false }
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Quantity override (tertiary)
                        Button(action: {
                            showResetWarning = true
                        }) {
                            Text("QUANTITY OVERRIDE")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(.secondaryText.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        
                        // End Trip button
                        Button(action: {
                            fuel.endTrip()
                        }) {
                            Text("END TRIP")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .tracking(2)
                                .foregroundColor(.secondaryText.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .padding(.top, 8)
                        
                    } else {
                        // NO SAVED STATE - Show Top Off + Tabs + Override
                        VStack(spacing: 16) {
                            FuelPresetButton(
                                title: "TOP OFF",
                                subtitle: "84 GAL",
                                detail: "17 / 25 / 25 / 17"
                            ) {
                                fuel.startFlight(.topoff)
                                dismiss()
                            }
                            
                            FuelPresetButton(
                                title: "TABS",
                                subtitle: "70 GAL",
                                detail: "17 / 18 / 18 / 17"
                            ) {
                                fuel.startFlight(.tabs)
                                dismiss()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Quantity override button
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
                    }
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .animation(.easeInOut, value: showCustomSplash)
        .alert("Reset Flight Data?", isPresented: $showResetWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Override", role: .destructive) {
                showCustomSplash = true
                initializeCustomTanks()
            }
        } message: {
            Text("This will clear your current flight data and start fresh with custom fuel quantities.")
        }
    }
    
    // MARK: - Actions
    
    func initializeCustomTanks() {
        customTanks = [:]
        for tank in aircraft.tanks {
            customTanks[tank.position] = tank.capacity
        }
    }
    
    func startCustomFlight() {
        // Convert TankPosition dictionary to String dictionary for FuelState
        let stringTanks: [String: Double] = Dictionary(uniqueKeysWithValues: 
            customTanks.map { ($0.key.key, $0.value) }
        )
        fuel.startFlight(.custom, customTanks: stringTanks)
        dismiss()
    }
    
    func resumeFlight() {
        fuel.isFlying = true
        dismiss()
    }

    func addFuelAndStart(amounts: [TankPosition: Double], pricePerGallon: Double?, totalCost: Double?, location: String?) {
        // Calculate new tank levels
        var newTanks: [String: Double] = [:]
        for tank in aircraft.tanks {
            let current = fuel.remaining(tank.position.key)
            let added = amounts[tank.position] ?? 0
            newTanks[tank.position.key] = min(tank.capacity, current + added)
        }
        
        // Use addFuel() with pricing info to preserve swap log and create fuel stop record
        fuel.addFuel(newTanks: newTanks, pricePerGallon: pricePerGallon, totalCost: totalCost, location: location)
        dismiss()
    }
}

// MARK: - Fuel Preset Button

struct FuelPresetButton: View {    
    let title: String
    let subtitle: String
    let detail: String
    var isWarning: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(isWarning ? .white : .primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(isWarning ? .white : .accentText)
                    
                    Text(isWarning ? "⚠ LOW FUEL - ADD FUEL RECOMMENDED" : detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(isWarning ? .white.opacity(0.8) : .secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(isWarning ? .white : .secondaryText)
            }
            .padding(20)
            .background(isWarning ? Color.red.opacity(0.8) : Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isWarning ? Color.red : Color.white.opacity(0.15), lineWidth: 2)
            )
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
                Text("START LEG")
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

// MARK: - Add Fuel Options Panel

struct AddFuelOptionsPanel: View {    
    let aircraft: Aircraft
    let savedLevels: [TankPosition: Double]
    let onAdd: ([TankPosition: Double], Double?, Double?, String?) -> Void  // amounts, price/gal, total cost, location
    let onCancel: () -> Void
    
    @State private var addAmounts: [TankPosition: Double] = [:]
    @State private var pricePerGallon: String = ""
    @State private var totalCost: String = ""
    @State private var location: String = ""
    
    var newLevels: [TankPosition: Double] {
        var result: [TankPosition: Double] = [:]
        for tank in aircraft.tanks {
            let saved = savedLevels[tank.position] ?? 0
            let added = addAmounts[tank.position] ?? 0
            result[tank.position] = min(tank.capacity, saved + added)
        }
        return result
    }
    
    var totalAdded: Double {
        addAmounts.values.reduce(0, +)
    }
    
    var newTotal: Double {
        newLevels.values.reduce(0, +)
    }
    
    var pricePerGallonValue: Double? {
        Double(pricePerGallon)
    }
    
    var totalCostValue: Double? {
        Double(totalCost)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FUEL STOP")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            // Quick-fill buttons
            HStack(spacing: 12) {
                Button(action: {
                    // Top off all tanks
                    for tank in aircraft.tanks {
                        let current = savedLevels[tank.position] ?? 0
                        addAmounts[tank.position] = tank.capacity - current
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("TOP OFF")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("84 GAL")
                            .font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentText)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    // Tab fill
                    let tabLevels: [TankPosition: Double] = [
                        .lTip: 17, .lMain: 18, .rMain: 18, .rTip: 17
                    ]
                    for tank in aircraft.tanks {
                        let current = savedLevels[tank.position] ?? 0
                        let target = tabLevels[tank.position] ?? tank.capacity
                        addAmounts[tank.position] = max(0, target - current)
                    }
                }) {
                    VStack(spacing: 4) {
                        Text("TABS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                        Text("70 GAL")
                            .font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentText.opacity(0.8))
                    .cornerRadius(8)
                }
            }
            
            // Tank add inputs with individual top-off buttons
            HStack(spacing: 12) {
                ForEach(aircraft.tanks) { tank in
                    VStack(spacing: 6) {
                        // Individual top-off button
                        Button(action: {
                            let current = savedLevels[tank.position] ?? 0
                            addAmounts[tank.position] = tank.capacity - current
                        }) {
                            Text("TOP")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(Color.accentText.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        AddFuelTankInput(
                            label: tank.position.rawValue,
                            current: savedLevels[tank.position] ?? 0,
                            add: Binding(
                                get: { addAmounts[tank.position] ?? 0 },
                                set: {
                                    let maxAdd = tank.capacity - (savedLevels[tank.position] ?? 0)
                                    addAmounts[tank.position] = min(maxAdd, max(0, $0))
                                }
                            ),
                            new: newLevels[tank.position] ?? 0
                        )
                    }
                }
            }
            
            // Pricing fields (all in one row, narrower)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("$/GAL")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 2) {
                        Text("$")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        TextField("6.50", text: $pricePerGallon)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentText)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 2) {
                        Text("$")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        TextField("352", text: $totalCost)
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentText)
                            .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("LOCATION")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    TextField("KLAS", text: $location)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentText)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                }
            }
            
            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("ADDED")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "+%.1f GAL", totalAdded))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentText)
                }
                
                HStack {
                    Text("NEW TOTAL")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f GAL", newTotal))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.fuelActive)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.buttonDisabled)
                .cornerRadius(8)
                
                Button("START LEG") {
                    onAdd(addAmounts, pricePerGallonValue, totalCostValue, location.isEmpty ? nil : location)
                }
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(totalAdded > 0 ? Color.accentText : Color.buttonDisabled)
                .cornerRadius(8)
                .disabled(totalAdded == 0)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentText.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            // Initialize with zeros
            for tank in aircraft.tanks {
                addAmounts[tank.position] = 0
            }
        }
    }
}

// MARK: - Add Fuel Tank Input

struct AddFuelTankInput: View {
    let label: String
    let current: Double
    @Binding var add: Double
    let new: Double
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(1)
            
            // Current
            Text(String(format: "%.1f", current))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondaryText.opacity(0.6))
            
            // Add input
            HStack(spacing: 2) {
                Text("+")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.accentText)
                
                TextField("", value: $add, format: .number)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(width: 40, height: 32)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentText, lineWidth: 1)
                    )
            }
            
            // New total
            Text(String(format: "%.1f", new))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.fuelActive)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Compact Tank Display

struct CompactTankDisplay: View {
    @ObservedObject var fuel: FuelState
    
    func remaining(_ tank: String) -> Double {
        fuel.remaining(tank)
    }
    
    func maxFuel(_ tank: String) -> Double {
        tank.contains("Tip") ? 17.0 : 25.0
    }
    
    func fillPercent(_ tank: String) -> Double {
        min(1, max(0, remaining(tank) / maxFuel(tank)))
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            CompactGauge(label: "L TIP", remaining: remaining("lTip"), maxFuel: 17)
            CompactGauge(label: "L MAIN", remaining: remaining("lMain"), maxFuel: 25)
            CompactGauge(label: "R MAIN", remaining: remaining("rMain"), maxFuel: 25)
            CompactGauge(label: "R TIP", remaining: remaining("rTip"), maxFuel: 17)
        }
    }
}

struct CompactGauge: View {
    let label: String
    let remaining: Double
    let maxFuel: Double
    
    var fillPercent: Double {
        min(1, max(0, remaining / maxFuel))
    }
    
    var isLow: Bool {
        remaining <= 3.0 && remaining > 0
    }
    
    var isEmpty: Bool {
        remaining < 2.0
    }
    
    var fillColor: Color {
        if isLow || isEmpty { return .fuelLow }
        return .accentText
    }
    
    var gaugeHeight: CGFloat {
        maxFuel == 17 ? 50 : 75  // Proportional: 17/25 ≈ 0.68
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(0.5)
            
            // Bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 40, height: gaugeHeight)
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(fillColor)
                    .frame(width: 40, height: gaugeHeight * fillPercent)
            }
            
            Text(String(format: "%.1f", remaining))
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(isLow || isEmpty ? .fuelLow : .primaryText)
        }
    }
}

#Preview {
    FuelOptionsView(aircraft: .n215c, fuel: FuelState())
}

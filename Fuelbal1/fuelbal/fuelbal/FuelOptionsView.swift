import SwiftUI

struct FuelOptionsView: View {
    let aircraft: Aircraft
    @ObservedObject var fuel: FuelState
    @Environment(\.dismiss) var dismiss
    @State private var showCustomSplash = false
    
    @State private var customTanks: [TankPosition: Double] = [:]
    @State private var showAddFuel = false  // NEW
    @State private var showResetWarning = false  // NEW
    @State private var showTrips = false  // NEW - for trips button
    @State private var showDeleteConfirmation = false  // NEW - for delete aircraft
    @State private var showNewFlightCostEntry = false  // NEW - for cost entry on new flights
    @State private var selectedPreset: Preset? = nil  // Track which preset was selected
    @State private var selectedTabLevels: [TankPosition: Double]? = nil  // Track tab levels if TAB FILL selected
    @State private var showKeepFlyingCostEntry = false  // NEW - for cost entry when continuing without fuel
    
    // Cost entry fields for new flights
    @State private var newFlightPrice = ""
    @State private var newFlightGallons = ""
    @State private var newFlightTotal = ""
    @State private var newFlightNotes = ""
    
    // Cost entry fields for keep flying (no fuel)
    @State private var restStopCost = ""
    @State private var restStopNotes = ""
    
    @ObservedObject var aircraftManager = AircraftManager.shared
    
    var hasSavedState: Bool {
        // Check if there's any flight data saved
        return !fuel.swapLog.isEmpty || fuel.tankBurned.values.contains(where: { $0 > 0 })
    }
    
    var savedTotalRemaining: Double {
        return fuel.totalRemaining
    }

    var savedSwapInfo: String {
        return "Leg #\(fuel.burnCycleNumber) • Swap #\(fuel.swapLog.count + 1)"
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
                        
                        // Delete button (only for custom aircraft)
                        if !aircraft.isPreset {
                            Button(action: {
                                showDeleteConfirmation = true
                            }) {
                                VStack(spacing: 2) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 14))
                                    Text("DELETE")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .tracking(1)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.red, lineWidth: 1)
                                )
                            }
                        }
                        
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentText, lineWidth: 1)
                            )
                        }
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
                                // Show cost entry panel instead of immediately resuming
                                withAnimation {
                                    showKeepFlyingCostEntry = true
                                }
                            }
                            
                            // Keep Flying cost entry panel
                            if showKeepFlyingCostEntry {
                                RestStopCostEntryPanel(
                                    miscCost: $restStopCost,
                                    notes: $restStopNotes,
                                    onContinue: {
                                        continueWithoutFuel()
                                    },
                                    onSkip: {
                                        skipRestStopCost()
                                    }
                                )
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .transition(.move(edge: .top).combined(with: .opacity))
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
                            fuel.endLeg()
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
                        // NO SAVED STATE - Show Top Off + Tab Fill + Override
                        VStack(spacing: 16) {
                            FuelPresetButton(
                                title: "TOP OFF",
                                subtitle: String(format: "%.0f GAL", aircraft.totalCapacity),
                                detail: aircraft.tanks.map { String(format: "%.0f", $0.capacity) }.joined(separator: " / ")
                            ) {
                                withAnimation {
                                    selectedPreset = .topoff
                                    selectedTabLevels = nil
                                    showNewFlightCostEntry = true
                                }
                            }
                            
                            // Only show TAB FILL if aircraft has tab fill data
                            if let tabTotal = aircraft.totalTabFill, let tabLevels = aircraft.tabFillLevels {
                                FuelPresetButton(
                                    title: "TAB FILL",
                                    subtitle: String(format: "%.0f GAL", tabTotal),
                                    detail: aircraft.tanks.compactMap { tank in
                                        tabLevels[tank.position].map { String(format: "%.0f", $0) }
                                    }.joined(separator: " / ")
                                ) {
                                    withAnimation {
                                        selectedPreset = .tabs
                                        selectedTabLevels = tabLevels
                                        showNewFlightCostEntry = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Cost entry panel for new flights
                        if showNewFlightCostEntry, let preset = selectedPreset {
                            NewFlightCostEntryPanel(
                                fuelAmount: preset == .topoff ? aircraft.totalCapacity : (aircraft.totalTabFill ?? 0),
                                presetName: preset == .topoff ? "TOP OFF" : "TAB FILL",
                                pricePerGallon: $newFlightPrice,
                                gallonsAdded: $newFlightGallons,
                                totalCost: $newFlightTotal,
                                notes: $newFlightNotes,
                                onStart: {
                                    startNewFlightWithCost(preset: preset)
                                },
                                onSkip: {
                                    startNewFlightWithoutCost(preset: preset)
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onTapGesture {
                                // Tapping the background dismisses the panel
                                withAnimation {
                                    showNewFlightCostEntry = false
                                    selectedPreset = nil
                                    selectedTabLevels = nil
                                    newFlightPrice = ""
                                    newFlightGallons = ""
                                    newFlightTotal = ""
                                    newFlightNotes = ""
                                }
                            }
                            .background(
                                Color.black.opacity(0.001)  // Invisible tap target
                                    .onTapGesture {
                                        withAnimation {
                                            showNewFlightCostEntry = false
                                            selectedPreset = nil
                                            selectedTabLevels = nil
                                            newFlightPrice = ""
                                            newFlightGallons = ""
                                            newFlightTotal = ""
                                            newFlightNotes = ""
                                        }
                                    }
                            )
                        }
                        
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
        .sheet(isPresented: $showTrips) {
            TripsListView()
        }
        .alert("Reset Flight Data?", isPresented: $showResetWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Override", role: .destructive) {
                showCustomSplash = true
                initializeCustomTanks()
            }
        } message: {
            Text("This will clear your current flight data and start fresh with custom fuel quantities.")
        }
        .alert("Delete Aircraft?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                aircraftManager.deleteAircraft(aircraft)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(aircraft.tailNumber)? This action cannot be undone.")
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
        fuel.startFlight(.custom, aircraft: aircraft, customTanks: stringTanks)
        dismiss()
    }
    
    func resumeFlight() {
        // Legacy function - now replaced by continueWithoutFuel
        fuel.resumeWithoutFuel()
        dismiss()
    }
    
    func continueWithoutFuel() {
        let cost = Double(restStopCost)
        let notes = restStopNotes.isEmpty ? nil : restStopNotes
        
        // Hide the panel first
        showKeepFlyingCostEntry = false
        
        // Resume with cost data (even if no fuel added)
        fuel.resumeWithoutFuel(miscCost: cost, notes: notes)
        dismiss()
    }
    
    func skipRestStopCost() {
        // Hide the panel first
        showKeepFlyingCostEntry = false
        
        // Continue without tracking any costs
        fuel.resumeWithoutFuel()
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
    
    func startNewFlightWithCost(preset: Preset) {
        let price = Double(newFlightPrice)
        let total = Double(newFlightTotal)
        let notes = newFlightNotes.isEmpty ? nil : newFlightNotes
        
        // Start flight with cost data
        fuel.startFlightWithInitialFuel(
            preset,
            aircraft: aircraft,
            tabFillLevels: selectedTabLevels,
            pricePerGallon: price,
            totalCost: total,
            location: notes  // Using location field for notes
        )
        dismiss()
    }
    
    func startNewFlightWithoutCost(preset: Preset) {
        // Start flight without cost tracking
        fuel.startFlight(preset, aircraft: aircraft, tabFillLevels: selectedTabLevels)
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
            
            // Quick-fill buttons - ENLARGED
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
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Text(String(format: "%.0f GAL", aircraft.totalCapacity))
                            .font(.system(size: 10, design: .monospaced))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentText)
                    .cornerRadius(10)
                }
                
                // Only show TAB FILL if aircraft has tab fill data
                if let tabTotal = aircraft.totalTabFill, let tabLevels = aircraft.tabFillLevels {
                    Button(action: {
                        // Tab fill
                        for tank in aircraft.tanks {
                            let current = savedLevels[tank.position] ?? 0
                            let target = tabLevels[tank.position] ?? tank.capacity
                            addAmounts[tank.position] = max(0, target - current)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("TAB FILL")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                            Text(String(format: "%.0f GAL", tabTotal))
                                .font(.system(size: 10, design: .monospaced))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentText.opacity(0.8))
                        .cornerRadius(10)
                    }
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
            
            // Pricing fields (all in one row, enlarged with DecimalTextField)
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("$/GAL")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 3) {
                        Text("$")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        DecimalTextField(
                            text: $pricePerGallon,
                            placeholder: "6.50",
                            decimalPlaces: 2,
                            font: .system(size: 14, weight: .bold, design: .monospaced),
                            foregroundColor: .accentText
                        )
                        .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 3) {
                        Text("$")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        DecimalTextField(
                            text: $totalCost,
                            placeholder: "352",
                            decimalPlaces: 2,
                            font: .system(size: 14, weight: .bold, design: .monospaced),
                            foregroundColor: .accentText
                        )
                        .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("NOTES")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    TextField("KLAS, etc.", text: $location)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentText)
                        .textInputAutocapitalization(.characters)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(6)
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
            
            // Buttons - ENLARGED
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Color.buttonDisabled)
                .cornerRadius(10)
                
                Button("START LEG") {
                    onAdd(addAmounts, pricePerGallonValue, totalCostValue, location.isEmpty ? nil : location)
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(totalAdded > 0 ? Color.accentText : Color.buttonDisabled)
                .cornerRadius(10)
                .disabled(totalAdded == 0)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentText.opacity(0.3), lineWidth: 1.5)
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

// MARK: - New Flight Cost Entry Panel

struct NewFlightCostEntryPanel: View {
    let fuelAmount: Double
    let presetName: String  // "TOP OFF" or "TAB FILL"
    @Binding var pricePerGallon: String
    @Binding var gallonsAdded: String
    @Binding var totalCost: String
    @Binding var notes: String
    let onStart: () -> Void
    let onSkip: () -> Void
    @Environment(\.dismiss) var dismiss  // For tap-to-dismiss
    
    // MARK: - Smart Calculation
    
    var calculationHint: String {
        let price = Double(pricePerGallon)
        let gallons = Double(gallonsAdded)
        let total = Double(totalCost)
        
        // Show calculated values based on what's entered
        if let p = price, let g = gallons, let t = total {
            // All three provided - validate consistency
            let expected = p * g
            let diff = t - expected
            if abs(diff) < 0.50 {
                return "✓ Consistent"
            } else {
                return String(format: "→ $%.2f/gal effective", t / g)
            }
        } else if let p = price, let g = gallons {
            // Calculate total
            return String(format: "→ $%.2f total", p * g)
        } else if let g = gallons, let t = total {
            // Calculate price per gallon
            return String(format: "→ $%.2f/gal", t / g)
        } else if let p = price, let t = total {
            // Calculate gallons
            return String(format: "→ %.1f gal", t / p)
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Single condensed header
            Text("FUEL COST (OPTIONAL) - \(presetName)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            // Three equal-width fields (33% each) - ENLARGED
            HStack(spacing: 10) {
                // Price per gallon
                VStack(alignment: .leading, spacing: 6) {
                    Text("$/GAL")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 3) {
                        Text("$")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        DecimalTextField(
                            text: $pricePerGallon,
                            placeholder: "6.50",
                            decimalPlaces: 2,
                            font: .system(size: 16, weight: .bold, design: .monospaced),
                            foregroundColor: .accentText
                        )
                        .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                
                // Gallons added
                VStack(alignment: .leading, spacing: 6) {
                    Text("GALLONS")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    DecimalTextField(
                        text: $gallonsAdded,
                        placeholder: "45.2",
                        decimalPlaces: 1,
                        font: .system(size: 16, weight: .bold, design: .monospaced),
                        foregroundColor: .accentText
                    )
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                
                // Total cost
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 3) {
                        Text("$")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        DecimalTextField(
                            text: $totalCost,
                            placeholder: "352",
                            decimalPlaces: 2,
                            font: .system(size: 16, weight: .bold, design: .monospaced),
                            foregroundColor: .accentText
                        )
                        .keyboardType(.decimalPad)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Smart calculation hint
            if !calculationHint.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.accentText.opacity(0.7))
                    
                    Text(calculationHint)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.accentText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
            }
            
            // Notes field (full width) - ENLARGED
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                TextField("Airport, FBO, who paid, etc.", text: $notes)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.accentText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
            
            // Buttons - ENLARGED
            HStack(spacing: 12) {
                Button("Skip") {
                    onSkip()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentText, lineWidth: 1.5)
                )
                
                Button("Start") {
                    onStart()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentText)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentText.opacity(0.3), lineWidth: 1.5)
        )
    }
}

// MARK: - Compact Tank Display

struct CompactTankDisplay: View {
    @ObservedObject var fuel: FuelState
    
    func remaining(_ tank: String) -> Double {
        fuel.remaining(tank)
    }
    
    func maxFuel(_ tank: String) -> Double {
        // Get from current aircraft if available
        if let aircraft = fuel.currentAircraft,
           let tankPosition = TankPosition.allCases.first(where: { $0.key == tank }),
           let fuelTank = aircraft.tanks.first(where: { $0.position == tankPosition }) {
            return fuelTank.capacity
        }
        // Fallback to N215C defaults
        return tank.contains("Tip") ? 17.0 : 25.0
    }
    
    func fillPercent(_ tank: String) -> Double {
        min(1, max(0, remaining(tank) / maxFuel(tank)))
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Display tanks dynamically based on aircraft
            if let aircraft = fuel.currentAircraft {
                ForEach(aircraft.tanks) { tank in
                    CompactGauge(
                        label: tank.position.rawValue,
                        remaining: remaining(tank.position.key),
                        maxFuel: tank.capacity
                    )
                }
            } else {
                // Fallback to N215C configuration
                CompactGauge(label: "L TIP", remaining: remaining("lTip"), maxFuel: 17)
                CompactGauge(label: "L MAIN", remaining: remaining("lMain"), maxFuel: 25)
                CompactGauge(label: "R MAIN", remaining: remaining("rMain"), maxFuel: 25)
                CompactGauge(label: "R TIP", remaining: remaining("rTip"), maxFuel: 17)
            }
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

// MARK: - Rest Stop Cost Entry Panel

struct RestStopCostEntryPanel: View {
    @Binding var miscCost: String
    @Binding var notes: String
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 18) {
            // Header
            VStack(spacing: 6) {
                Image(systemName: "fuelpump.slash")
                    .font(.system(size: 24))
                    .foregroundColor(.accentText.opacity(0.7))
                
                Text("REST STOP - NO FUEL")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(2)
                
                Text("Track costs even without refueling")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.7))
            }
            
            // Cost field
            VStack(alignment: .leading, spacing: 6) {
                Text("MISCELLANEOUS COSTS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                HStack(spacing: 3) {
                    Text("$")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    DecimalTextField(
                        text: $miscCost,
                        placeholder: "0.00",
                        decimalPlaces: 2,
                        font: .system(size: 16, weight: .bold, design: .monospaced),
                        foregroundColor: .accentText
                    )
                    .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                
                Text("Parking, landing fees, ramp fees, etc.")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .padding(.horizontal, 4)
            }
            
            // Notes field
            VStack(alignment: .leading, spacing: 6) {
                Text("NOTES")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                
                TextField("Location, reason for stop, etc.", text: $notes)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.accentText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button("Skip") {
                    onSkip()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentText, lineWidth: 1.5)
                )
                
                Button("START LEG") {
                    onContinue()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentText)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentText.opacity(0.3), lineWidth: 1.5)
        )
    }
}

#Preview {
    FuelOptionsView(aircraft: .n215c, fuel: FuelState())
}

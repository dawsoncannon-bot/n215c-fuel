//
//  FlightView.swift
//  fuelbal
//
//  Created by Dawson Cannon on 12/30/25.
//

import SwiftUI

struct FlightView: View {
    @ObservedObject var fuel: FuelState
    @State private var totalizerInput = ""
    @State private var inputError = ""
    @FocusState private var inputFocused: Bool
    @State private var showShutdownPrompt = false
    @State private var shutdownInput = ""
    @State private var timer: Timer?
    @State private var showGPHInput = false  // NEW: Show GPH input sheet
    @State private var gphInput = ""  // NEW: GPH input field
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HeaderView(
                    fuel: fuel,
                    onExit: {
                        fuel.isFlying = false
                    },
                    onEngineToggle: {
                        if fuel.engineRunning {
                            showShutdownPrompt = true
                        } else {
                            fuel.startEngine()
                        }
                    }
                )
                
                // NEW: HUD with countdown timer and average GPH
                if fuel.engineRunning {
                    FuelManagementHUD(
                        fuel: fuel,
                        onGPHInput: {
                            showGPHInput = true
                        }
                    )
                }
                
                // Leg Timer Display (smaller, out of the way)
                if fuel.engineRunning || fuel.currentLegTime > 0 {
                    CompactLegTimerView(fuel: fuel)
                }
                
                // Phase indicator
                PhaseIndicator(fuel: fuel)
                
                // Reserve display
                Text("SAFETY RESERVE: \(String(format: "%.1f", FuelState.safetyReserve)) GAL")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(1)
                
                // Tank display
                TankDisplay(fuel: fuel)
                
                // Last reading and swap targets side by side
                HStack(spacing: 16) {
                    LastReadingBox(fuel: fuel)
                    SwapTargets(fuel: fuel)
                }
                
                // Input section with undo button (disabled when engine off)
                InputSection(
                    fuel: fuel,
                    totalizerInput: $totalizerInput,
                    inputError: $inputError,
                    inputFocused: $inputFocused
                )
                .disabled(!fuel.engineRunning)
                .opacity(fuel.engineRunning ? 1.0 : 0.5)
                
                // History
                if !fuel.swapLog.isEmpty {
                    HistoryView(fuel: fuel)
                }
            }
            .padding()
        }
        .onTapGesture {
            if fuel.engineRunning {
                inputFocused = false
            }
        }
        .onAppear {
            // Start timer to update leg time display
            startTimer()
        }
        .onDisappear {
            // Stop timer when view disappears
            stopTimer()
        }
        .sheet(isPresented: $showShutdownPrompt) {
            ShutdownPromptView(
                fuel: fuel,
                shutdownInput: $shutdownInput,
                onCancel: {
                    showShutdownPrompt = false
                    shutdownInput = ""
                },
                onConfirm: { reading in
                    fuel.shutdown(reading: reading)
                    showShutdownPrompt = false
                    shutdownInput = ""
                }
            )
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showGPHInput) {
            GPHInputView(
                fuel: fuel,
                gphInput: $gphInput,
                onCancel: {
                    showGPHInput = false
                    gphInput = ""
                },
                onConfirm: { gph in
                    fuel.logObservedGPH(gph)
                    showGPHInput = false
                    gphInput = ""
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
    }
    
    // NEW: Timer management
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateLegTime()
            updateCountdown()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateLegTime() {
        guard fuel.engineRunning, let startTime = fuel.legTimerStart else { return }
        fuel.currentLegTime = Date().timeIntervalSince(startTime)
    }
    
    private func updateCountdown() {
        guard fuel.engineRunning else { return }
        fuel.updateCountdownTimer()
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var fuel: FuelState
    let onExit: () -> Void
    let onEngineToggle: () -> Void
    
    var body: some View {
        HStack {
            // Back button (only active when engine off)
            Button(action: onExit) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                    Text("BACK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(fuel.engineRunning ? .gray.opacity(0.3) : .accentText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(fuel.engineRunning ? Color.gray.opacity(0.3) : Color.accentText, lineWidth: 1)
                )
            }
            .disabled(fuel.engineRunning)
            
            Spacer()
            
            // Center info
            VStack(spacing: 4) {
                Text("LEG #\(fuel.legNumber) • \(fuel.preset.rawValue)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(2)
                
                Text(String(format: "%.1f GAL", fuel.totalRemaining))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentText)
            }
            
            Spacer()
            
            // Right side - Engine start/stop button
            Button(action: onEngineToggle) {
                VStack(spacing: 2) {
                    Image(systemName: fuel.engineRunning ? "power" : "key.fill")
                        .font(.system(size: 16, weight: .bold))
                    Text(fuel.engineRunning ? "STOP" : "START")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(fuel.engineRunning ? .white : .black)
                .frame(width: 60, height: 44)
                .background(fuel.engineRunning ? Color.red : Color.green)
                .cornerRadius(8)
            }
        }
        .padding(.bottom, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .bottom
        )
    }
}

// MARK: - Phase Indicator

struct PhaseIndicator: View {
    @ObservedObject var fuel: FuelState
    
    var text: String {
        if fuel.fuelExhausted { return "FUEL EXHAUSTED" }
        if fuel.phase == .tips { return "TIPS PHASE" }
        if let mode = fuel.flightMode {
            return "MAINS • \(mode.rawValue)"
        }
        return "MAINS PHASE"
    }
    
    var colors: (text: Color, border: Color, bg: Color) {
        if fuel.fuelExhausted {
            return (.fuelLow, .fuelLow.opacity(0.33), Color.cardBackground.opacity(0.5))
        }
        if fuel.phase == .tips {
            return (.fuelActive, .fuelActive.opacity(0.2), Color.cardBackground)
        }
        if fuel.flightMode == .endurance {
            return (.fuelActive, .fuelActive.opacity(0.2), Color.cardBackground)
        }
        if fuel.flightMode == .balanced {
            return (.accentText, .accentText.opacity(0.27), Color.cardBackground)
        }
        return (.gray, Color.white.opacity(0.1), Color.cardBackground)
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundColor(colors.text)
            .tracking(2)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(colors.bg)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(colors.border, lineWidth: 1)
            )
    }
}

// MARK: - Tank Display

struct TankDisplay: View {
    @ObservedObject var fuel: FuelState
    
    // Define proper tank order
    private func tankOrder(_ key: String) -> Int {
        switch key {
        case "lTip": return 0
        case "lMain": return 1
        case "center": return 2
        case "rMain": return 3
        case "rTip": return 4
        case "aft": return 5
        default: return 999
        }
    }
    
    var leftTanks: [String] {
        guard let aircraft = fuel.currentAircraft else {
            return ["lMain", "lTip"]
        }
        return aircraft.tanks
            .filter { $0.position.key.hasPrefix("l") }
            .sorted { tankOrder($0.position.key) < tankOrder($1.position.key) }
            .map { $0.position.key }
    }
    
    var rightTanks: [String] {
        guard let aircraft = fuel.currentAircraft else {
            return ["rMain", "rTip"]
        }
        return aircraft.tanks
            .filter { $0.position.key.hasPrefix("r") }
            .sorted { tankOrder($0.position.key) < tankOrder($1.position.key) }
            .map { $0.position.key }
    }
    
    var centerTanks: [String] {
        guard let aircraft = fuel.currentAircraft else {
            return []
        }
        return aircraft.tanks
            .filter { $0.position.key.hasPrefix("c") || $0.position.key.hasPrefix("a") }  // center or aft
            .sorted { tankOrder($0.position.key) < tankOrder($1.position.key) }
            .map { $0.position.key }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Left wing
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(leftTanks, id: \.self) { tank in
                    TankGauge(fuel: fuel, tank: tank)
                }
            }
            
            // Center indicator
            CenterIndicator(fuel: fuel)
            
            // Right wing
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(rightTanks, id: \.self) { tank in
                    TankGauge(fuel: fuel, tank: tank)
                }
            }
            
            // Center/Aft tanks (if any) - shown after right wing
            if !centerTanks.isEmpty {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(centerTanks, id: \.self) { tank in
                        TankGauge(fuel: fuel, tank: tank)
                    }
                }
            }
        }
    }
}

// MARK: - Tank Gauge

struct TankGauge: View {
    @ObservedObject var fuel: FuelState
    let tank: String
    
    var remaining: Double { fuel.remaining(tank) }
    
    var maxFuel: Double {
        // Get from current aircraft if available
        if let aircraft = fuel.currentAircraft,
           let tankPosition = TankPosition.allCases.first(where: { $0.key == tank }),
           let fuelTank = aircraft.tanks.first(where: { $0.position == tankPosition }) {
            return fuelTank.capacity
        }
        // Fallback to N215C defaults
        return tank.contains("Tip") ? 17.0 : 25.0
    }
    
    var fillPercent: Double { min(1, max(0, remaining / maxFuel)) }
    var isActive: Bool { fuel.currentTank == tank && !fuel.fuelExhausted }
    var isLow: Bool { remaining <= FuelState.lowWarn && remaining > 0 }
    var isEmpty: Bool { remaining < FuelState.exhaustedThreshold }
    var isLocked: Bool { tank.contains("Tip") && fuel.phase == .mains }
    
    var fillColor: Color {
        if isLow || isEmpty { return .fuelLow }
        if isActive { return .fuelActive }
        return .accentText
    }
    
    var opacity: Double {
        if isEmpty { return 0.3 }
        if isLocked { return 0.4 }
        return 1.0
    }
    
    var gaugeHeight: CGFloat {
        // Scale height proportionally to capacity
        // Base: 25 gal = 70 points
        let baseCapacity = 25.0
        let baseHeight = 70.0
        let scaledHeight = (maxFuel / baseCapacity) * baseHeight
        return CGFloat(min(max(scaledHeight, 40), 90))  // Clamp between 40-90 points
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(fuel.tankLabel(tank))
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(1)
            
            // Bar
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 28, height: gaugeHeight)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: 28, height: gaugeHeight * fillPercent)
            }
            
            Text(String(format: "%.1f", remaining))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(isLow || isEmpty ? .fuelLow : .primaryText)
        }
        .padding(10)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? .fuelActive : Color.white.opacity(0.15), lineWidth: 2)
        )
        .opacity(opacity)
        .frame(width: 65)
    }
}

// MARK: - Center Indicator

struct CenterIndicator: View {
    @ObservedObject var fuel: FuelState
    
    var currentColor: Color {
        if fuel.fuelExhausted { return .gray }
        if !fuel.engineRunning { return .gray }
        return fuel.isLeft(fuel.currentTank) ? .accentText : .fuelLow
    }
    
    var displayLabel: String {
        if !fuel.engineRunning { return "OFF" }
        if fuel.fuelExhausted { return "--" }
        return fuel.tankLabel(fuel.currentTank)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("BURNING")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            Text(displayLabel)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(currentColor)
                .padding(.top, 4)
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.white.opacity(0.1))
                .padding(.top, 10)
            
            Text("NEXT")
                .font(.system(size: 8, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(1)
                .padding(.top, 8)
            
            Text(fuel.nextTank != nil ? fuel.tankLabel(fuel.nextTank!) : "--")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.fuelActive)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(minWidth: 110)
    }
}

// MARK: - Last Reading Box

struct LastReadingBox: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        VStack(spacing: 6) {
            Text("LAST READING")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            Text(fuel.lastReading != nil ? String(format: "%.1f", fuel.lastReading!) : "--")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Swap Targets

struct SwapTargets: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        Group {
            if fuel.fuelExhausted {
                TargetBox(label: "COMPLETE", value: "--", style: .balanced)
            } else if fuel.swapLog.isEmpty {
                // First swap - climbout (but check if tank is small)
                let remaining = fuel.remaining(fuel.currentTank)
                let available = remaining - FuelState.safetyReserve
                
                if available < 7.0 {
                    // Tank doesn't have enough for full 7.0 gal climbout
                    if let last = fuel.lastReading {
                        TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", last + available), style: .warning)
                    } else {
                        // No reading yet, show max available
                        TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", available), style: .warning)
                    }
                } else if remaining < 10 {
                    // Between 7-10 gallons, show do not exceed
                    if let last = fuel.lastReading {
                        TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", last + available), style: .warning)
                    } else {
                        TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", available), style: .warning)
                    }
                } else {
                    // Tank has enough for normal 7.0 gal climbout
                    TargetBox(label: "SWAP AT", value: "7.0", style: .endurance)
                }
            } else if fuel.swapLog.count == 1 && fuel.phase == .mains && fuel.preset == .topoff && fuel.flightMode == nil {
                // Swap 2 for topoff - show both options (unless tank too small)
                if fuel.remaining(fuel.currentTank) < 10, let max = fuel.maxTarget {
                    TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", max), style: .warning)
                } else if let targets = fuel.calcTargets() {
                    VStack(spacing: 8) {
                        TargetBox(label: "BALANCED", value: String(format: "%.1f", targets.balanced), style: .balanced, compact: true)
                        TargetBox(label: "ENDURANCE", value: String(format: "%.1f", targets.endurance), style: .endurance, compact: true)
                    }
                    .onAppear {
                        fuel.swap2Targets = targets
                    }
                }
            } else if fuel.isLastTank, let max = fuel.maxTarget {
                // Zero fuel - last tank
                TargetBox(label: "🛑 ZERO FUEL", value: String(format: "%.1f", max), style: .zeroFuel)
            } else if fuel.isLastBurnForTank, let max = fuel.maxTarget {
                // Do not exceed - last burn for this tank
                TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", max), style: .warning)
            } else if fuel.remaining(fuel.currentTank) < 10, let max = fuel.maxTarget {
                // Tank has less than 10 gallons - DO NOT EXCEED mode
                TargetBox(label: "⚠ DO NOT EXCEED", value: String(format: "%.1f", max), style: .warning)
            } else if fuel.phase == .tips {
                // Tips phase
                if let last = fuel.lastReading {
                    let available = fuel.remaining(fuel.currentTank) - FuelState.safetyReserve
                    let burn = min(FuelState.tipBurn, available)
                    TargetBox(label: "SWAP AT", value: String(format: "%.1f", last + burn), style: .balanced)
                } else {
                    TargetBox(label: "SWAP AT", value: "--", style: .balanced)
                }
            } else if let targets = fuel.calcTargets() {
                // Mains with mode locked
                let mode = fuel.flightMode ?? .balanced
                let value = mode == .endurance ? targets.endurance : targets.balanced
                let label = fuel.preset == .tabs ? "SWAP AT" : mode.rawValue
                TargetBox(label: label, value: String(format: "%.1f", value), style: mode == .endurance ? .endurance : .balanced)
            } else {
                TargetBox(label: "SWAP AT", value: "--", style: .balanced)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Target Box

enum TargetStyle {
    case balanced, endurance, warning, zeroFuel
}

struct TargetBox: View {
    let label: String
    let value: String
    let style: TargetStyle
    var compact: Bool = false
    
    var labelColor: Color {
        switch style {
        case .balanced, .endurance: return .gray
        case .warning, .zeroFuel: return .fuelLow
        }
    }
    
    var valueColor: Color {
        switch style {
        case .balanced: return .accentText
        case .endurance: return .fuelActive
        case .warning, .zeroFuel: return .fuelLow
        }
    }
    
    var borderColor: Color {
        switch style {
        case .balanced: return .accentText
        case .endurance: return .fuelActive.opacity(0.33)
        case .warning, .zeroFuel: return .fuelLow
        }
    }
    
    var bgColor: Color {
        switch style {
        case .warning: return Color.cardBackground.opacity(0.5)
        case .zeroFuel: return Color.red.opacity(0.1)
        default: return Color.cardBackground
        }
    }
    
    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Text(label)
                .font(.system(size: compact ? 8 : (style == .zeroFuel ? 11 : 9), weight: (style == .warning || style == .zeroFuel) ? .bold : .regular, design: .monospaced))
                .foregroundColor(labelColor)
                .tracking(2)
            
            Text(value)
                .font(.system(size: compact ? 22 : (style == .zeroFuel ? 36 : 32), weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, compact ? 12 : 24)
        .padding(.vertical, compact ? 8 : 14)
        .background(bgColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: style == .zeroFuel ? 2 : 1)
        )
    }
}

// MARK: - Input Section

struct InputSection: View {
    @ObservedObject var fuel: FuelState
    @Binding var totalizerInput: String
    @Binding var inputError: String
    @FocusState.Binding var inputFocused: Bool
    
    var isValid: Bool {
        guard let reading = Double(totalizerInput) else { return false }
        let last = fuel.lastReading ?? 0
        return reading >= last
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Undo button
            Button(action: { fuel.undoLastSwap() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 11, weight: .bold))
                    Text("UNDO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(fuel.swapLog.isEmpty ? Color.gray.opacity(0.3) : .secondaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(fuel.swapLog.isEmpty ? Color.gray.opacity(0.3) : Color.secondaryText, lineWidth: 1)
                )
            }
            .disabled(fuel.swapLog.isEmpty)
            
            Text("TOTALIZER USED")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            // Input and button side by side
            HStack(spacing: 12) {
                TextField("0.0", text: $totalizerInput)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($inputFocused)
                    .frame(height: 60)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(inputError.isEmpty ? (inputFocused ? .accentText : Color.white.opacity(0.15)) : .fuelLow, lineWidth: 2)
                    )
                    .onChange(of: totalizerInput) {
                        validateInput()
                    }
                
                Button(action: logSwap) {
                    Text("LOG\nSWAP")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(canLog ? .black : .gray)
                        .frame(width: 80, height: 60)
                        .background(canLog ? Color.accentText : Color.buttonDisabled)
                        .cornerRadius(8)
                }
                .disabled(!canLog)
            }
            .padding(.horizontal, 12)
            
            Text(inputError)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.fuelLow)
                .frame(height: 14)
        }
    }
    
    var canLog: Bool {
        !fuel.fuelExhausted && !totalizerInput.isEmpty && inputError.isEmpty && isValid
    }
    
    func validateInput() {
        inputError = ""
        guard let reading = Double(totalizerInput) else { return }
        let last = fuel.lastReading ?? 0
        if reading < last {
            inputError = "Must be ≥ \(String(format: "%.1f", last))"
        }
    }
    
    func logSwap() {
        guard let reading = Double(totalizerInput), isValid else { return }
        fuel.logSwap(reading: reading)
        totalizerInput = ""
        inputError = ""
        inputFocused = false
    }
}

// MARK: - History View

struct HistoryView: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        VStack(spacing: 8) {
            Text("RECENT SWAPS")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Header row
            HStack(spacing: 8) {
                Text("#")
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .frame(width: 20, alignment: .leading)
                
                Text("TANK")
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .frame(width: 65, alignment: .leading)
                
                Text("TIME")
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .frame(width: 70, alignment: .trailing)
                
                Text("TOTAL")
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .frame(width: 45, alignment: .trailing)
                
                Text("BURN")
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .frame(width: 40, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .regular, design: .monospaced))
            .padding(.horizontal, 4)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            ForEach(fuel.swapLog.suffix(4).reversed()) { entry in
                HStack(spacing: 8) {
                    Text("#\(entry.swapNumber)")
                        .foregroundColor(.secondaryText)
                        .frame(width: 20, alignment: .leading)
                    
                    Text(entry.tank)
                        .foregroundColor(.secondaryText)
                        .frame(width: 65, alignment: .leading)
                    
                    Text(entry.formattedLegTime)
                        .foregroundColor(.fuelActive)
                        .frame(width: 70, alignment: .trailing)
                    
                    Text(String(format: "%.1f", entry.totalizer))
                        .foregroundColor(.secondaryText)
                        .frame(width: 45, alignment: .trailing)
                    
                    Text(String(format: "+%.1f", entry.burned))
                        .foregroundColor(.accentText)
                        .frame(width: 40, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .padding(.horizontal, 4)
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Fuel Management HUD

struct FuelManagementHUD: View {
    @ObservedObject var fuel: FuelState
    let onGPHInput: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Countdown Timer (top, most prominent)
            if fuel.predictedTimeToSwap > 0 {
                CountdownTimerDisplay(fuel: fuel)
            }
            
            // Average GPH and Observed GPH side by side
            HStack(spacing: 12) {
                // Average GPH (historical data)
                VStack(spacing: 4) {
                    Text("AVG GPH")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondaryText)
                        .tracking(2)
                    
                    Text(fuel.formattedAverageGPH)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentText)
                    
                    Text("ACTUAL BURN")
                        .font(.system(size: 7, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondaryText.opacity(0.6))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                
                // Observed GPH (predictive data)
                Button(action: onGPHInput) {
                    VStack(spacing: 4) {
                        Text("OBSERVED")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondaryText)
                            .tracking(2)
                        
                        if let observedGPH = fuel.currentObservedGPH {
                            Text(String(format: "%.1f", observedGPH))
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.fuelActive)
                        } else {
                            Text("TAP")
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        Text("INSTRUMENT")
                            .font(.system(size: 7, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondaryText.opacity(0.6))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(fuel.currentObservedGPH != nil ? Color.fuelActive.opacity(0.3) : Color.white.opacity(0.1), lineWidth: fuel.currentObservedGPH != nil ? 2 : 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Countdown Timer Display

struct CountdownTimerDisplay: View {
    @ObservedObject var fuel: FuelState
    
    var isUrgent: Bool {
        fuel.predictedTimeToSwap > 0 && fuel.predictedTimeToSwap < 300  // Less than 5 minutes
    }
    
    var displayColor: Color {
        if fuel.predictedTimeToSwap <= 0 {
            return .fuelLow
        } else if isUrgent {
            return .orange
        } else {
            return .fuelActive
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: isUrgent ? "exclamationmark.triangle.fill" : "timer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(displayColor)
                
                Text("TIME TO SWAP")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(2)
            }
            
            Text(fuel.formattedCountdownTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(displayColor)
                .monospacedDigit()
            
            if isUrgent {
                Text("⚠️ PREPARE TO SWAP")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .tracking(1)
            } else {
                Text("Based on observed GPH")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(isUrgent ? Color.orange.opacity(0.1) : Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(displayColor.opacity(0.5), lineWidth: isUrgent ? 3 : 2)
        )
    }
}

// MARK: - Compact Leg Timer View

struct CompactLegTimerView: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondaryText.opacity(0.6))
            
            Text("LEG TIME:")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText.opacity(0.6))
                .tracking(1)
            
            Text(fuel.formattedLegTime)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(fuel.engineRunning ? .secondaryText : .secondaryText.opacity(0.5))
                .monospacedDigit()
            
            if !fuel.engineRunning && fuel.currentLegTime > 0 {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - GPH Input View

struct GPHInputView: View {
    @ObservedObject var fuel: FuelState
    @Binding var gphInput: String
    let onCancel: () -> Void
    let onConfirm: (Double) -> Void
    
    @State private var error = ""
    @FocusState private var focused: Bool
    
    var isValid: Bool {
        guard let gph = Double(gphInput) else { return false }
        return gph > 0 && gph < 100  // Reasonable GPH range
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("OBSERVED GPH")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .tracking(3)
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Enter current GPH from instrument")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    if let currentGPH = fuel.currentObservedGPH {
                        Text("Current: \(String(format: "%.1f", currentGPH)) GPH")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.fuelActive)
                    }
                }
                
                TextField("0.0", text: $gphInput)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .frame(width: 200, height: 70)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(error.isEmpty ? (focused ? .fuelActive : Color.white.opacity(0.15)) : .fuelLow, lineWidth: 2)
                    )
                    .onChange(of: gphInput) {
                        validateInput()
                    }
                
                Text(error)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.fuelLow)
                    .frame(height: 14)
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .frame(width: 120, height: 44)
                    .background(Color.buttonDisabled)
                    .cornerRadius(8)
                    
                    Button("Log GPH") {
                        if let gph = Double(gphInput), isValid {
                            onConfirm(gph)
                        }
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 44)
                    .background(isValid ? Color.fuelActive : Color.buttonDisabled)
                    .cornerRadius(8)
                    .disabled(!isValid)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            focused = true
        }
    }
    
    func validateInput() {
        error = ""
        guard let gph = Double(gphInput) else { return }
        if gph <= 0 {
            error = "Must be greater than 0"
        } else if gph >= 100 {
            error = "Must be less than 100"
        }
    }
}

// MARK: - Leg Timer View (kept for reference, now using compact version)

struct LegTimerView: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        VStack(spacing: 6) {
            Text("LEG TIME")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            Text(fuel.formattedLegTime)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(fuel.engineRunning ? .fuelActive : .secondaryText)
            
            if !fuel.engineRunning && fuel.currentLegTime > 0 {
                Text("ENGINE STOPPED")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText.opacity(0.6))
                    .tracking(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(fuel.engineRunning ? Color.fuelActive.opacity(0.3) : Color.white.opacity(0.1), lineWidth: fuel.engineRunning ? 2 : 1)
        )
    }
}

// MARK: - Shutdown Prompt

struct ShutdownPromptView: View {
    @ObservedObject var fuel: FuelState
    @Binding var shutdownInput: String
    let onCancel: () -> Void
    let onConfirm: (Double) -> Void
    
    @State private var error = ""
    @FocusState private var focused: Bool
    
    var isValid: Bool {
        guard let reading = Double(shutdownInput) else { return false }
        let last = fuel.lastReading ?? 0
        return reading >= last
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("SHUTDOWN")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .tracking(3)
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Current Totalizer Reading?")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    if let last = fuel.lastReading {
                        Text("Last: \(String(format: "%.1f", last))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondaryText.opacity(0.6))
                    }
                }
                
                TextField("0.0", text: $shutdownInput)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .frame(width: 200, height: 70)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(error.isEmpty ? (focused ? .accentText : Color.white.opacity(0.15)) : .fuelLow, lineWidth: 2)
                    )
                    .onChange(of: shutdownInput) {
                        validateInput()
                    }
                
                Text(error)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.fuelLow)
                    .frame(height: 14)
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .frame(width: 120, height: 44)
                    .background(Color.buttonDisabled)
                    .cornerRadius(8)
                    
                    Button("Shutdown") {
                        if let reading = Double(shutdownInput), isValid {
                            onConfirm(reading)
                        }
                    }
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 44)
                    .background(isValid ? Color.accentText : Color.buttonDisabled)
                    .cornerRadius(8)
                    .disabled(!isValid)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            focused = true
        }
    }
    
    func validateInput() {
        error = ""
        guard let reading = Double(shutdownInput) else { return }
        let last = fuel.lastReading ?? 0
        if reading < last {
            error = "Must be ≥ \(String(format: "%.1f", last))"
        }
    }
}

#Preview {
    FlightView(fuel: FuelState())
}

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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HeaderView(fuel: fuel)
                
                // Phase indicator
                PhaseIndicator(fuel: fuel)
                
                // Reserve display
                Text("SAFETY RESERVE: \(String(format: "%.1f", FuelState.safetyReserve)) GAL")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(1)
                
                // Tank display
                TankDisplay(fuel: fuel)
                
                // Last reading
                LastReadingBox(fuel: fuel)
                
                // Swap targets
                SwapTargets(fuel: fuel)
                
                // Input section
                InputSection(
                    fuel: fuel,
                    totalizerInput: $totalizerInput,
                    inputError: $inputError,
                    inputFocused: $inputFocused
                )
                
                // History
                if !fuel.swapLog.isEmpty {
                    HistoryView(fuel: fuel)
                }
            }
            .padding()
        }
        .onTapGesture {
            inputFocused = false
        }
    }
}

// MARK: - Header

struct HeaderView: View {
    @ObservedObject var fuel: FuelState
    
    var body: some View {
        HStack {
            // Left buttons
            HStack(spacing: 8) {
                Button(action: { fuel.endFlight() }) {
                    Text("✕")
                        .font(.system(size: 20))
                        .foregroundColor(.secondaryText)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondaryText, lineWidth: 1)
                        )
                }
                
                Button(action: { fuel.undoLastSwap() }) {
                    Text("↩")
                        .font(.system(size: 18))
                        .foregroundColor(fuel.swapLog.isEmpty ? Color.gray.opacity(0.3) : .gray)
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondaryText, lineWidth: 1)
                        )
                }
                .disabled(fuel.swapLog.isEmpty)
            }
            
            Spacer()
            
            // Center info
            VStack(spacing: 4) {
                Text(fuel.preset.rawValue)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(3)
                
                Text(String(format: "%.1f GAL", fuel.totalRemaining))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.accentText)
            }
            
            Spacer()
            
            // Swap count
            Text("#\(fuel.swapLog.count + 1)")
                .font(.system(size: 18, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .frame(width: 44, alignment: .trailing)
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
            return (.fuelLow, .fuelLow.opacity(0.33), .cardBackground.opacity(0.5))
        }
        if fuel.phase == .tips {
            return (.fuelActive, .fuelActive.opacity(0.2), .cardBackground)
        }
        if fuel.flightMode == .endurance {
            return (.fuelActive, .fuelActive.opacity(0.2), .cardBackground)
        }
        if fuel.flightMode == .balanced {
            return (.accentText, .accentText.opacity(0.27), .cardBackground)
        }
        return (.gray, Color.white.opacity(0.1), .cardBackground)
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
    
    var body: some View {
        HStack(spacing: 8) {
            // Left wing
            HStack(spacing: 8) {
                TankGauge(fuel: fuel, tank: "lTip")
                TankGauge(fuel: fuel, tank: "lMain")
            }
            
            // Center indicator
            CenterIndicator(fuel: fuel)
            
            // Right wing
            HStack(spacing: 8) {
                TankGauge(fuel: fuel, tank: "rMain")
                TankGauge(fuel: fuel, tank: "rTip")
            }
        }
    }
}

// MARK: - Tank Gauge

struct TankGauge: View {
    @ObservedObject var fuel: FuelState
    let tank: String
    
    var remaining: Double { fuel.remaining(tank) }
    var maxFuel: Double { tank.contains("Tip") ? 17.0 : 25.0 }
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
                    .frame(width: 28, height: 70)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(fillColor)
                    .frame(width: 28, height: CGFloat(fillPercent * 70))
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
        return fuel.isLeft(fuel.currentTank) ? .accentText : .fuelLow
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("BURNING")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            Text(fuel.fuelExhausted ? "--" : fuel.tankLabel(fuel.currentTank))
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
                // First swap - climbout
                TargetBox(label: "SWAP AT", value: "7.0", style: .endurance)
            } else if fuel.swapLog.count == 1 && fuel.phase == .mains && fuel.preset == .topoff && fuel.flightMode == nil {
                // Swap 2 for topoff - show both options
                if let targets = fuel.calcTargets() {
                    HStack(spacing: 16) {
                        TargetBox(label: "BALANCED", value: String(format: "%.1f", targets.balanced), style: .balanced)
                        TargetBox(label: "ENDURANCE", value: String(format: "%.1f", targets.endurance), style: .endurance)
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
        case .warning: return .cardBackground.opacity(0.5)
        case .zeroFuel: return Color.red.opacity(0.1)
        default: return .cardBackground
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: style == .zeroFuel ? 11 : 9, weight: (style == .warning || style == .zeroFuel) ? .bold : .regular, design: .monospaced))
                .foregroundColor(labelColor)
                .tracking(2)
            
            Text(value)
                .font(.system(size: style == .zeroFuel ? 36 : 32, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(bgColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: style == .zeroFuel ? 2 : 1)
        )
        .frame(minWidth: style == .zeroFuel ? 200 : (style == .warning ? 180 : 140))
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
            Text("TOTALIZER USED")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(2)
            
            TextField("0.0", text: $totalizerInput)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
                .keyboardType(.decimalPad)
                .focused($inputFocused)
                .frame(width: 180, height: 60)
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(inputError.isEmpty ? (inputFocused ? .accentText : Color.white.opacity(0.15)) : .fuelLow, lineWidth: 2)
                )
                .onChange(of: totalizerInput) {
                    validateInput()
                }
            
            Text(inputError)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.fuelLow)
                .frame(height: 14)
            
            Button(action: logSwap) {
                Text("LOG SWAP")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .tracking(2)
                    .foregroundColor(canLog ? .black : .gray)
                    .frame(width: 200, height: 52)
                    .background(canLog ? Color.accentText : Color.buttonDisabled)
                    .cornerRadius(8)
            }
            .disabled(!canLog)
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
        VStack(spacing: 4) {
            ForEach(fuel.swapLog.suffix(4).reversed()) { entry in
                HStack(spacing: 12) {
                    Text("#\(entry.swapNumber)")
                        .foregroundColor(.secondaryText)
                        .frame(width: 24, alignment: .leading)
                    
                    Text(entry.tank)
                        .foregroundColor(.secondaryText)
                        .frame(width: 55, alignment: .leading)
                    
                    Text(String(format: "%.1f", entry.totalizer))
                        .foregroundColor(.secondaryText)
                        .frame(width: 45, alignment: .trailing)
                    
                    Text(String(format: "+%.1f", entry.burned))
                        .foregroundColor(.accentText)
                }
                .font(.system(size: 12, weight: .regular, design: .monospaced))
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }
}

#Preview {
    FlightView(fuel: FuelState())
}

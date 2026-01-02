import SwiftUI

struct StartView: View {
    @ObservedObject var fuel: FuelState
    @State private var showSplash = false
    @State private var splashTanks: [String: Double] = ["lTip": 17, "lMain": 25, "rMain": 25, "rTip": 17]
    
    var splashTotal: Double {
        splashTanks.values.reduce(0, +)
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 8) {
                Spacer()
                
                // Title
                Text("N215C")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.fuelActive)
                    .tracking(4)
                
                Text("Fuel Tracker")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(8)
                    .padding(.bottom, 32)
                
                // Resume box (if flight in progress)
                if fuel.swapLog.count > 0 || fuel.tankBurned.values.contains(where: { $0 > 0 }) {
                    ResumeBox(fuel: fuel)
                        .padding(.bottom, 32)
                }
                
                Text("NEW FLIGHT")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(3)
                    .padding(.bottom, 16)
                
                // Preset buttons
                HStack(spacing: 20) {
                    PresetButton(name: "TOP OFF", gallons: 84, tanks: "17 / 25 / 25 / 17") {
                        fuel.startFlight(.topoff, aircraft: .n215c)
                    }
                    
                    PresetButton(name: "TABS", gallons: 70, tanks: "17 / 18 / 18 / 17") {
                        fuel.startFlight(.tabs, aircraft: .n215c)
                    }
                }
                .padding(.bottom, 20)
                
                // Splash button
                Button(action: { showSplash.toggle() }) {
                    Text("QUANTITY OVERRIDE")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Splash panel
                if showSplash {
                    SplashPanel(tanks: $splashTanks, total: splashTotal) {
                        fuel.startFlight(.custom, aircraft: .n215c, customTanks: splashTanks)
                    }
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Resume Box
    
    struct ResumeBox: View {
        @ObservedObject var fuel: FuelState
        @State private var showAddFuel = false
        @State private var addAmounts: [String: Double] = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        
        var body: some View {
            VStack(spacing: 16) {
                Text("SAVED FLIGHT")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.fuelActive)
                    .tracking(2)
                
                Text("\(fuel.preset.rawValue) • \(String(format: "%.1f", fuel.totalRemaining)) GAL • Swap #\(fuel.swapLog.count + 1)")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                
                if !showAddFuel {
                    HStack(spacing: 10) {
                        Button("RESUME") {
                            fuel.isFlying = true
                        }
                        .buttonStyle(ResumeButtonStyle(isPrimary: true))
                        
                        Button("ADD FUEL") {
                            showAddFuel = true
                        }
                        .buttonStyle(ResumeButtonStyle(isSecondary: true))
                        
                        Button("CLEAR") {
                            fuel.clearFlight()
                        }
                        .buttonStyle(ResumeButtonStyle())
                    }
                } else {
                    AddFuelPanel(fuel: fuel, addAmounts: $addAmounts) {
                        showAddFuel = false
                    }
                }
            }
            .padding(20)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.fuelActive.opacity(0.27), lineWidth: 1)
            )
            .frame(maxWidth: 340)
        }
    }
    
    // MARK: - Preset Button
    
    struct PresetButton: View {
        let name: String
        let gallons: Int
        let tanks: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    Text(name)
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("\(gallons) GAL")
                        .font(.system(size: 16, weight: .regular, design: .monospaced))
                        .foregroundColor(Color.accentText)
                    
                    Text(tanks)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                        .tracking(1)
                }
                .padding(.horizontal, 36)
                .padding(.vertical, 28)
                .background(Color.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - Splash Panel
    
    struct SplashPanel: View {
        @Binding var tanks: [String: Double]
        let total: Double
        let onStart: () -> Void
        
        var body: some View {
            VStack(spacing: 14) {
                Text("MANUAL FUEL QUANTITY")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(2)
                
                HStack(spacing: 8) {
                    TankInput(label: "L TIP", value: Binding(
                        get: { tanks["lTip"] ?? 0 },
                        set: { tanks["lTip"] = min(17, max(0, $0)) }
                    ), max: 17)
                    TankInput(label: "L MAIN", value: Binding(
                        get: { tanks["lMain"] ?? 0 },
                        set: { tanks["lMain"] = min(25, max(0, $0)) }
                    ), max: 25)
                    TankInput(label: "R MAIN", value: Binding(
                        get: { tanks["rMain"] ?? 0 },
                        set: { tanks["rMain"] = min(25, max(0, $0)) }
                    ), max: 25)
                    TankInput(label: "R TIP", value: Binding(
                        get: { tanks["rTip"] ?? 0 },
                        set: { tanks["rTip"] = min(17, max(0, $0)) }
                    ), max: 17)
                }
                
                HStack {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f GAL", total))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.fuelActive)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
                
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
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .frame(maxWidth: 340)
        }
    }
    
    // MARK: - Tank Input
    
    struct TankInput: View {
        let label: String
        @Binding var value: Double
        let max: Double
        
        var body: some View {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                TextField("", value: $value, format: .number)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.accentText)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(width: 44, height: 32)
                    .background(Color.black.opacity(0.15))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentText, lineWidth: 1)
                    )
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Add Fuel Panel
    
    struct AddFuelPanel: View {
        @ObservedObject var fuel: FuelState
        @Binding var addAmounts: [String: Double]
        let onCancel: () -> Void
        
        var newTotal: Double {
            fuel.totalRemaining + addAmounts.values.reduce(0, +)
        }
        
        var body: some View {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    AddFuelTank(label: "L TIP", current: fuel.remaining("lTip"), add: Binding(
                        get: { addAmounts["lTip"] ?? 0 },
                        set: { addAmounts["lTip"] = $0 }
                    ), max: 17 - fuel.remaining("lTip"))
                    AddFuelTank(label: "L MAIN", current: fuel.remaining("lMain"), add: Binding(
                        get: { addAmounts["lMain"] ?? 0 },
                        set: { addAmounts["lMain"] = $0 }
                    ), max: 25 - fuel.remaining("lMain"))
                    AddFuelTank(label: "R MAIN", current: fuel.remaining("rMain"), add: Binding(
                        get: { addAmounts["rMain"] ?? 0 },
                        set: { addAmounts["rMain"] = $0 }
                    ), max: 25 - fuel.remaining("rMain"))
                    AddFuelTank(label: "R TIP", current: fuel.remaining("rTip"), add: Binding(
                        get: { addAmounts["rTip"] ?? 0 },
                        set: { addAmounts["rTip"] = $0 }
                    ), max: 17 - fuel.remaining("rTip"))
                }
                
                HStack {
                    Text("NEW TOTAL")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text(String(format: "%.1f GAL", newTotal))
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.fuelActive)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.3))
                .cornerRadius(6)
                
                Button(action: {
                    let newTanks: [String: Double] = [
                        "lTip": min(17, fuel.remaining("lTip") + (addAmounts["lTip"] ?? 0)),
                        "lMain": min(25, fuel.remaining("lMain") + (addAmounts["lMain"] ?? 0)),
                        "rMain": min(25, fuel.remaining("rMain") + (addAmounts["rMain"] ?? 0)),
                        "rTip": min(17, fuel.remaining("rTip") + (addAmounts["rTip"] ?? 0))
                    ]
                    fuel.startFlight(.custom, aircraft: .n215c, customTanks: newTanks)
                }) {
                    Text("START NEW CYCLE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentText)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 16)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.black.opacity(0.15)),
                alignment: .top
            )
        }
    }
    
    // MARK: - Add Fuel Tank
    
    struct AddFuelTank: View {
        let label: String
        let current: Double
        @Binding var add: Double
        let max: Double
        
        var newValue: Double {
            current + add
        }
        
        var body: some View {
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                Text(String(format: "%.1f", current))
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
                
                HStack(spacing: 2) {
                    Text("+")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(Color.accentText)
                    
                    TextField("", value: $add, format: .number)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.accentText)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .frame(width: 36, height: 26)
                        .background(Color.black.opacity(0.15))
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.accentText, lineWidth: 1)
                        )
                }
                
                Text(String(format: "%.1f", newValue))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.fuelActive)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Button Styles
    
    struct ResumeButtonStyle: ButtonStyle {
        var isPrimary = false
        var isSecondary = false
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundColor(isPrimary ? .black : (isSecondary ? Color.accentText : .gray))
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(isPrimary ? Color.fuelActive : Color.clear)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isPrimary ? Color.fuelActive : (isSecondary ? Color.accentText : Color.secondaryText), lineWidth: 2)
                )
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
        }
    }
}

#Preview {
    StartView(fuel: FuelState())
}


import SwiftUI
import Combine

enum Preset: String, Codable {
    case topoff = "TOP OFF"
    case tabs = "TABS"
    case custom = "CUSTOM"
    
    var tanks: [String: Double] {
        switch self {
        case .topoff: return ["lTip": 17, "lMain": 25, "rMain": 25, "rTip": 17]
        case .tabs: return ["lTip": 17, "lMain": 18, "rMain": 18, "rTip": 17]
        case .custom: return ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        }
    }
    
    var total: Double {
        tanks.values.reduce(0, +)
    }
}

enum FlightMode: String, Codable {
    case balanced = "BALANCED"
    case endurance = "ENDURANCE"
}

enum Phase: String, Codable {
    case mains = "MAINS"
    case tips = "TIPS"
}

struct SwapEntry: Codable, Identifiable {
    let id: UUID
    let swapNumber: Int
    let tank: String
    let totalizer: Double
    let burned: Double
    
    init(swapNumber: Int, tank: String, totalizer: Double, burned: Double) {
        self.id = UUID()
        self.swapNumber = swapNumber
        self.tank = tank
        self.totalizer = totalizer
        self.burned = burned
    }
}

@MainActor
class FuelState: ObservableObject {
    // Constants
    static let safetyReserve = 0.9
    static let exhaustedThreshold = 2.0
    static let lowWarn = 3.0
    static let tipBurn = 8.0
    static let climbout = 7.0
    
    // Published state
    @Published var isFlying = false
    @Published var preset: Preset = .topoff
    @Published var customFuel: [String: Double] = [:]
    @Published var currentTank: String = "lMain"
    @Published var swapLog: [SwapEntry] = []
    @Published var tankBurned: [String: Double] = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
    @Published var phase: Phase = .mains
    @Published var fuelExhausted = false
    @Published var flightMode: FlightMode? = nil
    @Published var swap2Targets: (balanced: Double, endurance: Double)? = nil
    
    private let storageKey = "n215c_fuel_state"
    
    init() {
        load()
    }
    
    // MARK: - Computed Properties
    
    var tankOrder: [String] { ["lTip", "lMain", "rMain", "rTip"] }
    
    func startFuel(_ tank: String) -> Double {
        if preset == .custom {
            return customFuel[tank] ?? 0
        }
        return preset.tanks[tank] ?? 0
    }
    
    func remaining(_ tank: String) -> Double {
        max(0, startFuel(tank) - (tankBurned[tank] ?? 0))
    }
    
    var totalRemaining: Double {
        tankOrder.reduce(0) { $0 + remaining($1) }
    }
    
    var lastReading: Double? {
        swapLog.last?.totalizer
    }
    
    func isExhausted(_ tank: String) -> Bool {
        remaining(tank) < Self.exhaustedThreshold
    }
    
    var mainsExhausted: Bool {
        isExhausted("lMain") && isExhausted("rMain")
    }
    
    var usableTankCount: Int {
        tankOrder.filter { remaining($0) >= Self.exhaustedThreshold }.count
    }
    
    var isLastTank: Bool {
        remaining(currentTank) >= Self.exhaustedThreshold && usableTankCount == 1
    }
    
    var isLastBurnForTank: Bool {
        let rem = remaining(currentTank)
        guard rem >= Self.exhaustedThreshold else { return false }
        let available = rem - Self.safetyReserve
        let normalBurn = getNormalBurn()
        return available <= normalBurn + 1
    }
    
    var nextTank: String? {
        guard !fuelExhausted else { return nil }
        
        let lm = remaining("lMain"), rm = remaining("rMain")
        let lt = remaining("lTip"), rt = remaining("rTip")
        let threshold = Self.exhaustedThreshold
        
        if phase == .tips {
            if currentTank == "lTip" {
                return rt >= threshold ? "rTip" : (lt >= threshold ? "lTip" : nil)
            }
            if currentTank == "rTip" {
                return lt >= threshold ? "lTip" : (rt >= threshold ? "rTip" : nil)
            }
            return lt >= rt ? (lt >= threshold ? "lTip" : (rt >= threshold ? "rTip" : nil))
                            : (rt >= threshold ? "rTip" : (lt >= threshold ? "lTip" : nil))
        }
        
        if !mainsExhausted {
            if currentTank == "lMain" {
                return rm >= threshold ? "rMain" : (lm >= threshold ? "lMain" : nil)
            }
            if currentTank == "rMain" {
                return lm >= threshold ? "lMain" : (rm >= threshold ? "rMain" : nil)
            }
            return lm >= rm ? "lMain" : "rMain"
        }
        
        // Mains exhausted, go to tips
        return lt >= rt ? (lt >= threshold ? "lTip" : (rt >= threshold ? "rTip" : nil))
                        : (rt >= threshold ? "rTip" : (lt >= threshold ? "lTip" : nil))
    }
    
    func getNormalBurn() -> Double {
        if phase == .tips { return Self.tipBurn }
        
        let cur = remaining(currentTank)
        
        if preset == .tabs || preset == .custom {
            return min(11, max(10, cur - Self.safetyReserve))
        }
        
        if preset == .topoff {
            if flightMode == .endurance {
                return min(19, cur - Self.safetyReserve)
            }
            return min(10, max(7, cur - Self.safetyReserve))
        }
        
        return min(10, cur - Self.safetyReserve)
    }
    
    var maxTarget: Double? {
        guard let last = lastReading else { return nil }
        let rem = remaining(currentTank)
        return last + max(0, rem - Self.safetyReserve)
    }
    
    func calcTargets() -> (balanced: Double, endurance: Double)? {
        guard let last = lastReading, phase == .mains else { return nil }
        let cur = remaining(currentTank)
        
        // Balanced
        var balBurn = min(10, cur - Self.safetyReserve)
        balBurn = max(7, balBurn)
        if balBurn > cur - Self.safetyReserve { balBurn = cur - Self.safetyReserve }
        
        // Endurance (topoff only)
        let endBurn = preset == .topoff ? min(19, cur - Self.safetyReserve) : balBurn
        
        return (last + balBurn, last + endBurn)
    }
    
    // MARK: - Actions
    
    func startFlight(_ selectedPreset: Preset, customTanks: [String: Double]? = nil) {
        preset = selectedPreset
        customFuel = customTanks ?? [:]
        currentTank = "lMain"
        swapLog = []
        tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        phase = .mains
        fuelExhausted = false
        flightMode = selectedPreset == .tabs ? .balanced : nil
        swap2Targets = nil
        isFlying = true
        save()
    }
    
    func logSwap(reading: Double) {
        guard !fuelExhausted else { return }
        
        let burned = swapLog.isEmpty ? reading : reading - (lastReading ?? 0)
        
        // Determine mode on swap 2 for topoff
        if swapLog.count == 1, let targets = swap2Targets, preset == .topoff {
            let avg = (targets.balanced + targets.endurance) / 2
            flightMode = reading > avg ? .endurance : .balanced
        }
        
        tankBurned[currentTank, default: 0] += burned
        
        let entry = SwapEntry(
            swapNumber: swapLog.count + 1,
            tank: tankLabel(currentTank),
            totalizer: reading,
            burned: burned
        )
        swapLog.append(entry)
        
        // Phase transition
        if phase == .mains && mainsExhausted {
            phase = .tips
        }
        
        if let next = nextTank {
            currentTank = next
        } else {
            fuelExhausted = true
        }
        
        save()
    }
    
    func undoLastSwap() {
        guard let last = swapLog.popLast() else { return }
        
        let tankKey = tankKeyFromLabel(last.tank)
        tankBurned[tankKey, default: 0] -= last.burned
        currentTank = tankKey
        
        if phase == .tips && (tankKey == "lMain" || tankKey == "rMain") {
            phase = .mains
        }
        
        if swapLog.count <= 1 && preset != .tabs && preset != .custom {
            flightMode = nil
            swap2Targets = nil
        }
        
        fuelExhausted = false
        save()
    }
    
    func shutdown(reading: Double) {
        guard !fuelExhausted else {
            isFlying = false
            save()
            return
        }
        
        // Calculate fuel burned since last swap
        let burned = swapLog.isEmpty ? reading : reading - (lastReading ?? 0)
        
        // Update current tank
        tankBurned[currentTank, default: 0] += burned
        
        // Log shutdown as special entry (for reference)
        let shutdownEntry = SwapEntry(
            swapNumber: swapLog.count + 1,
            tank: tankLabel(currentTank) + " (SHUTDOWN)",
            totalizer: reading,
            burned: burned
        )
        swapLog.append(shutdownEntry)
        
        isFlying = false
        save()
    }

    func cancelFlight() {
        isFlying = false
        save()
    }
    
    func clearFlight() {
        isFlying = false
        preset = .topoff
        customFuel = [:]
        currentTank = "lMain"
        swapLog = []
        tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        phase = .mains
        fuelExhausted = false
        flightMode = nil
        swap2Targets = nil
        clearStorage()
    }
    
    // MARK: - Helpers
    
    func tankLabel(_ key: String) -> String {
        ["lMain": "L MAIN", "rMain": "R MAIN", "lTip": "L TIP", "rTip": "R TIP"][key] ?? key
    }
    
    func tankKeyFromLabel(_ label: String) -> String {
        ["L MAIN": "lMain", "R MAIN": "rMain", "L TIP": "lTip", "R TIP": "rTip"][label] ?? label
    }
    
    func isLeft(_ tank: String) -> Bool {
        tank.hasPrefix("l")
    }
    
    // MARK: - Persistence
    
    private func save() {
        let data = SavedState(
            preset: preset,
            customFuel: customFuel,
            currentTank: currentTank,
            swapLog: swapLog,
            tankBurned: tankBurned,
            phase: phase,
            fuelExhausted: fuelExhausted,
            flightMode: flightMode
        )
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode(SavedState.self, from: data) else { return }
        
        preset = saved.preset
        customFuel = saved.customFuel
        currentTank = saved.currentTank
        swapLog = saved.swapLog
        tankBurned = saved.tankBurned
        phase = saved.phase
        fuelExhausted = saved.fuelExhausted
        flightMode = saved.flightMode
        isFlying = !swapLog.isEmpty || tankBurned.values.contains { $0 > 0 }
    }
    
    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

private struct SavedState: Codable {
    let preset: Preset
    let customFuel: [String: Double]
    let currentTank: String
    let swapLog: [SwapEntry]
    let tankBurned: [String: Double]
    let phase: Phase
    let fuelExhausted: Bool
    let flightMode: FlightMode?
}

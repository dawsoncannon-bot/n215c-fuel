import SwiftUI
import Combine
import Foundation

// MARK: - Fuel Stop

struct FuelStop: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    var fuelAdded: [String: Double]  // Per tank
    var pricePerGallon: Double?
    var totalCost: Double?
    var location: String?  // Optional airport code
    var notes: String?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), fuelAdded: [String: Double], pricePerGallon: Double? = nil, totalCost: Double? = nil, location: String? = nil, notes: String? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.fuelAdded = fuelAdded
        self.pricePerGallon = pricePerGallon
        self.totalCost = totalCost
        self.location = location
        self.notes = notes
    }
    
    var totalAdded: Double {
        fuelAdded.values.reduce(0, +)
    }
}

// MARK: - Flight Leg

struct FlightLeg: Codable, Identifiable {
    let id: UUID
    var legNumber: Int
    var startTime: Date
    var endTime: Date?
    var startingFuel: [String: Double]
    var swapLog: [SwapEntry]
    var currentTank: String
    var phase: Phase
    var flightMode: FlightMode?
    var preset: Preset
    var fuelExhausted: Bool
    var swap2Targets: (balanced: Double, endurance: Double)?
    
    init(id: UUID = UUID(), legNumber: Int, startTime: Date = Date(), endTime: Date? = nil, startingFuel: [String: Double], swapLog: [SwapEntry] = [], currentTank: String = "lMain", phase: Phase = .mains, flightMode: FlightMode? = nil, preset: Preset, fuelExhausted: Bool = false, swap2Targets: (balanced: Double, endurance: Double)? = nil) {
        self.id = id
        self.legNumber = legNumber
        self.startTime = startTime
        self.endTime = endTime
        self.startingFuel = startingFuel
        self.swapLog = swapLog
        self.currentTank = currentTank
        self.phase = phase
        self.flightMode = flightMode
        self.preset = preset
        self.fuelExhausted = fuelExhausted
        self.swap2Targets = swap2Targets
    }
    
    var totalBurned: Double {
        swapLog.reduce(0) { $0 + $1.burned }
    }
    
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    // Codable conformance for tuple
    enum CodingKeys: String, CodingKey {
        case id, legNumber, startTime, endTime, startingFuel, swapLog, currentTank, phase, flightMode, preset, fuelExhausted
        case swap2TargetsBalanced, swap2TargetsEndurance
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        legNumber = try container.decode(Int.self, forKey: .legNumber)
        startTime = try container.decode(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        startingFuel = try container.decode([String: Double].self, forKey: .startingFuel)
        swapLog = try container.decode([SwapEntry].self, forKey: .swapLog)
        currentTank = try container.decode(String.self, forKey: .currentTank)
        phase = try container.decode(Phase.self, forKey: .phase)
        flightMode = try container.decodeIfPresent(FlightMode.self, forKey: .flightMode)
        preset = try container.decode(Preset.self, forKey: .preset)
        fuelExhausted = try container.decode(Bool.self, forKey: .fuelExhausted)
        
        if let balanced = try container.decodeIfPresent(Double.self, forKey: .swap2TargetsBalanced),
           let endurance = try container.decodeIfPresent(Double.self, forKey: .swap2TargetsEndurance) {
            swap2Targets = (balanced, endurance)
        } else {
            swap2Targets = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(legNumber, forKey: .legNumber)
        try container.encode(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(startingFuel, forKey: .startingFuel)
        try container.encode(swapLog, forKey: .swapLog)
        try container.encode(currentTank, forKey: .currentTank)
        try container.encode(phase, forKey: .phase)
        try container.encodeIfPresent(flightMode, forKey: .flightMode)
        try container.encode(preset, forKey: .preset)
        try container.encode(fuelExhausted, forKey: .fuelExhausted)
        
        if let targets = swap2Targets {
            try container.encode(targets.balanced, forKey: .swap2TargetsBalanced)
            try container.encode(targets.endurance, forKey: .swap2TargetsEndurance)
        }
    }
}

// MARK: - Trip

struct Trip: Codable, Identifiable {
    let id: UUID
    var name: String?  // "Phoenix → Salt Lake → Denver"
    var legs: [FlightLeg]
    var fuelStops: [FuelStop]
    var startDate: Date
    var endDate: Date?
    
    init(id: UUID = UUID(), name: String? = nil, legs: [FlightLeg] = [], fuelStops: [FuelStop] = [], startDate: Date = Date(), endDate: Date? = nil) {
        self.id = id
        self.name = name
        self.legs = legs
        self.fuelStops = fuelStops
        self.startDate = startDate
        self.endDate = endDate
    }
    
    var totalFuelConsumed: Double {
        legs.reduce(0) { $0 + $1.totalBurned }
    }
    
    var totalFuelCost: Double {
        fuelStops.compactMap { $0.totalCost }.reduce(0, +)
    }
    
    var totalDuration: TimeInterval {
        legs.compactMap { $0.duration }.reduce(0, +)
    }
}

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
    
    // Published state - Trip/Leg tracking
    @Published var currentTrip: Trip?
    @Published var currentLeg: FlightLeg?
    
    // Published state - Legacy (for backwards compatibility)
    @Published var isFlying = false
    @Published var engineRunning = false
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
    private let tripStorageKey = "n215c_current_trip"
    
    init() {
        load()
    }
    
    // MARK: - Computed Properties
    
    var tankOrder: [String] { ["lTip", "lMain", "rMain", "rTip"] }
    
    var legNumber: Int {
        if let trip = currentTrip {
            return trip.legs.count + (currentLeg != nil ? 1 : 0)
        }
        return 1
    }
    
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
        let available = cur - Self.safetyReserve
        
        // Safety check: never exceed available fuel
        guard available > 0 else { return 0 }
        
        var targetBurn: Double
        
        if preset == .tabs || preset == .custom {
            targetBurn = min(11, max(10, available))
        } else if preset == .topoff {
            if flightMode == .endurance {
                targetBurn = min(19, available)
            } else {
                targetBurn = min(10, max(7, available))
            }
        } else {
            targetBurn = min(10, available)
        }
        
        // CRITICAL SAFETY: If tank has less than 10 gal after adding fuel,
        // cap the burn to available fuel (do not exceed mode)
        if cur < 10 {
            targetBurn = min(targetBurn, available)
        }
        
        return max(0, min(targetBurn, available))
    }
    
    var maxTarget: Double? {
        guard let last = lastReading else { return nil }
        let rem = remaining(currentTank)
        return last + max(0, rem - Self.safetyReserve)
    }
    
    func calcTargets() -> (balanced: Double, endurance: Double)? {
        guard let last = lastReading, phase == .mains else { return nil }
        let cur = remaining(currentTank)
        let available = cur - Self.safetyReserve
        
        // Safety check: never exceed available fuel
        guard available > 0 else { return nil }
        
        // Balanced
        var balBurn = min(10, available)
        balBurn = max(7, balBurn)
        
        // Critical safety: if tank has less than 10 gal, cap at available
        if cur < 10 {
            balBurn = min(balBurn, available)
        }
        
        // Ensure never exceeds available
        balBurn = min(balBurn, available)
        
        // Endurance (topoff only)
        var endBurn = preset == .topoff ? min(19, available) : balBurn
        if cur < 10 {
            endBurn = min(endBurn, available)
        }
        endBurn = min(endBurn, available)
        
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
        engineRunning = false  // Start suspended
        
        // Create new trip and leg
        let startingFuel = selectedPreset == .custom ? (customTanks ?? [:]) : selectedPreset.tanks
        
        if currentTrip == nil {
            // Start new trip
            currentTrip = Trip(startDate: Date())
        }
        
        // Create new leg
        let legNum = (currentTrip?.legs.count ?? 0) + 1
        currentLeg = FlightLeg(
            legNumber: legNum,
            startTime: Date(),
            startingFuel: startingFuel,
            preset: selectedPreset
        )
        
        save()
    }
    
    func addFuel(newTanks: [String: Double], pricePerGallon: Double? = nil, totalCost: Double? = nil, location: String? = nil) {
        // End current leg first
        endCurrentLeg()
        
        // Calculate fuel added per tank
        var fuelAdded: [String: Double] = [:]
        for tank in tankOrder {
            let current = remaining(tank)
            let newAmount = newTanks[tank] ?? 0
            fuelAdded[tank] = max(0, newAmount - current)
        }
        
        // Create fuel stop record
        let fuelStop = FuelStop(
            fuelAdded: fuelAdded,
            pricePerGallon: pricePerGallon,
            totalCost: totalCost,
            location: location
        )
        
        // Add to current trip
        if currentTrip == nil {
            currentTrip = Trip(startDate: Date())
        }
        currentTrip?.fuelStops.append(fuelStop)
        
        // Start new leg with updated fuel
        preset = .custom
        customFuel = newTanks
        currentTank = "lMain"
        swapLog = []
        tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        phase = .mains
        fuelExhausted = false
        flightMode = nil
        swap2Targets = nil
        isFlying = true  // KEEP FLYING
        engineRunning = false  // Start suspended (ready to start engine)
        
        // Create new leg
        let legNum = (currentTrip?.legs.count ?? 0) + 1
        currentLeg = FlightLeg(
            legNumber: legNum,
            startTime: Date(),
            startingFuel: newTanks,
            preset: .custom
        )
        
        save()
    }
    
    func endCurrentLeg() {
        guard var leg = currentLeg else { return }
        
        // Finalize leg data
        leg.endTime = Date()
        leg.swapLog = swapLog
        leg.currentTank = currentTank
        leg.phase = phase
        leg.flightMode = flightMode
        leg.fuelExhausted = fuelExhausted
        leg.swap2Targets = swap2Targets
        
        // Add to trip
        if currentTrip == nil {
            currentTrip = Trip(startDate: leg.startTime)
        }
        currentTrip?.legs.append(leg)
        
        // Clear current leg
        currentLeg = nil
        
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
            engineRunning = false
            endCurrentLeg()
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
        
        engineRunning = false
        endCurrentLeg()  // End leg when engine shuts down
        save()
    }
    
    func startEngine() {
        engineRunning = true
        save()
    }
    
    func stopEngine() {
        engineRunning = false
        save()
    }

    func cancelFlight() {
        isFlying = false
        engineRunning = false
        endCurrentLeg()
        save()
    }
    
    func endTrip() {
        // Finalize current leg if active
        if currentLeg != nil {
            endCurrentLeg()
        }
        
        // Mark trip as ended
        if var trip = currentTrip {
            trip.endDate = Date()
            
            // Archive trip to completed trips
            archiveTrip(trip)
        }
        
        // Clear current trip and flight state
        currentTrip = nil
        isFlying = false
        engineRunning = false
        preset = .topoff
        customFuel = [:]
        currentTank = "lMain"
        swapLog = []
        tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        phase = .mains
        fuelExhausted = false
        flightMode = nil
        swap2Targets = nil
        
        save()
    }
    
    func archiveTrip(_ trip: Trip) {
        // Load existing archived trips
        var archivedTrips: [Trip] = []
        if let data = UserDefaults.standard.data(forKey: "archivedTrips"),
           let trips = try? JSONDecoder().decode([Trip].self, from: data) {
            archivedTrips = trips
        }
        
        // Add new trip
        archivedTrips.append(trip)
        
        // Keep only last 50 trips
        if archivedTrips.count > 50 {
            archivedTrips = Array(archivedTrips.suffix(50))
        }
        
        // Save back
        if let encoded = try? JSONEncoder().encode(archivedTrips) {
            UserDefaults.standard.set(encoded, forKey: "archivedTrips")
        }
    }
    
    func clearFlight() {
        isFlying = false
        engineRunning = false
        preset = .topoff
        customFuel = [:]
        currentTank = "lMain"
        swapLog = []
        tankBurned = ["lTip": 0, "lMain": 0, "rMain": 0, "rTip": 0]
        phase = .mains
        fuelExhausted = false
        flightMode = nil
        swap2Targets = nil
        currentTrip = nil
        currentLeg = nil
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
        
        // Save trip data separately
        if let trip = currentTrip, let encoded = try? JSONEncoder().encode(trip) {
            UserDefaults.standard.set(encoded, forKey: tripStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: tripStorageKey)
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
        
        // Load trip data
        if let tripData = UserDefaults.standard.data(forKey: tripStorageKey),
           let trip = try? JSONDecoder().decode(Trip.self, from: tripData) {
            currentTrip = trip
        }
    }
    
    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: tripStorageKey)
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

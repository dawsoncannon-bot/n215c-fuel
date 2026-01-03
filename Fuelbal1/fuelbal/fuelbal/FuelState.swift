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
    var postFuelLevels: [String: Double]?  // NEW: Actual levels after fueling (inferred from preset or custom entry)
    var miscCost: Double?  // NEW: Costs incurred without fuel (fees, parking, etc.)
    
    init(id: UUID = UUID(), timestamp: Date = Date(), fuelAdded: [String: Double], pricePerGallon: Double? = nil, totalCost: Double? = nil, location: String? = nil, notes: String? = nil, postFuelLevels: [String: Double]? = nil, miscCost: Double? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.fuelAdded = fuelAdded
        self.pricePerGallon = pricePerGallon
        self.totalCost = totalCost
        self.location = location
        self.notes = notes
        self.postFuelLevels = postFuelLevels
        self.miscCost = miscCost
    }
    
    var totalAdded: Double {
        fuelAdded.values.reduce(0, +)
    }
    
    /// Returns true if no fuel was added (rest stop / cost-only stop)
    var isRestStop: Bool {
        totalAdded == 0
    }
    
    /// Display name for the stop type
    var stopType: String {
        isRestStop ? "REST STOP - NO FUEL ADDED" : "FUEL STOP"
    }
    
    /// Total costs for this stop (fuel + miscellaneous)
    var totalStopCost: Double {
        let fuelCost = totalCost ?? 0
        let misc = miscCost ?? 0
        return fuelCost + misc
    }
    
    // NEW: Infer pre-fuel levels from post-fuel levels
    // Example: If topped off to 84 gal and added 45.2 gal, you had 38.8 gal
    var inferredPreFuelLevels: [String: Double]? {
        guard let postLevels = postFuelLevels else { return nil }
        
        var preLevels: [String: Double] = [:]
        for (tank, postLevel) in postLevels {
            let added = fuelAdded[tank] ?? 0
            preLevels[tank] = max(0, postLevel - added)
        }
        
        return preLevels
    }
    
    // NEW: Total fuel before this stop (inferred)
    var inferredPreFuelTotal: Double? {
        inferredPreFuelLevels?.values.reduce(0, +)
    }
    
    // NEW: Calculate variance between tracked and actual fuel
    func calculateVariance(trackedPreFuel: [String: Double]) -> [String: Double]? {
        guard let actualPreFuel = inferredPreFuelLevels else { return nil }
        
        var variance: [String: Double] = [:]
        for (tank, trackedLevel) in trackedPreFuel {
            let actualLevel = actualPreFuel[tank] ?? 0
            variance[tank] = trackedLevel - actualLevel  // Positive = tracking optimistic
        }
        
        return variance
    }
    
    // NEW: Total variance across all tanks
    func totalVariance(trackedPreFuel: [String: Double]) -> Double? {
        calculateVariance(trackedPreFuel: trackedPreFuel)?.values.reduce(0, +)
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
    var engineStartTime: Date?
    var engineStopTime: Date?
    var totalEngineTime: TimeInterval?
    
    init(id: UUID = UUID(), legNumber: Int, startTime: Date = Date(), endTime: Date? = nil, startingFuel: [String: Double], swapLog: [SwapEntry] = [], currentTank: String = "lMain", phase: Phase = .mains, flightMode: FlightMode? = nil, preset: Preset, fuelExhausted: Bool = false, swap2Targets: (balanced: Double, endurance: Double)? = nil, engineStartTime: Date? = nil, engineStopTime: Date? = nil, totalEngineTime: TimeInterval? = nil) {
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
        self.engineStartTime = engineStartTime
        self.engineStopTime = engineStopTime
        self.totalEngineTime = totalEngineTime
    }
    
    var totalBurned: Double {
        swapLog.reduce(0) { $0 + $1.burned }
    }
    
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }
    
    // Format engine time as HH:MM:SS
    var formattedEngineTime: String {
        guard let time = totalEngineTime else { return "--:--:--" }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Codable conformance for tuple
    enum CodingKeys: String, CodingKey {
        case id, legNumber, startTime, endTime, startingFuel, swapLog, currentTank, phase, flightMode, preset, fuelExhausted
        case swap2TargetsBalanced, swap2TargetsEndurance
        case engineStartTime, engineStopTime, totalEngineTime
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
        
        engineStartTime = try container.decodeIfPresent(Date.self, forKey: .engineStartTime)
        engineStopTime = try container.decodeIfPresent(Date.self, forKey: .engineStopTime)
        totalEngineTime = try container.decodeIfPresent(TimeInterval.self, forKey: .totalEngineTime)
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
        
        try container.encodeIfPresent(engineStartTime, forKey: .engineStartTime)
        try container.encodeIfPresent(engineStopTime, forKey: .engineStopTime)
        try container.encodeIfPresent(totalEngineTime, forKey: .totalEngineTime)
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
    
    var totalFuelAdded: Double {
        fuelStops.reduce(0) { $0 + $1.totalAdded }
    }
    
    // Average fuel price across all fuel stops (weighted by quantity)
    var averageFuelPrice: Double? {
        let stopsWithPrices = fuelStops.compactMap { stop -> (price: Double, qty: Double)? in
            guard let price = stop.pricePerGallon else { return nil }
            return (price, stop.totalAdded)
        }
        
        guard !stopsWithPrices.isEmpty else { return nil }
        
        let totalCost = stopsWithPrices.reduce(0) { $0 + ($1.price * $1.qty) }
        let totalQty = stopsWithPrices.reduce(0) { $0 + $1.qty }
        
        return totalQty > 0 ? totalCost / totalQty : nil
    }
    
    // Total money spent on fuel purchases (includes unburned fuel)
    var totalMoneySpent: Double {
        fuelStops.compactMap { $0.totalCost }.reduce(0, +)
    }
    
    // Estimated cost of fuel burned (using average price)
    var estimatedFuelBurnedCost: Double? {
        guard let avgPrice = averageFuelPrice else { return nil }
        return totalFuelConsumed * avgPrice
    }
    
    var totalFuelCost: Double {
        fuelStops.compactMap { $0.totalCost }.reduce(0, +)
    }
    
    var totalDuration: TimeInterval {
        legs.compactMap { $0.duration }.reduce(0, +)
    }
    
    // MARK: - Fuel Reconciliation
    
    /// Generates a reconciliation between tracked fuel and inferred actual fuel from receipts
    /// This works when fuel stops include cost data, allowing us to reverse-engineer pre-fuel levels
    func fuelReconciliation() -> [LegReconciliation] {
        var reconciliations: [LegReconciliation] = []
        
        // Match legs with their corresponding fuel stops
        for (index, leg) in legs.enumerated() {
            // Find the fuel stop that occurred after this leg (if any)
            let nextStopIndex = index  // Fuel stops align with leg endings
            guard nextStopIndex < fuelStops.count else { continue }
            
            let fuelStop = fuelStops[nextStopIndex]
            
            // Calculate tracked ending fuel for this leg
            var trackedEndingFuel: [String: Double] = [:]
            for (tank, startingAmount) in leg.startingFuel {
                let burned = leg.swapLog
                    .filter { $0.tank.contains(tank.uppercased()) || $0.tank.hasPrefix(tank.prefix(1).uppercased()) }
                    .reduce(0) { $0 + $1.burned }
                trackedEndingFuel[tank] = max(0, startingAmount - burned)
            }
            
            let trackedTotal = trackedEndingFuel.values.reduce(0, +)
            let actualTotal = fuelStop.inferredPreFuelTotal
            let variance = actualTotal.map { trackedTotal - $0 }
            
            reconciliations.append(LegReconciliation(
                legNumber: leg.legNumber,
                trackedEndingFuel: trackedEndingFuel,
                inferredActualFuel: fuelStop.inferredPreFuelLevels,
                variance: variance,
                fuelStop: fuelStop
            ))
        }
        
        return reconciliations
    }
    
    /// Check if trip has enough data for meaningful reconciliation
    var canReconcile: Bool {
        !fuelStops.isEmpty && fuelStops.contains { $0.postFuelLevels != nil }
    }
}

// MARK: - Leg Reconciliation

struct LegReconciliation {
    let legNumber: Int
    let trackedEndingFuel: [String: Double]
    let inferredActualFuel: [String: Double]?
    let variance: Double?  // Positive = tracking was optimistic (thought we had more than we did)
    let fuelStop: FuelStop
    
    var trackedTotal: Double {
        trackedEndingFuel.values.reduce(0, +)
    }
    
    var actualTotal: Double? {
        inferredActualFuel?.values.reduce(0, +)
    }
    
    var hasVariance: Bool {
        guard let variance = variance else { return false }
        return abs(variance) > 0.5  // More than 0.5 gallon difference
    }
    
    var varianceDescription: String {
        guard let variance = variance else { return "Unknown" }
        
        if abs(variance) < 0.5 {
            return "Within tolerance (±0.5 gal)"
        } else if variance > 0 {
            return String(format: "Tracking optimistic by %.1f gal", variance)
        } else {
            return String(format: "Tracking conservative by %.1f gal", abs(variance))
        }
    }
}

enum Preset: String, Codable {
    case topoff = "TOP OFF"
    case tabs = "TAB FILL"
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
    let legTime: TimeInterval?  // Time elapsed since engine start (in seconds)
    
    init(swapNumber: Int, tank: String, totalizer: Double, burned: Double, legTime: TimeInterval? = nil) {
        self.id = UUID()
        self.swapNumber = swapNumber
        self.tank = tank
        self.totalizer = totalizer
        self.burned = burned
        self.legTime = legTime
    }
    
    // Format leg time as HH:MM:SS
    var formattedLegTime: String {
        guard let time = legTime else { return "--:--:--" }
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Observed GPH Entry

struct ObservedGPHEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let legTime: TimeInterval  // Time elapsed when observation was made
    let observedGPH: Double  // GPH value observed on aircraft instrument
    
    init(id: UUID = UUID(), timestamp: Date = Date(), legTime: TimeInterval, observedGPH: Double) {
        self.id = id
        self.timestamp = timestamp
        self.legTime = legTime
        self.observedGPH = observedGPH
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
    @Published var currentAircraft: Aircraft?
    
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
    
    // Leg timer tracking
    @Published var legTimerStart: Date?
    @Published var currentLegTime: TimeInterval = 0
    
    // NEW: Observed GPH tracking
    @Published var observedGPHLog: [ObservedGPHEntry] = []
    @Published var predictedTimeToSwap: TimeInterval = 0  // Countdown timer in seconds
    
    private let storageKey = "n215c_fuel_state"
    private let tripStorageKey = "n215c_current_trip"
    private let aircraftStorageKey = "n215c_current_aircraft"
    
    init() {
        load()
    }
    
    // MARK: - Computed Properties
    
    var tankOrder: [String] {
        // Use current aircraft's tanks if available, otherwise default to N215C
        if let aircraft = currentAircraft {
            return aircraft.tanks.map { $0.position.key }
        }
        return ["lTip", "lMain", "rMain", "rTip"]
    }
    
    var legNumber: Int {
        if let trip = currentTrip {
            return trip.legs.count + (currentLeg != nil ? 1 : 0)
        }
        return 1
    }
    
    // Format current leg time as HH:MM:SS
    var formattedLegTime: String {
        let hours = Int(currentLegTime) / 3600
        let minutes = (Int(currentLegTime) % 3600) / 60
        let seconds = Int(currentLegTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // NEW: Calculate average GPH based on actual fuel burned and elapsed time
    var averageGPH: Double? {
        guard engineRunning || currentLegTime > 0,
              let lastReading = lastReading,
              currentLegTime > 0 else { return nil }
        
        let hoursElapsed = currentLegTime / 3600.0
        return lastReading / hoursElapsed
    }
    
    // NEW: Format average GPH for display
    var formattedAverageGPH: String {
        guard let gph = averageGPH else { return "--" }
        return String(format: "%.1f", gph)
    }
    
    // NEW: Current observed GPH (most recent entry)
    var currentObservedGPH: Double? {
        observedGPHLog.last?.observedGPH
    }
    
    // NEW: Format countdown timer as MM:SS
    var formattedCountdownTime: String {
        guard predictedTimeToSwap > 0 else { return "--:--" }
        
        let minutes = Int(predictedTimeToSwap) / 60
        let seconds = Int(predictedTimeToSwap) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // NEW: Calculate how much fuel will be burned by the time we need to swap
    // This uses the piecewise burn calculation across different GPH observations
    func calculatePredictedBurn() -> Double? {
        guard !observedGPHLog.isEmpty,
              let startTime = legTimerStart else { return nil }
        
        let currentTime = Date().timeIntervalSince(startTime)
        let fuelInTank = remaining(currentTank)
        let availableFuel = fuelInTank - Self.safetyReserve
        
        guard availableFuel > 0 else { return 0 }
        
        // Calculate already burned fuel since last swap
        let lastSwapTime = swapLog.last?.legTime ?? 0
        var accumulatedBurn: Double = 0
        
        // Process each GPH observation segment
        for (index, entry) in observedGPHLog.enumerated() {
            // Only consider observations after last swap
            guard entry.legTime >= lastSwapTime else { continue }
            
            let segmentStart = max(entry.legTime, lastSwapTime)
            let segmentEnd: TimeInterval
            
            if index < observedGPHLog.count - 1 {
                // Use next observation as end point
                segmentEnd = observedGPHLog[index + 1].legTime
            } else {
                // This is the current segment - use current time
                segmentEnd = currentTime
            }
            
            let segmentDuration = segmentEnd - segmentStart
            let segmentBurnRate = entry.observedGPH / 3600.0  // Convert GPH to gallons per second
            accumulatedBurn += segmentBurnRate * segmentDuration
        }
        
        return accumulatedBurn
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
    
    // Determine proper starting tank based on aircraft configuration
    private func determineStartingTank(aircraft: Aircraft) -> String {
        // Priority order for starting tank:
        // 1. Left main (most common)
        // 2. Right main
        // 3. Center
        // 4. First available tank (fallback)
        
        let tankKeys = aircraft.tanks.map { $0.position.key }
        
        // Check for mains first (never start on tips)
        if tankKeys.contains("lMain") {
            return "lMain"
        }
        if tankKeys.contains("rMain") {
            return "rMain"
        }
        if tankKeys.contains("center") {
            return "center"
        }
        
        // Fallback to first tank (shouldn't happen with normal aircraft)
        return tankKeys.first ?? "lMain"
    }
    
    func startFlight(_ selectedPreset: Preset, aircraft: Aircraft, customTanks: [String: Double]? = nil, tabFillLevels: [TankPosition: Double]? = nil) {
        startFlightWithInitialFuel(selectedPreset, aircraft: aircraft, customTanks: customTanks, tabFillLevels: tabFillLevels, pricePerGallon: nil, totalCost: nil, location: nil)
    }
    
    func startFlightWithInitialFuel(_ selectedPreset: Preset, aircraft: Aircraft, customTanks: [String: Double]? = nil, tabFillLevels: [TankPosition: Double]? = nil, pricePerGallon: Double?, totalCost: Double?, location: String?) {
        preset = selectedPreset
        customFuel = customTanks ?? [:]
        currentAircraft = aircraft  // NEW: Store the aircraft
        
        // Initialize tankBurned dynamically based on aircraft tanks
        tankBurned = Dictionary(uniqueKeysWithValues: aircraft.tanks.map { ($0.position.key, 0.0) })
        
        // If tabs preset and tabFillLevels provided, override customFuel
        if selectedPreset == .tabs, let tabLevels = tabFillLevels {
            customFuel = Dictionary(uniqueKeysWithValues: tabLevels.map { ($0.key, $1) })
        }
        
        // Set starting tank - prefer mains over tips
        currentTank = determineStartingTank(aircraft: aircraft)
        swapLog = []
        phase = .mains
        fuelExhausted = false
        flightMode = selectedPreset == .tabs ? .balanced : nil
        swap2Targets = nil
        isFlying = true
        engineRunning = false  // Start suspended
        
        // Create new leg (NO automatic trip creation)
        let startingFuel = selectedPreset == .custom ? (customTanks ?? [:]) : selectedPreset.tanks
        
        // Determine leg number based on total open legs + current trip legs
        let openLegsCount = getOpenLegsCount()
        let tripLegsCount = currentTrip?.legs.count ?? 0
        let legNum = openLegsCount + tripLegsCount + 1
        
        currentLeg = FlightLeg(
            legNumber: legNum,
            startTime: Date(),
            startingFuel: startingFuel,
            preset: selectedPreset
        )
        
        // If cost data provided, create initial FuelStop and save to open fuel stops
        if pricePerGallon != nil || totalCost != nil {
            let fuelStop = FuelStop(
                fuelAdded: startingFuel,
                pricePerGallon: pricePerGallon,
                totalCost: totalCost,
                location: location,
                postFuelLevels: startingFuel  // NEW: Starting fuel IS the post-fuel level
            )
            saveToOpenFuelStops(fuelStop)
        }
        
        save()
    }
    
    func getOpenLegsCount() -> Int {
        guard let data = UserDefaults.standard.data(forKey: "openLegs"),
              let legs = try? JSONDecoder().decode([FlightLeg].self, from: data) else {
            return 0
        }
        return legs.count
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
        
        // Create fuel stop record with post-fuel levels (enables inference)
        let fuelStop = FuelStop(
            fuelAdded: fuelAdded,
            pricePerGallon: pricePerGallon,
            totalCost: totalCost,
            location: location,
            postFuelLevels: newTanks  // NEW: Store actual post-fuel state
        )
        
        // Save fuel stop to open fuel stops (will be associated with trip when legs are packaged)
        saveToOpenFuelStops(fuelStop)
        
        // Start new leg with updated fuel (NO automatic trip creation)
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
        
        // Determine leg number
        let openLegsCount = getOpenLegsCount()
        let tripLegsCount = currentTrip?.legs.count ?? 0
        let legNum = openLegsCount + tripLegsCount + 1
        
        currentLeg = FlightLeg(
            legNumber: legNum,
            startTime: Date(),
            startingFuel: newTanks,
            preset: .custom
        )
        
        save()
    }
    
    func saveToOpenFuelStops(_ fuelStop: FuelStop) {
        // Load existing open fuel stops
        var openFuelStops: [FuelStop] = []
        if let data = UserDefaults.standard.data(forKey: "openFuelStops"),
           let stops = try? JSONDecoder().decode([FuelStop].self, from: data) {
            openFuelStops = stops
        }
        
        // Add new fuel stop
        openFuelStops.append(fuelStop)
        
        // Keep only last 50 stops
        if openFuelStops.count > 50 {
            openFuelStops = Array(openFuelStops.suffix(50))
        }
        
        // Save back
        if let encoded = try? JSONEncoder().encode(openFuelStops) {
            UserDefaults.standard.set(encoded, forKey: "openFuelStops")
        }
    }
    
    func resumeWithoutFuel(miscCost: Double? = nil, notes: String? = nil) {
        // IMPORTANT: When continuing without adding fuel, we ONLY increment leg number
        // All fuel state (burn progress, totalizer, swaps, current tank) is preserved
        
        // If cost data provided, create a rest stop record
        if miscCost != nil || notes != nil {
            let restStop = FuelStop(
                fuelAdded: Dictionary(uniqueKeysWithValues: tankOrder.map { ($0, 0.0) }),
                notes: notes,
                miscCost: miscCost
            )
            saveToOpenFuelStops(restStop)
        }
        
        // Simply increment leg number while preserving all flight state
        let openLegsCount = getOpenLegsCount()
        let tripLegsCount = currentTrip?.legs.count ?? 0
        let newLegNum = openLegsCount + tripLegsCount + 1
        
        // Update or create leg with new number but preserve all existing state
        if var leg = currentLeg {
            leg.legNumber = newLegNum
            leg.startTime = Date()  // New leg start time
            currentLeg = leg
        } else {
            // Shouldn't happen, but create leg with current state if needed
            var startingFuel: [String: Double] = [:]
            for tank in tankOrder {
                startingFuel[tank] = startFuel(tank)
            }
            
            currentLeg = FlightLeg(
                legNumber: newLegNum,
                startTime: Date(),
                startingFuel: startingFuel,
                swapLog: swapLog,
                currentTank: currentTank,
                phase: phase,
                flightMode: flightMode,
                preset: preset,
                fuelExhausted: fuelExhausted,
                swap2Targets: swap2Targets
            )
        }
        
        // Keep engine state and flying state as-is
        // swapLog, tankBurned, currentTank, phase, totalizer - ALL PRESERVED
        
        isFlying = true
        engineRunning = false  // New leg will start when user hits START ENGINE
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
        
        // Add to trip or save as open leg
        if currentTrip != nil {
            // Part of ongoing trip - add to trip
            currentTrip?.legs.append(leg)
        } else {
            // Standalone leg - save to open legs
            saveToOpenLegs(leg)
        }
        
        // Clear current leg
        currentLeg = nil
        
        save()
    }
    
    func saveToOpenLegs(_ leg: FlightLeg) {
        // Load existing open legs
        var openLegs: [FlightLeg] = []
        if let data = UserDefaults.standard.data(forKey: "openLegs"),
           let legs = try? JSONDecoder().decode([FlightLeg].self, from: data) {
            openLegs = legs
        }
        
        // Add new leg
        openLegs.append(leg)
        
        // Keep only last 50 legs
        if openLegs.count > 50 {
            openLegs = Array(openLegs.suffix(50))
        }
        
        // Save back
        if let encoded = try? JSONEncoder().encode(openLegs) {
            UserDefaults.standard.set(encoded, forKey: "openLegs")
        }
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
        
        // Calculate leg time for this swap
        let legTime: TimeInterval? = {
            guard let startTime = legTimerStart else { return nil }
            return Date().timeIntervalSince(startTime)
        }()
        
        let entry = SwapEntry(
            swapNumber: swapLog.count + 1,
            tank: tankLabel(currentTank),
            totalizer: reading,
            burned: burned,
            legTime: legTime
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
        
        // NEW: Clear observed GPH log when swapping tanks (new tank, new predictions)
        observedGPHLog = []
        predictedTimeToSwap = 0
        
        save()
    }
    
    // NEW: Log an observed GPH reading from aircraft instrument
    func logObservedGPH(_ gph: Double) {
        guard let startTime = legTimerStart else { return }
        
        let currentTime = Date().timeIntervalSince(startTime)
        
        let entry = ObservedGPHEntry(
            legTime: currentTime,
            observedGPH: gph
        )
        
        observedGPHLog.append(entry)
        
        // Update countdown timer prediction
        updateCountdownTimer()
        
        save()
    }
    
    // NEW: Update the countdown timer based on current observed GPH
    func updateCountdownTimer() {
        guard let latestGPH = currentObservedGPH,
              let startTime = legTimerStart else {
            predictedTimeToSwap = 0
            return
        }
        
        let currentTime = Date().timeIntervalSince(startTime)
        let fuelInTank = remaining(currentTank)
        let availableFuel = fuelInTank - Self.safetyReserve
        
        guard availableFuel > 0, latestGPH > 0 else {
            predictedTimeToSwap = 0
            return
        }
        
        // Calculate fuel already burned since last swap using piecewise GPH
        let alreadyBurned = calculatePredictedBurn() ?? 0
        
        // Calculate remaining fuel to burn
        let remainingToBurn = availableFuel - alreadyBurned
        
        guard remainingToBurn > 0 else {
            predictedTimeToSwap = 0
            return
        }
        
        // Calculate time to burn remaining fuel at current GPH
        let hoursRemaining = remainingToBurn / latestGPH
        let secondsRemaining = hoursRemaining * 3600
        
        predictedTimeToSwap = secondsRemaining
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
            
            // Stop timer on shutdown
            if let startTime = legTimerStart {
                let totalTime = Date().timeIntervalSince(startTime)
                currentLegTime = totalTime
                
                if var leg = currentLeg {
                    leg.engineStopTime = Date()
                    leg.totalEngineTime = totalTime
                    currentLeg = leg
                }
                
                legTimerStart = nil
            }
            
            endCurrentLeg()
            save()
            return
        }
        
        // Calculate fuel burned since last swap
        let burned = swapLog.isEmpty ? reading : reading - (lastReading ?? 0)
        
        // Update current tank
        tankBurned[currentTank, default: 0] += burned
        
        // Calculate final leg time
        let finalLegTime: TimeInterval? = {
            guard let startTime = legTimerStart else { return nil }
            return Date().timeIntervalSince(startTime)
        }()
        
        // Log shutdown as special entry (for reference)
        let shutdownEntry = SwapEntry(
            swapNumber: swapLog.count + 1,
            tank: tankLabel(currentTank) + " (SHUTDOWN)",
            totalizer: reading,
            burned: burned,
            legTime: finalLegTime
        )
        swapLog.append(shutdownEntry)
        
        engineRunning = false
        
        // Stop timer and save total engine time
        if let startTime = legTimerStart {
            let totalTime = Date().timeIntervalSince(startTime)
            currentLegTime = totalTime
            
            if var leg = currentLeg {
                leg.engineStopTime = Date()
                leg.totalEngineTime = totalTime
                currentLeg = leg
            }
            
            legTimerStart = nil
        }
        
        endCurrentLeg()
        save()
    }
    
    func startEngine() {
        engineRunning = true
        
        // Start leg timer
        if legTimerStart == nil {
            legTimerStart = Date()
            currentLegTime = 0
            
            // Update current leg with engine start time
            if var leg = currentLeg {
                leg.engineStartTime = legTimerStart
                currentLeg = leg
            }
        }
        
        save()
    }
    
    func stopEngine() {
        engineRunning = false
        
        // Stop leg timer and calculate total engine time
        if let startTime = legTimerStart {
            let totalTime = Date().timeIntervalSince(startTime)
            currentLegTime = totalTime
            
            // Update current leg with engine stop time and total time
            if var leg = currentLeg {
                leg.engineStopTime = Date()
                leg.totalEngineTime = totalTime
                currentLeg = leg
            }
            
            // Clear timer start (will be reset on next engine start)
            legTimerStart = nil
        }
        
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
        currentAircraft = nil
        legTimerStart = nil
        currentLegTime = 0
        observedGPHLog = []  // NEW: Clear observed GPH
        predictedTimeToSwap = 0  // NEW: Clear countdown
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
        
        // Save current aircraft
        if let aircraft = currentAircraft, let encoded = try? JSONEncoder().encode(aircraft) {
            UserDefaults.standard.set(encoded, forKey: aircraftStorageKey)
        } else {
            UserDefaults.standard.removeObject(forKey: aircraftStorageKey)
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
        
        // Load current aircraft
        if let aircraftData = UserDefaults.standard.data(forKey: aircraftStorageKey),
           let aircraft = try? JSONDecoder().decode(Aircraft.self, from: aircraftData) {
            currentAircraft = aircraft
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

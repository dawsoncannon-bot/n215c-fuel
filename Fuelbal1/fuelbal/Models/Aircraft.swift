import Foundation

// MARK: - Aircraft Model
struct Aircraft: Codable, Identifiable {
    let id: UUID
    var tailNumber: String
    var manufacturer: String
    var model: String
    var icao: String  // max 6 characters
    var fuelType: FuelType
    var tanks: [FuelTank]
    var isPreset: Bool  // true for built-in presets like N215C
    var tabFillLevels: [TankPosition: Double]?  // Optional: fuel to "tabs" per tank
    
    init(id: UUID = UUID(), tailNumber: String, manufacturer: String, model: String, icao: String, fuelType: FuelType, tanks: [FuelTank], isPreset: Bool = false, tabFillLevels: [TankPosition: Double]? = nil) {
        self.id = id
        self.tailNumber = tailNumber
        self.manufacturer = manufacturer
        self.model = model
        self.icao = icao
        self.fuelType = fuelType
        self.tanks = tanks
        self.isPreset = isPreset
        self.tabFillLevels = tabFillLevels
    }
    
    var totalCapacity: Double {
        tanks.reduce(0) { $0 + $1.capacity }
    }
    
    var totalTabFill: Double? {
        guard let tabs = tabFillLevels else { return nil }
        return tabs.values.reduce(0, +)
    }
    
    var hasTabFill: Bool {
        tabFillLevels != nil
    }
}

// MARK: - Fuel Tank
struct FuelTank: Codable, Identifiable {
    let id: UUID
    var position: TankPosition
    var capacity: Double  // usable gallons only
    
    init(id: UUID = UUID(), position: TankPosition, capacity: Double) {
        self.id = id
        self.position = position
        self.capacity = capacity
    }
}

// MARK: - Tank Position
enum TankPosition: String, Codable, CaseIterable {
    case lTip = "L TIP"
    case lMain = "L MAIN"
    case center = "CENTER"
    case rMain = "R MAIN"
    case rTip = "R TIP"
    case aft = "AFT"
    
    var key: String {
        switch self {
        case .lTip: return "lTip"
        case .lMain: return "lMain"
        case .center: return "center"
        case .rMain: return "rMain"
        case .rTip: return "rTip"
        case .aft: return "aft"
        }
    }
}

// MARK: - Fuel Type
enum FuelType: String, Codable, CaseIterable {
    case avgas = "AVGAS 100LL"
    case jetA = "JET-A"
    
    var weightPerGallon: Double {
        switch self {
        case .avgas: return 6.0
        case .jetA: return 6.8
        }
    }
}

// MARK: - Preset Aircraft (User's actual aircraft)
extension Aircraft {
    static let n215c = Aircraft(
        tailNumber: "N215C",
        manufacturer: "Piper",
        model: "Cherokee 6",
        icao: "PA32",
        fuelType: .avgas,
        tanks: [
            FuelTank(position: .lTip, capacity: 17),
            FuelTank(position: .lMain, capacity: 25),
            FuelTank(position: .rMain, capacity: 25),
            FuelTank(position: .rTip, capacity: 17)
        ],
        isPreset: true,
        tabFillLevels: [
            .lTip: 17,   // Tips always full (no tabs)
            .lMain: 18,  // Mains to tabs
            .rMain: 18,  // Mains to tabs
            .rTip: 17    // Tips always full (no tabs)
        ]
    )
}

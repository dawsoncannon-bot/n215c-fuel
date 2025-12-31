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
    
    init(id: UUID = UUID(), tailNumber: String, manufacturer: String, model: String, icao: String, fuelType: FuelType, tanks: [FuelTank], isPreset: Bool = false) {
        self.id = id
        self.tailNumber = tailNumber
        self.manufacturer = manufacturer
        self.model = model
        self.icao = icao
        self.fuelType = fuelType
        self.tanks = tanks
        self.isPreset = isPreset
    }
    
    var totalCapacity: Double {
        tanks.reduce(0) { $0 + $1.capacity }
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
    case rMain = "R MAIN"
    case rTip = "R TIP"
    
    var key: String {
        switch self {
        case .lTip: return "lTip"
        case .lMain: return "lMain"
        case .rMain: return "rMain"
        case .rTip: return "rTip"
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

// MARK: - Preset Aircraft
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
        isPreset: true
    )
}

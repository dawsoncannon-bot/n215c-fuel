//  FuelCostTrackingMode.swift
//  fuelbal
//
//  Mode selection for fuel cost tracking

import Foundation

enum FuelCostTrackingMode: String, Codable {
    case simple = "Simple"
    case money = "Money"
    
    var description: String {
        switch self {
        case .simple:
            return "Track fuel only"
        case .money:
            return "Track fuel + costs"
        }
    }
}

// User preference storage
extension UserDefaults {
    private static let fuelCostModeKey = "fuelCostTrackingMode"
    
    var fuelCostTrackingMode: FuelCostTrackingMode {
        get {
            guard let rawValue = string(forKey: Self.fuelCostModeKey),
                  let mode = FuelCostTrackingMode(rawValue: rawValue) else {
                return .simple // Default
            }
            return mode
        }
        set {
            set(newValue.rawValue, forKey: Self.fuelCostModeKey)
        }
    }
}

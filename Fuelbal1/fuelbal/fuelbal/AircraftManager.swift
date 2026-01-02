import Foundation
import SwiftUI
import Combine

/// Manages custom aircraft persistence and retrieval
class AircraftManager: ObservableObject {
    static let shared = AircraftManager()
    
    @Published private(set) var customAircraft: [Aircraft] = []
    
    private let storageKey = "customAircraft"
    
    private init() {
        loadCustomAircraft()
    }
    
    // MARK: - All Aircraft (Presets + Custom)
    
    var allAircraft: [Aircraft] {
        var aircraft = [Aircraft.n215c] // Start with presets
        aircraft.append(contentsOf: customAircraft)
        return aircraft
    }
    
    // MARK: - Save Custom Aircraft
    
    func saveAircraft(_ aircraft: Aircraft) {
        // Check if aircraft with same tail number already exists
        if let index = customAircraft.firstIndex(where: { $0.tailNumber == aircraft.tailNumber }) {
            // Update existing aircraft
            customAircraft[index] = aircraft
        } else {
            // Add new aircraft
            customAircraft.append(aircraft)
        }
        
        persistCustomAircraft()
    }
    
    // MARK: - Delete Custom Aircraft
    
    func deleteAircraft(_ aircraft: Aircraft) {
        customAircraft.removeAll { $0.id == aircraft.id }
        persistCustomAircraft()
    }
    
    func deleteAircraft(at offsets: IndexSet) {
        customAircraft.remove(atOffsets: offsets)
        persistCustomAircraft()
    }
    
    // MARK: - Get Aircraft
    
    func getAircraft(byId id: UUID) -> Aircraft? {
        return allAircraft.first { $0.id == id }
    }
    
    func getAircraft(byTailNumber tailNumber: String) -> Aircraft? {
        return allAircraft.first { $0.tailNumber.uppercased() == tailNumber.uppercased() }
    }
    
    // MARK: - Persistence
    
    private func persistCustomAircraft() {
        if let encoded = try? JSONEncoder().encode(customAircraft) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadCustomAircraft() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let aircraft = try? JSONDecoder().decode([Aircraft].self, from: data) else {
            customAircraft = []
            return
        }
        customAircraft = aircraft
    }
    
    // MARK: - Clear All Custom Aircraft (for testing/reset)
    
    func clearAllCustomAircraft() {
        customAircraft = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

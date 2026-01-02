import Foundation

// MARK: - Aircraft Template
// Templates are NOT aircraft - they're configuration references
// Users can browse these when creating a new aircraft to quickly fill in fuel configs

struct AircraftTemplate: Identifiable {
    let id = UUID()
    let manufacturer: String
    let model: String
    let variant: String  // e.g., "Standard", "With Tip Tanks", "84 Gal", "105 Gal"
    let icao: String
    let fuelType: FuelType
    let tankConfig: [TankPosition: Double]  // Position -> Usable Gallons
    let tabFillLevels: [TankPosition: Double]?  // Optional: fuel to "tabs" per tank
    let notes: String?
    
    var displayName: String {
        if variant.isEmpty {
            return "\(manufacturer) \(model)"
        }
        return "\(manufacturer) \(model) (\(variant))"
    }
    
    var totalCapacity: Double {
        tankConfig.values.reduce(0, +)
    }
    
    var totalTabFill: Double? {
        guard let tabs = tabFillLevels else { return nil }
        return tabs.values.reduce(0, +)
    }
}

// MARK: - Template Categories

enum TemplateCategory: String, CaseIterable, Identifiable {
    case cessna = "Cessna"
    case piper = "Piper"
    case beechcraft = "Beechcraft"
    case cirrus = "Cirrus"
    case mooney = "Mooney"
    case other = "Other"
    
    var id: String { rawValue }
}

// MARK: - Template Library

struct AircraftTemplateLibrary {
    
    static func templates(for category: TemplateCategory) -> [AircraftTemplate] {
        switch category {
        case .cessna:
            return cessnaTemplates
        case .piper:
            return piperTemplates
        case .beechcraft:
            return beechcraftTemplates
        case .cirrus:
            return cirrusTemplates
        case .mooney:
            return mooneyTemplates
        case .other:
            return otherTemplates
        }
    }
    
    // MARK: - Cessna Templates
    
    private static let cessnaTemplates: [AircraftTemplate] = [
        // C172 (late models, e.g., S)
        AircraftTemplate(
            manufacturer: "Cessna",
            model: "172 Skyhawk",
            variant: "Late Models (S)",
            icao: "C172",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 26.5,
                .rMain: 26.5
            ],
            tabFillLevels: nil,
            notes: "BOTH normally used; not true crossfeed. Earlier models differ - verify POH."
        ),
        
        // C182 (common later models)
        AircraftTemplate(
            manufacturer: "Cessna",
            model: "182 Skylane",
            variant: "Later Models",
            icao: "C182",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 44.0,
                .rMain: 44.0
            ],
            tabFillLevels: nil,
            notes: "BOTH available; some POHs specify BOTH for normal ops. Verify year."
        ),
        
        // C210 (various models)
        AircraftTemplate(
            manufacturer: "Cessna",
            model: "210 Centurion",
            variant: "",
            icao: "C210",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 45.0,
                .rMain: 44.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH; L/R/OFF only. Some versions use aux tanks that transfer (often to right)."
        ),
    ]
    
    // MARK: - Piper Templates
    
    private static let piperTemplates: [AircraftTemplate] = [
        // PA-28-140 Cherokee
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-28-140 Cherokee",
            variant: "",
            icao: "PA28",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 18.0,
                .rMain: 18.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Small unusable fuel varies by year - verify POH."
        ),
        
        // PA-28-180 Cherokee
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-28-180 Cherokee",
            variant: "",
            icao: "PA28",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 24.0,
                .rMain: 24.0
            ],
            tabFillLevels: [
                .lMain: 18.0,
                .rMain: 18.0
            ],
            notes: "No BOTH selector; L/R/OFF only. Tabs = 18 gal/side (36 total). Verify early vs later POHs for exact usable."
        ),
        
        // PA-28-181 Archer
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-28-181 Archer",
            variant: "",
            icao: "PA28",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 24.0,
                .rMain: 24.0
            ],
            tabFillLevels: [
                .lMain: 18.0,
                .rMain: 18.0
            ],
            notes: "No BOTH selector; L/R/OFF only. Tabs = 18 gal/side (36 total). Very consistent across fleet."
        ),
        
        // PA-28R-180 Arrow I (Hershey bar)
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-28R-180 Arrow I",
            variant: "Hershey Bar Wing",
            icao: "PA28",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 24.0,
                .rMain: 24.0
            ],
            tabFillLevels: [
                .lMain: 18.0,
                .rMain: 18.0
            ],
            notes: "No BOTH selector; L/R/OFF only. Tabs = 18 gal/side (36 total). Same fuel logic as other PA-28s."
        ),
        
        // PA-28R-200 Arrow II (Hershey bar, early)
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-28R-200 Arrow II",
            variant: "Hershey Bar Wing",
            icao: "PA28",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 24.0,
                .rMain: 24.0
            ],
            tabFillLevels: [
                .lMain: 18.0,
                .rMain: 18.0
            ],
            notes: "No BOTH selector; L/R/OFF only. Tabs = 18 gal/side (36 total). Wing planform does not change fuel logic."
        ),
        
        // PA-32-260 Cherokee Six - 84 gallon configuration (4 tanks)
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-32-260 Cherokee Six",
            variant: "84 Gal (4 Tanks)",
            icao: "PA32",
            fuelType: .avgas,
            tankConfig: [
                .lTip: 17.0,
                .lMain: 25.0,
                .rMain: 25.0,
                .rTip: 17.0
            ],
            tabFillLevels: [
                .lTip: 17.0,  // Tips always full (no tabs)
                .lMain: 18.0, // Mains to tabs
                .rMain: 18.0, // Mains to tabs
                .rTip: 17.0   // Tips always full (no tabs)
            ],
            notes: "No BOTH selector; selector chooses individual tank. Tabs = 18 gal/side mains, 17 gal tips (70 total). Slight unusable per tank varies by POH."
        ),
        
        // PA-32 Saratoga (fixed gear, common config)
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-32 Saratoga",
            variant: "Fixed Gear",
            icao: "PA32",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 51.0,
                .rMain: 51.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Some sources quote 107 total with ~5 unusable."
        ),
        
        // PA-32R-300 Lance / Lance II
        AircraftTemplate(
            manufacturer: "Piper",
            model: "PA-32R-300 Lance",
            variant: "Retractable",
            icao: "PA32",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 47.0,
                .rMain: 47.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Retractable gear version of PA-32."
        ),
    ]
    
    // MARK: - Beechcraft Templates
    
    private static let beechcraftTemplates: [AircraftTemplate] = [
        // Bonanza Model 35 (V-Tail) - Standard (no tips)
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "Bonanza 35 (V-Tail)",
            variant: "Standard (No Tips)",
            icao: "BE35",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 20.0,
                .rMain: 20.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH; L/R/OFF only. Wing root tanks. No tip tanks."
        ),
        
        // Bonanza Model 35 (V-Tail) - With 20 gal tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "Bonanza 35 (V-Tail)",
            variant: "With 20 Gal Tips",
            icao: "BE35",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 20.0,
                .rMain: 20.0,
                .lTip: 10.0,
                .rTip: 10.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY - do not feed engine directly. Must transfer to mains. Transfer faster than burn or overboard venting occurs. L/R/OFF selector only."
        ),
        
        // Bonanza Model 35 (V-Tail) - With 40 gal tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "Bonanza 35 (V-Tail)",
            variant: "With 40 Gal Tips",
            icao: "BE35",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 20.0,
                .rMain: 20.0,
                .lTip: 20.0,
                .rTip: 20.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY - do not feed engine directly. Must have room in mains to accept transfer. Tips transfer slower than burn - plan ahead. L/R/OFF only."
        ),
        
        // Bonanza 33 / F33 (Straight-Tail) - Standard (no tips)
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "Bonanza 33 / F33",
            variant: "Standard (No Tips)",
            icao: "BE33",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 25.0,
                .rMain: 25.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH; L/R/OFF only. Straight-tail Debonair. Standard mains only."
        ),
        
        // Bonanza 33 / F33 (Straight-Tail) - With tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "Bonanza 33 / F33",
            variant: "With Tips (70-80 Gal)",
            icao: "BE33",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 25.0,
                .rMain: 25.0,
                .lTip: 10.0,
                .rTip: 10.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY via electrical pumps. Must manage balance manually. Transfer to one side repeatedly = imbalance risk. L/R/OFF only."
        ),
        
        // Bonanza A36 / G36 (Long-Body) - Standard (no tips)
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "A36 / G36 Bonanza",
            variant: "Standard (No Tips)",
            icao: "BE36",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 37.0,
                .rMain: 37.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH; L/R/OFF only. Long-body. Large mains only."
        ),
        
        // Bonanza A36 / G36 (Long-Body) - With 20 gal tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "A36 / G36 Bonanza",
            variant: "With 20 Gal Tips",
            icao: "BE36",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 37.0,
                .rMain: 37.0,
                .lTip: 10.0,
                .rTip: 10.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY. Total ~94 gal usable. Can out-range bladder. Aft CG sensitivity with high fuel loads. Electrical load awareness for transfers. L/R/OFF only."
        ),
        
        // Bonanza A36 / G36 (Long-Body) - With 40 gal tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "A36 / G36 Bonanza",
            variant: "With 40 Gal Tips",
            icao: "BE36",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 37.0,
                .rMain: 37.0,
                .lTip: 20.0,
                .rTip: 20.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY. Total ~114 gal usable. Long transfers at altitude = electrical load concern. Must manage balance manually. Can dump overboard if transfer too long. L/R/OFF only."
        ),
        
        // Bonanza B36TC (Turbo) - Standard
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "B36TC Bonanza (Turbo)",
            variant: "Standard (No Tips)",
            icao: "BE36",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 37.0,
                .rMain: 37.0
            ],
            tabFillLevels: nil,
            notes: "Turbo model. No BOTH; L/R/OFF only. Higher fuel burn - tip transfer timing critical in climb."
        ),
        
        // Bonanza B36TC (Turbo) - With tips
        AircraftTemplate(
            manufacturer: "Beechcraft",
            model: "B36TC Bonanza (Turbo)",
            variant: "With Tips (110+ Gal)",
            icao: "BE36",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 37.0,
                .rMain: 37.0,
                .lTip: 18.0,
                .rTip: 18.0
            ],
            tabFillLevels: nil,
            notes: "⚠️ TIPS TRANSFER ONLY. Turbo = higher burn. Tip transfer timing CRITICAL in climb phase. Long transfers + high electrical load. L/R/OFF only."
        ),
    ]
    
    // MARK: - Cirrus Templates
    
    private static let cirrusTemplates: [AircraftTemplate] = [
        // PLACEHOLDER - awaiting verified usable fuel data
    ]
    
    // MARK: - Mooney Templates
    
    private static let mooneyTemplates: [AircraftTemplate] = [
        // Mooney M20C
        AircraftTemplate(
            manufacturer: "Mooney",
            model: "M20C",
            variant: "",
            icao: "M20C",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 24.0,
                .rMain: 24.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Some docs list 52 total with ~4 unusable."
        ),
        
        // Mooney M20J
        AircraftTemplate(
            manufacturer: "Mooney",
            model: "M20J",
            variant: "",
            icao: "M20J",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 32.0,
                .rMain: 32.0
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Very consistent across J models."
        ),
        
        // Mooney M20R Ovation
        AircraftTemplate(
            manufacturer: "Mooney",
            model: "M20R Ovation",
            variant: "",
            icao: "M20R",
            fuelType: .avgas,
            tankConfig: [
                .lMain: 44.5,
                .rMain: 44.5
            ],
            tabFillLevels: nil,
            notes: "No BOTH selector; L/R/OFF only. Confirm exact usable per POH and mods."
        ),
    ]
    
    // MARK: - Other Templates
    
    private static let otherTemplates: [AircraftTemplate] = [
        // PLACEHOLDER - awaiting verified usable fuel data
    ]
    
    // MARK: - All Templates
    
    static var allTemplates: [AircraftTemplate] {
        TemplateCategory.allCases.flatMap { templates(for: $0) }
    }
    
    static func searchTemplates(query: String) -> [AircraftTemplate] {
        let lowercasedQuery = query.lowercased()
        return allTemplates.filter { template in
            template.manufacturer.lowercased().contains(lowercasedQuery) ||
            template.model.lowercased().contains(lowercasedQuery) ||
            template.variant.lowercased().contains(lowercasedQuery) ||
            template.icao.lowercased().contains(lowercasedQuery)
        }
    }
}

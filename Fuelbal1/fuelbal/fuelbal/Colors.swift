import SwiftUI

extension Color {
    // MARK: - Background Colors
    static let appBackground = Color.black
    static let cardBackground = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let sheetBackground = Color(red: 0.1, green: 0.1, blue: 0.1) // Slightly lighter than pure black
    
    // MARK: - Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color.gray
    static let accentText = Color.cyan
    
    // MARK: - UI Colors
    static let buttonPrimary = Color.cyan
    static let buttonSecondary = Color.white.opacity(0.2)
    static let buttonDisabled = Color.gray.opacity(0.3)
    
    // MARK: - Fuel Status Colors
    static let fuelActive = Color(red: 1.0, green: 0.9, blue: 0.43) // Yellow-gold
    static let fuelNormal = Color.cyan
    static let fuelLow = Color(red: 1.0, green: 0.42, blue: 0.42) // Red
    
    // MARK: - Tank Colors
    static let tankLeft = Color.cyan
    static let tankRight = Color(red: 1.0, green: 0.42, blue: 0.42) // Red
}

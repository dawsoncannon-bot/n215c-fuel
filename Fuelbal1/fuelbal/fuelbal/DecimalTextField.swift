//
//  DecimalTextField.swift
//  fuelbal
//
//  Reusable decimal-formatted text field with auto-formatting

import SwiftUI

/// A text field that automatically formats decimal numbers
/// - Parameters:
///   - text: Binding to the text value
///   - placeholder: Placeholder text
///   - decimalPlaces: Number of decimal places (0 for integers, 1 for gallons, 2 for currency)
///   - font: Font to use
///   - foregroundColor: Text color
struct DecimalTextField: View {
    @Binding var text: String
    let placeholder: String
    let decimalPlaces: Int
    let font: Font
    let foregroundColor: Color
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newValue in
                // Filter to only allow numbers and decimal point
                let filtered = newValue.filter { "0123456789.".contains($0) }
                
                // For zero decimal places (integers), don't allow decimal point
                if decimalPlaces == 0 {
                    text = filtered.filter { $0 != "." }
                    return
                }
                
                // Ensure only one decimal point
                let components = filtered.components(separatedBy: ".")
                if components.count > 2 {
                    // Multiple decimal points - keep only first
                    text = components[0] + "." + components.dropFirst().joined()
                    return
                }
                
                // Apply decimal place limit
                if components.count == 2 {
                    let decimals = components[1]
                    if decimals.count > decimalPlaces {
                        text = components[0] + "." + decimals.prefix(decimalPlaces)
                        return
                    }
                }
                
                text = filtered
            }
        ))
        .font(font)
        .foregroundColor(foregroundColor)
        .focused($isFocused)
        .onChange(of: isFocused) { oldValue, newValue in
            if !newValue && !text.isEmpty {
                // Lost focus - format with proper decimal places
                if let value = Double(text) {
                    if decimalPlaces == 0 {
                        // Integer formatting
                        text = String(format: "%.0f", value)
                    } else {
                        // Decimal formatting
                        text = String(format: "%.\(decimalPlaces)f", value)
                    }
                }
            }
        }
    }
}

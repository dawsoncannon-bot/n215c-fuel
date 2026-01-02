//  FuelCostEntryView.swift
//  fuelbal
//
//  Modal for entering fuel cost data in Money mode

import SwiftUI

struct FuelCostEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    let fuelQuantity: Double  // Gallons being added
    let onConfirm: (Double?, Double?, String?) -> Void
    
    @State private var pricePerGallon = ""
    @State private var totalCost = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var showValidationWarning = false
    
    private var calculatedSubtotal: Double? {
        guard let price = Double(pricePerGallon) else { return nil }
        return fuelQuantity * price
    }
    
    private var enteredTotal: Double? {
        Double(totalCost)
    }
    
    private var hasPricingMismatch: Bool {
        guard let subtotal = calculatedSubtotal,
              let total = enteredTotal else { return false }
        
        // Total should be >= subtotal (accounts for taxes/fees)
        // Warn if total is more than 50% higher (likely error)
        return total < subtotal * 0.95 || total > subtotal * 1.5
    }
    
    private var isValid: Bool {
        !pricePerGallon.isEmpty && !totalCost.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.accentText)
                            
                            Text("FUEL COST ENTRY")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.primaryText)
                                .tracking(2)
                            
                            Text("Adding \(String(format: "%.1f", fuelQuantity)) gallons")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Price per gallon
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PRICE PER GALLON")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(1)
                            
                            HStack {
                                Text("$")
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                
                                TextField("0.00", text: $pricePerGallon)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                                
                                Text("/ gal")
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                            }
                            .padding(16)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            
                            // Calculated subtotal
                            if let subtotal = calculatedSubtotal {
                                HStack {
                                    Text("Subtotal:")
                                    Spacer()
                                    Text(String(format: "$%.2f", subtotal))
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Total cost (from receipt)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("TOTAL COST (RECEIPT)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                    .tracking(1)
                                
                                Spacer()
                                
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            HStack {
                                Text("$")
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentText)
                                
                                TextField("0.00", text: $totalCost)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentText)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.plain)
                            }
                            .padding(16)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasPricingMismatch ? Color.orange : Color.clear, lineWidth: 2)
                            )
                            
                            // Show difference
                            if let subtotal = calculatedSubtotal, let total = enteredTotal {
                                let difference = total - subtotal
                                HStack {
                                    Text(difference >= 0 ? "Taxes & Fees:" : "Discount:")
                                    Spacer()
                                    Text(String(format: "$%.2f", abs(difference)))
                                        .fontWeight(.bold)
                                }
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(difference >= 0 ? .green : .orange)
                                .padding(.horizontal, 4)
                            }
                            
                            // Validation warning
                            if hasPricingMismatch {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                    Text("Check your numbers - total seems unusual")
                                        .font(.system(size: 11, design: .monospaced))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                            }
                            
                            Text("Include taxes, fees, and any surcharges")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondaryText.opacity(0.7))
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Optional fields
                        VStack(alignment: .leading, spacing: 16) {
                            Text("OPTIONAL")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondaryText)
                                .tracking(1)
                            
                            // Location
                            VStack(alignment: .leading, spacing: 6) {
                                Text("LOCATION (AIRPORT/FBO)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                
                                TextField("KPHX Signature", text: $location)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                    .textInputAutocapitalization(.characters)
                                    .padding(12)
                                    .background(Color.cardBackground)
                                    .cornerRadius(8)
                            }
                            
                            // Notes
                            VStack(alignment: .leading, spacing: 6) {
                                Text("NOTES")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                
                                TextField("Self-serve, card fee...", text: $notes)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                    .padding(12)
                                    .background(Color.cardBackground)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Save button
                        Button(action: saveAndDismiss) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text("SAVE FUEL PURCHASE")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .tracking(1)
                            }
                            .foregroundColor(isValid ? .black : .secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(isValid ? Color.accentText : Color.cardBackground)
                            .cornerRadius(12)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondaryText)
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        let price = Double(pricePerGallon)
        let total = Double(totalCost)
        let loc = location.isEmpty ? nil : location
        
        onConfirm(price, total, loc)
        dismiss()
    }
}

#Preview {
    FuelCostEntryView(fuelQuantity: 45.5) { price, total, location in
        print("Price: \(price ?? 0), Total: \(total ?? 0), Location: \(location ?? "none")")
    }
}

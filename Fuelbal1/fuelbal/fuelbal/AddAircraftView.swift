import SwiftUI

struct AddAircraftView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var aircraftManager = AircraftManager.shared
    
    // Aircraft details
    @State private var tailNumber = ""
    @State private var manufacturer = ""
    @State private var model = ""
    @State private var icao = ""
    @State private var fuelType: FuelType = .avgas
    
    // Tank configuration
    @State private var lTipCapacity = ""
    @State private var lMainCapacity = ""
    @State private var centerCapacity = ""
    @State private var rMainCapacity = ""
    @State private var rTipCapacity = ""
    @State private var aftCapacity = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTemplateBrowser = false
    
    var totalCapacity: Double {
        let lTip = Double(lTipCapacity) ?? 0
        let lMain = Double(lMainCapacity) ?? 0
        let center = Double(centerCapacity) ?? 0
        let rMain = Double(rMainCapacity) ?? 0
        let rTip = Double(rTipCapacity) ?? 0
        let aft = Double(aftCapacity) ?? 0
        return lTip + lMain + center + rMain + rTip + aft
    }
    
    var isValid: Bool {
        !tailNumber.isEmpty &&
        !manufacturer.isEmpty &&
        !model.isEmpty &&
        !icao.isEmpty &&
        icao.count <= 6 &&
        totalCapacity > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "airplane.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.accentText)
                            
                            Text("NEW AIRCRAFT")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.primaryText)
                                .tracking(2)
                            
                            Text("Configure your aircraft profile")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Template browser button
                        Button(action: {
                            showTemplateBrowser = true
                        }) {
                            HStack {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 14))
                                
                                Text("BROWSE FUEL CONFIG TEMPLATES")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .tracking(1)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.accentText)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.accentText.opacity(0.5), lineWidth: 1.5)
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Aircraft Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "AIRCRAFT DETAILS")
                            
                            CustomTextField(
                                label: "TAIL NUMBER",
                                placeholder: "N12345",
                                text: $tailNumber
                            )
                            .textInputAutocapitalization(.characters)
                            
                            CustomTextField(
                                label: "MANUFACTURER",
                                placeholder: "Cessna",
                                text: $manufacturer
                            )
                            
                            CustomTextField(
                                label: "MODEL",
                                placeholder: "172 Skyhawk",
                                text: $model
                            )
                            
                            CustomTextField(
                                label: "ICAO TYPE (MAX 6 CHARS)",
                                placeholder: "C172",
                                text: $icao
                            )
                            .textInputAutocapitalization(.characters)
                            .onChange(of: icao) { oldValue, newValue in
                                if newValue.count > 6 {
                                    icao = String(newValue.prefix(6))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Fuel Type Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "FUEL TYPE")
                            
                            HStack(spacing: 12) {
                                FuelTypeButton(
                                    fuelType: .avgas,
                                    selectedType: $fuelType
                                )
                                
                                FuelTypeButton(
                                    fuelType: .jetA,
                                    selectedType: $fuelType
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Tank Configuration Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "TANK CAPACITY (USABLE GAL)")
                            
                            Text("Enter 0 if tank not present")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondaryText)
                            
                            // Airplane-shaped tank layout
                            VStack(spacing: 8) {
                                // Optional airplane icon for context
                                Image(systemName: "airplane")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondaryText.opacity(0.3))
                                    .padding(.bottom, 4)
                                
                                // Wing tanks - top row (LT, LM, C, RM, RT)
                                HStack(spacing: 6) {
                                    AirplaneTankField(
                                        label: "LT",
                                        capacity: $lTipCapacity
                                    )
                                    
                                    AirplaneTankField(
                                        label: "LM",
                                        capacity: $lMainCapacity
                                    )
                                    
                                    AirplaneTankField(
                                        label: "C",
                                        capacity: $centerCapacity
                                    )
                                    
                                    AirplaneTankField(
                                        label: "RM",
                                        capacity: $rMainCapacity
                                    )
                                    
                                    AirplaneTankField(
                                        label: "RT",
                                        capacity: $rTipCapacity
                                    )
                                }
                                
                                // Aft tank - centered below
                                HStack {
                                    Spacer()
                                    AirplaneTankField(
                                        label: "AFT",
                                        capacity: $aftCapacity
                                    )
                                    .frame(width: 70)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 12)
                            
                            // Total capacity display
                            HStack {
                                Text("TOTAL CAPACITY")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f GAL", totalCapacity))
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.accentText)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: saveAircraft) {
                            Text("CREATE AIRCRAFT")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(isValid ? .black : .secondaryText)
                                .tracking(2)
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
                    .foregroundColor(.accentText)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showTemplateBrowser) {
                TemplateBrowserView { template in
                    applyTemplate(template)
                }
            }
        }
    }
    
    private func applyTemplate(_ template: AircraftTemplate) {
        // Fill in aircraft details
        manufacturer = template.manufacturer
        model = template.model
        icao = template.icao
        fuelType = template.fuelType
        
        // Fill in tank capacities
        lTipCapacity = template.tankConfig[.lTip].map { String(format: "%.1f", $0) } ?? ""
        lMainCapacity = template.tankConfig[.lMain].map { String(format: "%.1f", $0) } ?? ""
        centerCapacity = template.tankConfig[.center].map { String(format: "%.1f", $0) } ?? ""
        rMainCapacity = template.tankConfig[.rMain].map { String(format: "%.1f", $0) } ?? ""
        rTipCapacity = template.tankConfig[.rTip].map { String(format: "%.1f", $0) } ?? ""
        aftCapacity = template.tankConfig[.aft].map { String(format: "%.1f", $0) } ?? ""
    }
    
    private func saveAircraft() {
        // Check if tail number already exists
        if aircraftManager.getAircraft(byTailNumber: tailNumber) != nil {
            errorMessage = "An aircraft with tail number \(tailNumber.uppercased()) already exists."
            showError = true
            return
        }
        
        // Create the aircraft
        var tanks: [FuelTank] = []
        
        if let lTip = Double(lTipCapacity), lTip > 0 {
            tanks.append(FuelTank(position: .lTip, capacity: lTip))
        }
        if let lMain = Double(lMainCapacity), lMain > 0 {
            tanks.append(FuelTank(position: .lMain, capacity: lMain))
        }
        if let center = Double(centerCapacity), center > 0 {
            tanks.append(FuelTank(position: .center, capacity: center))
        }
        if let rMain = Double(rMainCapacity), rMain > 0 {
            tanks.append(FuelTank(position: .rMain, capacity: rMain))
        }
        if let rTip = Double(rTipCapacity), rTip > 0 {
            tanks.append(FuelTank(position: .rTip, capacity: rTip))
        }
        if let aft = Double(aftCapacity), aft > 0 {
            tanks.append(FuelTank(position: .aft, capacity: aft))
        }
        
        let newAircraft = Aircraft(
            tailNumber: tailNumber.uppercased(),
            manufacturer: manufacturer,
            model: model,
            icao: icao.uppercased(),
            fuelType: fuelType,
            tanks: tanks,
            isPreset: false
        )
        
        // Save through AircraftManager
        aircraftManager.saveAircraft(newAircraft)
        
        dismiss()
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.accentText)
            .tracking(1)
    }
}

struct CustomTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(0.5)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.primaryText)
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(8)
        }
    }
}

struct AirplaneTankField: View {
    let label: String
    @Binding var capacity: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .tracking(0.5)
            
            DecimalTextField(
                text: $capacity,
                placeholder: "0",
                decimalPlaces: 1,
                font: .system(size: 14, weight: .bold, design: .monospaced),
                foregroundColor: .primaryText
            )
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentText.opacity(0.3), lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct FuelTypeButton: View {
    let fuelType: FuelType
    @Binding var selectedType: FuelType
    
    var isSelected: Bool {
        fuelType == selectedType
    }
    
    var body: some View {
        Button(action: {
            selectedType = fuelType
        }) {
            VStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .accentText : .secondaryText)
                
                Text(fuelType.rawValue)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .accentText : .secondaryText)
                
                Text("\(String(format: "%.1f", fuelType.weightPerGallon)) LB/GAL")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentText : Color.white.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AddAircraftView()
}

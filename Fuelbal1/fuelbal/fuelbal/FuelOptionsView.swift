import SwiftUI

struct FuelOptionsView: View {
    let aircraft: Aircraft
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 8) {
                    Text(aircraft.tailNumber)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(.primaryText)
                    
                    Text("\(aircraft.manufacturer) \(aircraft.model)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.secondaryText)
                    
                    HStack(spacing: 16) {
                        Label(aircraft.icao, systemImage: "airplane")
                        Label("\(Int(aircraft.totalCapacity)) GAL", systemImage: "drop.fill")
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.accentText)
                }
                .padding(.top, 60)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 40)
                
                Text("NEW FLIGHT")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(3)
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        print("TOP OFF tapped")
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TOP OFF")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                
                                Text("84 GAL")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.accentText)
                                
                                Text("17 / 25 / 25 / 17")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondaryText)
                        }
                        .padding(20)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        print("TABS tapped")
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TABS")
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .foregroundColor(.primaryText)
                                
                                Text("70 GAL")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.accentText)
                                
                                Text("17 / 18 / 18 / 17")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondaryText)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondaryText)
                        }
                        .padding(20)
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Close button
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.secondaryText)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    FuelOptionsView(aircraft: .n215c)
}

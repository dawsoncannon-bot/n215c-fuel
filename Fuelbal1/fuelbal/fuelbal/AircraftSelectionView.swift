import SwiftUI
import Combine

struct AircraftSelectionView: View {
    @State private var selectedAircraft: Aircraft? = nil
    @State private var showOptions = false
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("FUEL TRACKER")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondaryText)
                    .tracking(4)
                
                Text("SELECT AIRCRAFT")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(.primaryText)
                
                // N215C Card
                Button(action: {
                    selectedAircraft = Aircraft.n215c
                    showOptions = true
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("N215C")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                            
                            Text("PRESET")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.accentText)
                                .tracking(1)
                        }
                        
                        Text("Piper Cherokee 6")
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.secondaryText)
                        
                        HStack(spacing: 16) {
                            Label("PA32", systemImage: "airplane")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondaryText)
                            
                            Label("84 GAL", systemImage: "drop.fill")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.accentText)
                        }
                    }
                    .padding(16)
                    .background(Color.cardBackground)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
        }
        .fullScreenCover(isPresented: $showOptions) {
            FuelOptionsView(aircraft: Aircraft.n215c)
        }
    }
}


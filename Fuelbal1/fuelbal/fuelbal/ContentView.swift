import SwiftUI

struct ContentView: View {
    @StateObject private var fuel = FuelState()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // For now, always show Aircraft Selection
            AircraftSelectionView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

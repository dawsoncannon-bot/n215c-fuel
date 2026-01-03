import SwiftUI

struct ContentView: View {
    @StateObject private var fuel = FuelState()
    
    var body: some View {
        Group {
            if fuel.showFlightView {
                FlightView(fuel: fuel)
            } else {
                AircraftSelectionView(fuel: fuel)
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct AircraftTestView: View {
    let aircraft = Aircraft.n215c
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AIRCRAFT DATA TEST")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tail: \(aircraft.tailNumber)")
                Text("Type: \(aircraft.manufacturer) \(aircraft.model)")
                Text("ICAO: \(aircraft.icao)")
                Text("Fuel: \(aircraft.fuelType.rawValue)")
                Text("Weight/Gal: \(aircraft.fuelType.weightPerGallon, specifier: "%.1f") lbs")
                Text("Total Capacity: \(aircraft.totalCapacity, specifier: "%.0f") gal")
            }
            .font(.system(.body, design: .monospaced))
            
            Divider()
            
            Text("TANKS")
                .font(.headline)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(aircraft.tanks) { tank in
                    HStack {
                        Text(tank.position.rawValue)
                            .frame(width: 80, alignment: .leading)
                        Text("\(tank.capacity, specifier: "%.0f") gal")
                    }
                    .font(.system(.body, design: .monospaced))
                }
            }
        }
        .padding()
    }
}

#Preview {
    AircraftTestView()
}

# Implementation Summary - Cost Tracking & Trip Management

## ✅ COMPLETED

### 1. Data Structure Enhancements
**File**: `FuelState.swift`

Added to `Trip` struct:
- `totalFuelAdded`: Total gallons purchased
- `averageFuelPrice`: Weighted average $/gal across all stops
- `totalMoneySpent`: Sum of all receipt totals (includes taxes/fees/unburned fuel)
- `estimatedFuelBurnedCost`: Average price × burned fuel

### 2. Cost Tracking Mode System
**File**: `FuelCostTrackingMode.swift` ✅ CREATED

- Simple mode: Fuel quantities only (default, backward compatible)
- Money mode: Requires price/total for every fuel addition
- Persisted in UserDefaults per user

### 3. Fuel Cost Entry UI
**File**: `FuelCostEntryView.swift` ✅ CREATED

Beautiful modal for Money mode with:
- Price per gallon input
- Total cost (receipt) input
- Calculated subtotal comparison
- Taxes & fees automatic calculation
- Validation warnings for unusual pricing
- Optional location and notes fields

---

## 📋 REMAINING WORK

### Phase 1: Integrate Cost Entry into FuelOptionsView

**What to add**:
1. Mode selector toggle (Simple/Money) at top
2. After user selects TOP OFF/TABS/QUANTITY OVERRIDE:
   - Simple mode: Add fuel immediately (current behavior)
   - Money mode: Show FuelCostEntryView first
3. Pass cost data to `fuel.addFuel()`

**Code changes needed**:
```swift
// At top of FuelOptionsView body
@AppStorage("fuelCostTrackingMode") private var costModeRaw = FuelCostTrackingMode.simple.rawValue

var costMode: FuelCostTrackingMode {
    FuelCostTrackingMode(rawValue: costModeRaw) ?? .simple
}

// Add mode selector before fuel options
if !hasSavedState {
    HStack {
        Text("COST TRACKING")
        Picker("", selection: $costModeRaw) {
            Text("Simple").tag(FuelCostTrackingMode.simple.rawValue)
            Text("Money").tag(FuelCostTrackingMode.money.rawValue)
        }
        .pickerStyle(.segmented)
    }
    .padding(.horizontal, 20)
}

// When adding fuel, check mode
@State private var showCostEntry = false
@State private var pendingFuelAddition: [TankPosition: Double]? = nil

// In button actions:
if costMode == .money {
    pendingFuelAddition = calculatedTanks
    showCostEntry = true
} else {
    // Add immediately (current behavior)
    fuel.addFuel(newTanks: calculatedTanks, ...)
}

.sheet(isPresented: $showCostEntry) {
    if let tanks = pendingFuelAddition {
        let totalQty = tanks.values.reduce(0, +)
        FuelCostEntryView(fuelQuantity: totalQty) { price, total, location in
            fuel.addFuel(
                newTanks: tanks,
                pricePerGallon: price,
                totalCost: total,
                location: location
            )
            dismiss()
        }
    }
}
```

---

### Phase 2: Swipe-to-Delete Implementation

#### TripsListView.swift

**Open Legs Section**:
```swift
ForEach(openLegs.reversed()) { leg in
    OpenLegCard(...)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteOpenLeg(leg.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}

private func deleteOpenLeg(_ id: UUID) {
    openLegs.removeAll { $0.id == id }
    saveOpenLegs()
}
```

**Completed Trips Section**:
```swift
ForEach(archivedTrips.reversed()) { trip in
    TripCard(...)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                tripToDelete = trip
                showDeleteTripAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}

@State private var tripToDelete: Trip? = nil
@State private var showDeleteTripAlert = false

.alert("Delete Trip?", isPresented: $showDeleteTripAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        if let trip = tripToDelete {
            deleteTrip(trip.id)
        }
    }
} message: {
    Text("This will permanently delete the trip and all \(tripToDelete?.legs.count ?? 0) legs.")
}

private func deleteTrip(_ id: UUID) {
    archivedTrips.removeAll { $0.id == id }
    saveArchivedTrips()
}
```

---

### Phase 3: Bulk Delete Features

#### TripsListView.swift - Bulk Delete Legs

**Add to Open Legs Section**:
```swift
HStack {
    Text("OPEN LEGS")
    Spacer()
    
    if !selectedLegs.isEmpty {
        // Add delete button
        Button(action: {
            showBulkDeleteLegsAlert = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                Text("Delete (\(selectedLegs.count))")
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.red)
            .cornerRadius(6)
        }
        
        Button("Create Trip (\(selectedLegs.count))") {
            showCreateTrip = true
        }
        // existing styling...
    }
}

@State private var showBulkDeleteLegsAlert = false

.alert("Delete \(selectedLegs.count) Legs?", isPresented: $showBulkDeleteLegsAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        bulkDeleteLegs()
    }
} message: {
    Text("This cannot be undone.")
}

private func bulkDeleteLegs() {
    openLegs.removeAll { selectedLegs.contains($0.id) }
    selectedLegs.removeAll()
    saveOpenLegs()
}
```

#### Bulk Delete Trips

**Add to Completed Trips Section**:
```swift
HStack {
    Text("COMPLETED TRIPS")
    Spacer()
    
    if !archivedTrips.isEmpty {
        Button(isSelectingTrips ? "Done" : "Select") {
            withAnimation {
                isSelectingTrips.toggle()
                if !isSelectingTrips {
                    selectedTrips.removeAll()
                }
            }
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .foregroundColor(.accentText)
    }
}

@State private var isSelectingTrips = false

// Show bulk actions when selecting
if isSelectingTrips && !selectedTrips.isEmpty {
    Button(action: {
        showBulkDeleteTripsAlert = true
    }) {
        HStack {
            Image(systemName: "trash")
            Text("Delete \(selectedTrips.count) Trips")
        }
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.red)
        .cornerRadius(8)
    }
    .padding(.horizontal, 20)
}

@State private var showBulkDeleteTripsAlert = false

.alert("Delete \(selectedTrips.count) Trips?", isPresented: $showBulkDeleteTripsAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        bulkDeleteTrips()
    }
} message: {
    let totalLegs = archivedTrips.filter { selectedTrips.contains($0.id) }
        .reduce(0) { $0 + $1.legs.count }
    return Text("This will delete \(totalLegs) legs across \(selectedTrips.count) trips. This cannot be undone.")
}

private func bulkDeleteTrips() {
    archivedTrips.removeAll { selectedTrips.contains($0.id) }
    selectedTrips.removeAll()
    isSelectingTrips = false
    saveArchivedTrips()
}
```

---

### Phase 4: Enhanced Financial Displays

#### TripCard.swift (or inline in TripsListView)

**Add financial summary**:
```swift
VStack(alignment: .leading, spacing: 8) {
    // Existing trip info...
    
    // FINANCIAL SUMMARY (if cost data available)
    if trip.totalMoneySpent > 0 {
        Divider()
            .background(Color.white.opacity(0.1))
            .padding(.vertical, 4)
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let avgPrice = trip.averageFuelPrice {
                    HStack {
                        Text("AVG PRICE")
                        Spacer()
                        Text(String(format: "$%.2f/gal", avgPrice))
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondaryText)
                }
                
                if let burnedCost = trip.estimatedFuelBurnedCost {
                    HStack {
                        Text("FUEL BURNED")
                        Spacer()
                        Text(String(format: "$%.2f", burnedCost))
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.fuelActive)
                }
                
                HStack {
                    Text("TOTAL SPENT")
                    Spacer()
                    Text(String(format: "$%.2f", trip.totalMoneySpent))
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.accentText)
            }
        }
    }
}
```

#### TripDetailView.swift

**Add comprehensive financial breakdown**:
```swift
// After existing trip info, add:
if !trip.fuelStops.isEmpty && trip.totalMoneySpent > 0 {
    VStack(alignment: .leading, spacing: 12) {
        Text("FINANCIAL SUMMARY")
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.secondaryText)
            .tracking(2)
        
        // Fuel quantities
        FinancialRow(label: "Fuel Purchased", value: String(format: "%.1f GAL", trip.totalFuelAdded))
        FinancialRow(label: "Fuel Burned", value: String(format: "%.1f GAL", trip.totalFuelConsumed))
        FinancialRow(label: "Fuel Remaining", value: String(format: "%.1f GAL", trip.totalFuelAdded - trip.totalFuelConsumed))
        
        Divider().background(Color.white.opacity(0.2))
        
        // Costs
        if let avgPrice = trip.averageFuelPrice {
            FinancialRow(label: "Average Price", value: String(format: "$%.2f /gal", avgPrice))
        }
        
        if let burnedCost = trip.estimatedFuelBurnedCost {
            FinancialRow(label: "Fuel Burned Cost", value: String(format: "$%.2f", burnedCost), highlighted: false)
        }
        
        FinancialRow(label: "Total Paid", value: String(format: "$%.2f", trip.totalMoneySpent), highlighted: true)
        
        // Fuel stops breakdown
        if trip.fuelStops.count > 1 {
            Text("FUEL STOPS (\(trip.fuelStops.count))")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondaryText)
                .padding(.top, 8)
            
            ForEach(trip.fuelStops) { stop in
                FuelStopSummaryRow(stop: stop)
            }
        }
    }
    .padding(16)
    .background(Color.cardBackground)
    .cornerRadius(12)
    .padding(.horizontal, 16)
}

// Helper view
struct FinancialRow: View {
    let label: String
    let value: String
    var highlighted: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
            Spacer()
            Text(value)
                .font(.system(size: highlighted ? 13 : 11, weight: highlighted ? .bold : .regular, design: .monospaced))
        }
        .foregroundColor(highlighted ? .accentText : .primaryText)
    }
}

struct FuelStopSummaryRow: View {
    let stop: FuelStop
    
    var body: some View {
        HStack {
            if let location = stop.location {
                Text(location)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            } else {
                Text(stop.timestamp, style: .time)
                    .font(.system(size: 10, design: .monospaced))
            }
            
            Text(String(format: "%.1f gal", stop.totalAdded))
                .font(.system(size: 10, design: .monospaced))
            
            Spacer()
            
            if let total = stop.totalCost {
                Text(String(format: "$%.2f", total))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
        }
        .foregroundColor(.secondaryText)
        .padding(8)
        .background(Color.appBackground.opacity(0.5))
        .cornerRadius(6)
    }
}
```

---

## 🎯 Testing Checklist

### Cost Tracking:
- [ ] Toggle between Simple and Money modes
- [ ] Money mode: Cost entry appears after selecting fuel amount
- [ ] Price validation works (warns if unusual)
- [ ] Cost data saves correctly with FuelStop
- [ ] Trip calculations show correct averages

### Trip Management:
- [ ] Swipe-to-delete works on open legs
- [ ] Swipe-to-delete works on completed trips (with confirmation)
- [ ] Bulk selection works for legs
- [ ] Bulk delete for legs shows confirmation
- [ ] Bulk selection works for trips
- [ ] Bulk delete for trips shows scary confirmation with leg count

### Financial Displays:
- [ ] Trip cards show financial summary when data available
- [ ] Trip detail view shows comprehensive breakdown
- [ ] Fuel stops list correctly in detail view
- [ ] Average price calculates correctly (weighted)
- [ ] Burned cost vs. total spent shows difference
- [ ] All dollar amounts format correctly

---

## 🚀 Quick Start Guide

**To implement next**:

1. **Integrate FuelCostEntryView into FuelOptionsView** (20 minutes)
   - Add mode toggle at top
   - Add sheet presentation
   - Wire up confirmation callback

2. **Add swipe-to-delete** (15 minutes)
   - Open legs: single swipe
   - Trips: swipe with confirmation

3. **Add bulk delete UI** (15 minutes)
   - Buttons when items selected
   - Confirmation alerts

4. **Enhanced displays** (30 minutes)
   - Update TripCard
   - Update TripDetailView
   - Create helper components

**Total estimated time**: ~1.5 hours for complete implementation

---

Ready to implement! 🎉

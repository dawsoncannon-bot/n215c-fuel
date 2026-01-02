# Enhanced Cost Tracking & Trip Management Implementation Plan

## 🎯 Overview

Major enhancements to trip/leg management and fuel cost tracking based on real-world operational needs.

---

## ✅ Phase 1: Data Structure Enhancements (COMPLETED)

### Enhanced Trip struct

Added computed properties:
```swift
var totalFuelAdded: Double               // Total fuel purchased
var averageFuelPrice: Double?            // Weighted average $/gal
var totalMoneySpent: Double              // Total $ spent (includes unburned fuel)
var estimatedFuelBurnedCost: Double?     // Cost of burned fuel only
```

### Key Financial Calculations:

**averageFuelPrice**: Weighted by quantity purchased
- Accounts for varying prices at different stops
- Returns nil if no price data available

**totalMoneySpent**: Sum of all FuelStop.totalCost
- Includes taxes, fees, surcharges
- Represents actual receipt totals
- Higher than fuel burned cost (includes unburned fuel)

**estimatedFuelBurnedCost**: Average price × total burned
- Cost of fuel actually consumed
- Lower than totalMoneySpent (excludes unburned fuel)

---

## 📋 Phase 2: UI Enhancements NEEDED

### 2.1 Fuel Cost Tracking Mode Selection

**File**: `FuelCostTrackingMode.swift` ✅ CREATED

**Implementation needed in FuelOptionsView**:

```swift
@AppStorage("fuelCostTrackingMode") private var costMode: String = FuelCostTrackingMode.simple.rawValue

var body: some View {
    // At top of FuelOptionsView, add mode selector
    if !hasSavedState {  // Only show for new flights
        HStack {
            Text("COST TRACKING")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondaryText)
            
            Picker("", selection: $costMode) {
                ForEach([FuelCostTrackingMode.simple, .money], id: \.self) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 20)
    }
}
```

---

### 2.2 Enhanced "Add Fuel" Interface

**Current**: Shows TOP OFF / TABS / QUANTITY OVERRIDE

**New**: Mode-dependent behavior

#### Simple Mode (Default):
- Shows current UI (no changes)
- pricePerGallon: nil
- totalCost: nil

#### Money Mode:
- After selecting TOP OFF / TABS / QUANTITY OVERRIDE
- Show additional fields:
  ```
  Price Per Gallon: $_____
  Total Cost (Receipt): $_____
  Location (Optional): ____
  ```

**Implementation**:
```swift
@State private var showCostEntry = false
@State private var pricePerGallon = ""
@State private var receiptTotal = ""
@State private var fuelLocation = ""

// After user selects fuel amount
if FuelCostTrackingMode(rawValue: costMode) == .money {
    showCostEntry = true
}

// Cost entry sheet
.sheet(isPresented: $showCostEntry) {
    FuelCostEntryView(
        fuelAdded: calculatedAmount,
        onConfirm: { price, total, location in
            // Add fuel with cost data
            fuel.addFuel(
                newTanks: tanks,
                pricePerGallon: price,
                totalCost: total,
                location: location
            )
        }
    )
}
```

---

### 2.3 Swipe-to-Delete for Trips and Legs

**Files to modify**:
- `TripsListView.swift`
- `TripDetailView.swift`

#### TripsListView - Open Legs Section:

```swift
ForEach(openLegs.reversed()) { leg in
    OpenLegCard(leg: leg, ...)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteOpenLeg(leg)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}

private func deleteOpenLeg(_ leg: FlightLeg) {
    // Remove from storage
    if let index = openLegs.firstIndex(where: { $0.id == leg.id }) {
        openLegs.remove(at: index)
        saveOpenLegs()
    }
}
```

#### TripsListView - Completed Trips Section:

```swift
ForEach(archivedTrips.reversed()) { trip in
    TripCard(trip: trip, ...)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirmation = trip
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
}
.alert("Delete Trip?", isPresented: $showDeleteConfirmation != nil) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        if let trip = showDeleteConfirmation {
            deleteTrip(trip)
        }
    }
} message: {
    Text("This will permanently delete the trip and all its legs.")
}
```

---

### 2.4 Bulk Selection & Deletion

**Current**: Selection exists for "Create Trip" from open legs

**Enhancement**: Add bulk delete option

```swift
HStack {
    Text("OPEN LEGS")
    Spacer()
    
    if !selectedLegs.isEmpty {
        Button("Delete (\(selectedLegs.count))") {
            showBulkDeleteConfirmation = true
        }
        .foregroundColor(.red)
        
        Button("Create Trip (\(selectedLegs.count))") {
            showCreateTrip = true
        }
        .foregroundColor(.accentText)
    }
}

.alert("Delete \(selectedLegs.count) legs?", isPresented: $showBulkDeleteConfirmation) {
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

**Same for Trips**:
```swift
// Add selection mode toggle
if !archivedTrips.isEmpty {
    Button(editMode.isEditing ? "Done" : "Select") {
        withAnimation {
            editMode.isEditing.toggle()
        }
    }
}

// Show bulk actions when in edit mode
if editMode.isEditing && !selectedTrips.isEmpty {
    Button("Delete (\(selectedTrips.count))") {
        showBulkDeleteTrips = true
    }
    .foregroundColor(.red)
}
```

---

### 2.5 Enhanced Trip & Leg Details

#### TripCard Enhancements:

**Current display**:
- Trip name
- Date range
- Fuel consumed
- Total cost

**Add**:
```swift
VStack(alignment: .leading, spacing: 8) {
    // Existing info...
    
    // Financial summary
    if let avgPrice = trip.averageFuelPrice {
        HStack {
            Text("AVG FUEL PRICE")
            Spacer()
            Text(String(format: "$%.2f/gal", avgPrice))
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(.secondaryText)
    }
    
    if let burnedCost = trip.estimatedFuelBurnedCost {
        HStack {
            Text("FUEL BURNED VALUE")
            Spacer()
            Text(String(format: "$%.2f", burnedCost))
        }
        .font(.system(size: 11, design: .monospaced))
        .foregroundColor(.fuelActive)
    }
    
    HStack {
        Text("TOTAL SPENT")
        Spacer()
        Text(String(format: "$%.2f", trip.totalMoneySpent))
    }
    .font(.system(size: 12, weight: .bold, design: .monospaced))
    .foregroundColor(.primaryText)
    
    // Show difference (unburned fuel cost)
    let unburned = trip.totalMoneySpent - (trip.estimatedFuelBurnedCost ?? 0)
    if unburned > 0.01 {
        HStack {
            Text("FUEL IN TANKS")
            Spacer()
            Text(String(format: "$%.2f", unburned))
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(.secondaryText.opacity(0.7))
    }
}
```

#### LegCard Enhancements:

For individual legs in TripDetailView:

```swift
VStack(alignment: .leading, spacing: 6) {
    HStack {
        Text("LEG \(leg.legNumber)")
        Spacer()
        Text(String(format: "%.1f GAL", leg.totalBurned))
    }
    .font(.system(size: 12, weight: .bold, design: .monospaced))
    
    // Date/time
    Text(leg.startTime, style: .relative)
        .font(.system(size: 10, design: .monospaced))
        .foregroundColor(.secondaryText)
    
    // Duration if available
    if let duration = leg.duration {
        Text(formatDuration(duration))
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondaryText)
    }
}
```

---

## 📊 Phase 3: Financial Summary Views

### 3.1 Trip Detail Financial Breakdown

**New section in TripDetailView**:

```swift
// FINANCIAL SUMMARY
VStack(alignment: .leading, spacing: 12) {
    Text("FINANCIAL SUMMARY")
        .font(.system(size: 11, weight: .bold, design: .monospaced))
        .foregroundColor(.secondaryText)
        .tracking(2)
    
    FinancialRow(label: "Fuel Purchased", value: trip.totalFuelAdded, unit: "GAL")
    FinancialRow(label: "Fuel Burned", value: trip.totalFuelConsumed, unit: "GAL")
    FinancialRow(label: "Fuel Remaining", value: trip.totalFuelAdded - trip.totalFuelConsumed, unit: "GAL")
    
    Divider()
    
    if let avgPrice = trip.averageFuelPrice {
        FinancialRow(label: "Avg Price", value: avgPrice, unit: "$/GAL", decimals: 2)
    }
    
    if let burnedCost = trip.estimatedFuelBurnedCost {
        FinancialRow(label: "Fuel Burned Cost", value: burnedCost, unit: "$", decimals: 2)
    }
    
    FinancialRow(label: "Total Paid", value: trip.totalMoneySpent, unit: "$", decimals: 2, highlighted: true)
    
    // Breakdown by fuel stop
    if !trip.fuelStops.isEmpty {
        Text("FUEL STOPS")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.secondaryText)
            .padding(.top, 8)
        
        ForEach(trip.fuelStops) { stop in
            FuelStopRow(stop: stop)
        }
    }
}
.padding(16)
.background(Color.cardBackground)
.cornerRadius(12)
```

### 3.2 FuelStopRow Component:

```swift
struct FuelStopRow: View {
    let stop: FuelStop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let location = stop.location {
                    Text(location)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                } else {
                    Text("Fuel Stop")
                        .font(.system(size: 11, design: .monospaced))
                }
                
                Spacer()
                
                Text(stop.timestamp, style: .date)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondaryText)
            }
            
            HStack {
                Text(String(format: "%.1f gal", stop.totalAdded))
                
                if let price = stop.pricePerGallon {
                    Text("@ $\(String(format: "%.2f", price))")
                }
                
                Spacer()
                
                if let total = stop.totalCost {
                    Text(String(format: "$%.2f", total))
                        .fontWeight(.bold)
                }
            }
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondaryText)
        }
        .padding(8)
        .background(Color.appBackground)
        .cornerRadius(6)
    }
}
```

---

## 🔧 Phase 4: Storage & Persistence

### 4.1 Save/Load Methods

Add to FuelState or separate TripStorage class:

```swift
// Save open legs
func saveOpenLegs(_ legs: [FlightLeg]) {
    if let encoded = try? JSONEncoder().encode(legs) {
        UserDefaults.standard.set(encoded, forKey: "openLegs")
    }
}

// Load open legs
func loadOpenLegs() -> [FlightLeg] {
    guard let data = UserDefaults.standard.data(forKey: "openLegs"),
          let legs = try? JSONDecoder().decode([FlightLeg].self, from: data) else {
        return []
    }
    return legs
}

// Delete open leg
func deleteOpenLeg(_ legId: UUID) {
    var legs = loadOpenLegs()
    legs.removeAll { $0.id == legId }
    saveOpenLegs(legs)
}

// Save archived trips
func saveArchivedTrips(_ trips: [Trip]) {
    if let encoded = try? JSONEncoder().encode(trips) {
        UserDefaults.standard.set(encoded, forKey: "archivedTrips")
    }
}

// Delete trip
func deleteTrip(_ tripId: UUID) {
    var trips = loadArchivedTrips()
    trips.removeAll { $0.id == tripId }
    saveArchivedTrips(trips)
}
```

---

## ✅ Implementation Checklist

### Data Layer:
- [x] Enhanced Trip struct with financial calculations
- [x] Created FuelCostTrackingMode enum
- [ ] Add storage helpers for trip/leg deletion

### UI - FuelOptionsView:
- [ ] Add cost mode selector (Simple/Money toggle)
- [ ] Create FuelCostEntryView sheet for Money mode
- [ ] Modify fuel addition flow to capture cost data
- [ ] Update "Add Fuel" button to show mode-appropriate fields

### UI - TripsListView:
- [ ] Add swipe-to-delete for open legs
- [ ] Add swipe-to-delete for archived trips
- [ ] Add bulk delete button for selected legs
- [ ] Add bulk delete button for selected trips
- [ ] Add delete confirmation alerts

### UI - TripDetailView:
- [ ] Add comprehensive financial summary section
- [ ] Create FuelStopRow component
- [ ] Create FinancialRow component
- [ ] Show per-leg cost estimates (if data available)

### UI - Components:
- [ ] Create FuelCostEntryView (price + total input)
- [ ] Create FinancialRow (reusable financial display)
- [ ] Enhance TripCard with financial summary
- [ ] Enhance OpenLegCard with better formatting

---

## 🎨 UX Considerations

### Default Behavior:
- **Simple mode** is default (backward compatible)
- Existing users see no changes unless they switch to Money mode
- Money mode is sticky (persisted per user)

### Cost Entry Flow:
1. User selects fuel amount (TOP OFF / TABS / CUSTOM)
2. If Money mode: Show cost entry sheet
3. Cost entry shows:
   - Calculated fuel quantity (read-only)
   - Price per gallon (required)
   - Total cost from receipt (required)
   - Location (optional)
   - Notes (optional)
4. Validation: totalCost should be ≥ (quantity × price)
5. If validation fails: Show warning but allow override

### Deletion Safety:
- **Open legs**: Swipe to delete (no confirmation for single)
- **Bulk delete legs**: Confirmation required
- **Trips**: Always require confirmation (contains multiple legs)
- **Bulk delete trips**: Extra scary confirmation

---

## 📝 Next Steps

1. **Immediate**: Implement FuelCostEntryView component
2. **High Priority**: Add swipe-to-delete functionality
3. **Medium Priority**: Enhanced financial displays
4. **Nice to Have**: Export trip data as CSV

Would you like me to implement any specific component first?
